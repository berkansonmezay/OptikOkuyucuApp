/**
 * OMR Engine - Optical Mark Recognition using OpenCV.js
 * Handles image processing to detect marked bubbles on optical forms.
 * Features: Performance downscaling, Aspect Ratio verification, Extreme point recovery, Debug Overlays.
 */

export class OMREngine {
    constructor(config = {}) {
        this.bubbleRadius = config.bubbleRadius || 9; // Reduced for tighter fit
        this.detectionThreshold = config.detectionThreshold || 0.30;
        this.targetWidth = 800;
        this.targetHeight = 1130; // Closer to A4 aspect ratio (1.41)
        this.markers = []; // Store detected markers
        this.anchorPoints = []; // Specifically for the black square anchors
    }

    /**
     * Main entry point: Process raw camera frame
     * @param {HTMLCanvasElement} canvas
     * @param {Object} qrResult - Optional jsQR result for assisted localization
     */
    processFrame(canvas, qrResult = null) {
        if (!window.cv || !cv.imread) return null;

        let src = cv.imread(canvas);
        let paperContour = null;
        let small = null;
        let gray = null;

        try {
            // 1. Performance: Downscale for detection
            let ratio = Math.max(src.rows, src.cols) / 600;
            small = new cv.Mat();
            cv.resize(src, small, new cv.Size(Math.round(src.cols / ratio), Math.round(src.rows / ratio)), 0, 0, cv.INTER_AREA);

            gray = new cv.Mat();
            cv.cvtColor(small, gray, cv.COLOR_RGBA2GRAY);

            // 2. Multi-Pass Detection
            paperContour = this._findPaperContour(gray, "canny");
            if (!paperContour) {
                paperContour = this._findPaperContour(gray, "adaptive");
            }

            if (paperContour) {
                // Scaling: paperContour is from 'small' Mat (~600px)
                let upscaled = new cv.Mat(4, 1, cv.CV_32SC2);
                for (let i = 0; i < 4; i++) {
                    upscaled.data32S[i * 2] = Math.round(paperContour.data32S[i * 2] * ratio);
                    upscaled.data32S[i * 2 + 1] = Math.round(paperContour.data32S[i * 2 + 1] * ratio);
                }
                paperContour.delete();
                paperContour = upscaled;
            } else if (qrResult && qrResult.location) {
                // Fallback: QR estimation returns high-res points directly
                console.log("OMR: Contour failed, using High-Res QR estimation");
                paperContour = this._estimateContourFromQR(qrResult.location, { width: canvas.width, height: canvas.height }, ratio);
            }

            if (!paperContour) return null;

            // 3. Perspective Warp
            let warped = this._warpPerspective(src, paperContour);

            // 4. Final Processing for OMR
            let finalGray = new cv.Mat();
            cv.cvtColor(warped, finalGray, cv.COLOR_RGBA2GRAY);

            // Apply CLAHE (Local Contrast Enhancement) to combat glare
            let clahe = new cv.CLAHE(2.0, new cv.Size(8, 8));
            clahe.apply(finalGray, finalGray);
            clahe.delete();

            // Balanced adaptive threshold
            cv.adaptiveThreshold(finalGray, finalGray, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 21, 10);

            // 5. Marker Detection for Alignment
            this.markers = this._detectMarkers(finalGray);

            return { warpedImage: warped, processedOMR: finalGray, markers: this.markers, qrInfo: qrResult };

        } catch (e) {
            console.error("OMR processFrame Error:", e);
            return null;
        } finally {
            if (gray) gray.delete();
            if (small) small.delete();
            if (paperContour) paperContour.delete();
            if (src) src.delete();
        }
    }

    /**
     * Detects small square markers used for area anchoring
     */
    _detectMarkers(binary) {
        let detected = [];
        let contours = new cv.MatVector();
        let hierarchy = new cv.Mat();

        try {
            cv.findContours(binary, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

            for (let i = 0; i < contours.size(); ++i) {
                let cnt = contours.get(i);
                let area = cv.contourArea(cnt);
                let rect = cv.boundingRect(cnt);
                let aspectRatio = rect.width / rect.height;

                // Thresholds for markers on a 800x1100 target (Lowered area for robustness)
                if (area > 60 && area < 1500 && aspectRatio > 0.6 && aspectRatio < 1.4) {
                    let extent = area / (rect.width * rect.height);
                    if (extent > 0.7) { // Likely a square
                        detected.push({
                            x: rect.x + rect.width / 2,
                            y: rect.y + rect.height / 2,
                            w: rect.width,
                            h: rect.height,
                            area: area
                        });
                    }
                }
            }
        } catch (e) {
            console.error("OMR: Marker detection failed", e);
        } finally {
            contours.delete(); hierarchy.delete();
        }

        // Filter and sort anchor points (should be at top/bottom of sections)
        this.anchorPoints = detected.filter(m => m.area > 100);

        return detected;
    }

    /**
     * Estimates paper corners based on QR code position and LGS form layout.
     * Calculated for LGS form where QR is ~140px from top and ~245px from left on 800x1100 target.
     */
    _estimateContourFromQR(qrLoc, frameSize, ratio) {
        // Find QR center using all 4 corners for better precision
        const center = {
            x: (qrLoc.topLeftCorner.x + qrLoc.topRightCorner.x + qrLoc.bottomRightCorner.x + qrLoc.bottomLeftCorner.x) / 4,
            y: (qrLoc.topLeftCorner.y + qrLoc.topRightCorner.y + qrLoc.bottomRightCorner.y + qrLoc.bottomLeftCorner.y) / 4
        };

        // Calculate QR side length (qrSize) based on top edge
        const dx = qrLoc.topRightCorner.x - qrLoc.topLeftCorner.x;
        const dy = qrLoc.topRightCorner.y - qrLoc.topLeftCorner.y;
        const qrSize = Math.sqrt(dx * dx + dy * dy);

        // Unit vectors for Orientation (u) and Perpendicular (v)
        const ux = dx / qrSize;
        const uy = dy / qrSize;
        const vx = -uy;
        const vy = ux;

        // LGS Form Layout Constants (Target 800x1100)
        // QR Center is at {x: 245, y: 140}, QR size is ~80px
        const W_SCALE = 8.2;     // 800 / ~97px QR
        const H_SCALE = 11.6;    // 1130 / ~97px QR
        const X_OFF_PX = 1.45;   // QR Center X / QR Size
        const Y_OFF_PX = 1.45;   // QR Center Y / QR Size

        // Function to map standard OMR coordinates to current frame coordinates
        const getPoint = (sx, sy) => ({
            x: center.x + (sx - X_OFF_PX) * qrSize * ux + (sy - Y_OFF_PX) * qrSize * vx,
            y: center.y + (sx - X_OFF_PX) * qrSize * uy + (sy - Y_OFF_PX) * qrSize * vy
        });

        const pTL = getPoint(0, 0);
        const pTR = getPoint(W_SCALE, 0);
        const pBR = getPoint(W_SCALE, H_SCALE);
        const pBL = getPoint(0, H_SCALE);

        const result = new cv.Mat(4, 1, cv.CV_32SC2);
        result.data32S[0] = Math.round(pTL.x); result.data32S[1] = Math.round(pTL.y);
        result.data32S[2] = Math.round(pTR.x); result.data32S[3] = Math.round(pTR.y);
        result.data32S[4] = Math.round(pBR.x); result.data32S[5] = Math.round(pBR.y);
        result.data32S[6] = Math.round(pBL.x); result.data32S[7] = Math.round(pBL.y);

        return result;
    }

    /**
     * Helper to visualize the OMR grid for debugging
     * @param {HTMLCanvasElement} canvas
     * @param {Object} grid - The grid coordinates
     * @param {Object} results - Optional OMR read results to highlight detected marks
     */
    drawDebugGrid(canvas, grid, results = null) {
        const ctx = canvas.getContext('2d');

        // Draw Grid Bubbles and Search Areas
        ctx.lineWidth = 1;
        for (const subject in grid) {
            const subjectResults = results ? results[subject] : null;

            grid[subject].forEach((q, qIdx) => {
                const qResult = subjectResults ? subjectResults[qIdx] : null;

                q.options.forEach(opt => {
                    const isMarked = qResult === opt.label;

                    // Actual Bubble Location
                    ctx.strokeStyle = isMarked ? '#34c759' : 'rgba(0, 255, 0, 0.4)';
                    ctx.fillStyle = isMarked ? 'rgba(52, 199, 89, 0.3)' : 'transparent';

                    ctx.beginPath();
                    ctx.arc(opt.x, opt.y, this.bubbleRadius, 0, Math.PI * 2);
                    if (isMarked) ctx.fill();
                    ctx.stroke();

                    // Search Window Box (Diagnostic)
                    if (!isMarked) {
                        const ss = 6; // Current searchSize
                        ctx.strokeStyle = 'rgba(0, 255, 0, 0.15)';
                        ctx.strokeRect(
                            opt.x - this.bubbleRadius - ss,
                            opt.y - this.bubbleRadius - ss,
                            (this.bubbleRadius + ss) * 2,
                            (this.bubbleRadius + ss) * 2
                        );
                    }
                });

                // Draw question number if it's the first option
                if (qIdx % 5 === 0 || qIdx === 0) {
                    ctx.fillStyle = 'rgba(0, 255, 0, 0.6)';
                    ctx.font = 'bold 10px sans-serif';
                    ctx.fillText(qIdx + 1, q.options[0].x - 25, q.options[0].y + 4);
                }
            });

            // Draw Subject Name
            if (grid[subject][0]) {
                ctx.fillStyle = '#7C3AED';
                ctx.font = 'bold 12px sans-serif';
                ctx.fillText(subject, grid[subject][0].options[0].x, grid[subject][0].options[0].y - 20);
            }
        }

        // Draw Detected Markers / Anchor Points
        ctx.strokeStyle = '#ff3b30'; // Red for anchors
        ctx.lineWidth = 2;
        this.markers.forEach(m => {
            const isAnchor = m.area > 100;
            ctx.strokeStyle = isAnchor ? '#ff3b30' : '#ff9500'; // Red for anchors, orange for small markers

            ctx.strokeRect(m.x - m.w / 2, m.y - m.h / 2, m.w, m.h);
            // Small crosshair
            ctx.beginPath();
            ctx.moveTo(m.x - 5, m.y); ctx.lineTo(m.x + 5, m.y);
            ctx.moveTo(m.x, m.y - 5); ctx.lineTo(m.x, m.y + 5);
            ctx.stroke();

            if (isAnchor) {
                ctx.fillStyle = '#ff3b30';
                ctx.font = '8px sans-serif';
                ctx.fillText(`ANCHOR ${Math.round(m.area)}`, m.x - 15, m.y - 12);
            }
        });
    }

    _findPaperContour(gray, mode) {
        let processed = new cv.Mat();
        let contours = new cv.MatVector();
        let hierarchy = new cv.Mat();

        try {
            if (mode === "canny") {
                cv.GaussianBlur(gray, processed, new cv.Size(7, 7), 0);
                cv.Canny(processed, processed, 30, 80); // More sensitive Canny
                let kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(7, 7));
                cv.morphologyEx(processed, processed, cv.MORPH_CLOSE, kernel); // Bridge gaps
                cv.dilate(processed, processed, kernel);
                kernel.delete();
            } else {
                cv.adaptiveThreshold(gray, processed, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 31, 10);
                let kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(5, 5));
                cv.morphologyEx(processed, processed, cv.MORPH_CLOSE, kernel);
                cv.dilate(processed, processed, kernel);
                kernel.delete();
            }

            cv.findContours(processed, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

            for (let i = 0; i < contours.size(); ++i) {
                let cnt = contours.get(i);
                let area = cv.contourArea(cnt);
                let rect = cv.boundingRect(cnt);
                let aspectRatio = Math.max(rect.width, rect.height) / Math.min(rect.width, rect.height);

                // Robust filtering: Lower area threshold (15000) and wider aspect ratio (0.7 to 3.0)
                if (area > 15000 && aspectRatio > 0.7 && aspectRatio < 3.0 && area > maxArea) {
                    maxArea = area;
                    bestCnt = cnt;
                }
            }

            if (!bestCnt) return null;

            let pts = [];
            let hull = new cv.Mat();
            cv.convexHull(bestCnt, hull, false, true);
            for (let i = 0; i < hull.rows; i++) {
                pts.push({ x: hull.data32S[i * 2], y: hull.data32S[i * 2 + 1] });
            }
            hull.delete();

            if (pts.length < 4) return null;

            // Sorting for corners: TL, TR, BR, BL
            let tl = pts.reduce((p, c) => (p.x + p.y < c.x + c.y) ? p : c);
            let br = pts.reduce((p, c) => (p.x + p.y > c.x + c.y) ? p : c);
            let tr = pts.reduce((p, c) => (c.y - c.x < p.y - p.x) ? p : c);
            let bl = pts.reduce((p, c) => (c.y - c.x > p.y - p.x) ? p : c);

            let result = new cv.Mat(4, 1, cv.CV_32SC2);
            result.data32S[0] = tl.x; result.data32S[1] = tl.y;
            result.data32S[2] = tr.x; result.data32S[3] = tr.y;
            result.data32S[4] = br.x; result.data32S[5] = br.y;
            result.data32S[6] = bl.x; result.data32S[7] = bl.y;

            return result;

        } catch (e) {
            console.error("_findPaperContour error:", e);
            return null;
        } finally {
            processed.delete(); contours.delete(); hierarchy.delete();
        }
    }

    _warpPerspective(src, contour) {
        let corners = [];
        for (let i = 0; i < 4; i++) {
            corners.push({ x: contour.data32S[i * 2], y: contour.data32S[i * 2 + 1] });
        }

        corners.sort((a, b) => a.y - b.y);
        let top = corners.slice(0, 2).sort((a, b) => a.x - b.x);
        let bottom = corners.slice(2, 4).sort((a, b) => a.x - b.x);

        let srcTri = cv.matFromArray(4, 1, cv.CV_32FC2, [
            top[0].x, top[0].y, top[1].x, top[1].y,
            bottom[1].x, bottom[1].y, bottom[0].x, bottom[0].y
        ]);
        let dstTri = cv.matFromArray(4, 1, cv.CV_32FC2, [
            0, 0, this.targetWidth, 0,
            this.targetWidth, this.targetHeight, 0, this.targetHeight
        ]);

        let M = cv.getPerspectiveTransform(srcTri, dstTri);
        let warped = new cv.Mat();
        cv.warpPerspective(src, warped, M, new cv.Size(this.targetWidth, this.targetHeight));

        srcTri.delete(); dstTri.delete(); M.delete();
        return warped;
    }

    readMarks(processedOMR, grid, qrInfo = null) {
        const results = {};
        const searchSize = 10; // Increased from 8 for maximum alignment tolerance

        // Align grid if markers are available
        const alignedGrid = this._alignGrid(grid, qrInfo);

        for (const [subject, questions] of Object.entries(alignedGrid)) {
            results[subject] = questions.map(q => {
                let markedOptions = [];
                q.options.forEach(opt => {
                    let bestIntensity = 0;

                    // SUB-PIXEL SEARCH: Look for the mark in a small window
                    for (let oy = -searchSize; oy <= searchSize; oy += 2) {
                        for (let ox = -searchSize; ox <= searchSize; ox += 2) {
                            let rect = new cv.Rect(
                                Math.max(0, Math.round(opt.x + ox - this.bubbleRadius)),
                                Math.max(0, Math.round(opt.y + oy - this.bubbleRadius)),
                                Math.round(this.bubbleRadius * 2),
                                Math.round(this.bubbleRadius * 2)
                            );

                            try {
                                let roi = processedOMR.roi(rect);
                                let n = cv.countNonZero(roi);
                                let intensity = n / (rect.width * rect.height);
                                bestIntensity = Math.max(bestIntensity, intensity);
                                roi.delete();
                            } catch (e) { }
                        }
                    }

                    if (bestIntensity > this.detectionThreshold) {
                        markedOptions.push(opt.label);
                    }
                });

                if (markedOptions.length > 1) return "*";
                // Return null or " " if no options marked as per requirement
                return markedOptions.length === 1 ? markedOptions[0] : null;
            });
        }
        return results;
    }

    /**
     * Adjusts grid coordinates based on detected markers (anchor points).
     * Now implements independent per-column alignment for maximum precision.
     */
    _alignGrid(grid, qrInfo = null) {
        const aligned = JSON.parse(JSON.stringify(grid));

        // 1. Booklet Alignment (KITAPCIK)
        if (aligned['KITAPCIK']) {
            const bookletCentroid = { x: 585, y: 255 }; // Calibrated centroid for booklet markers
            const bookletMarkers = this._findMarkersNear(bookletCentroid, 150);

            if (bookletMarkers.length > 0) {
                // Use the average offset of nearby markers
                const observedCentroid = bookletMarkers.reduce((acc, m) => ({ x: acc.x + m.x / bookletMarkers.length, y: acc.y + m.y / bookletMarkers.length }), { x: 0, y: 0 });
                const offsetX = observedCentroid.x - bookletCentroid.x;
                const offsetY = observedCentroid.y - bookletCentroid.y;

                aligned['KITAPCIK'].forEach(q => q.options.forEach(opt => {
                    opt.x += offsetX;
                    opt.y += offsetY;
                }));
            }
        }

        // 2. Individual Subject Column Alignment
        for (const [subject, questions] of Object.entries(aligned)) {
            if (subject === 'KITAPCIK' || questions.length === 0) continue;

            const baseColX = questions[0].options[0].x;
            const baseColY = questions[0].options[0].y;

            // Search for markers that are likely at the top or bottom of this specific column
            // On LGS form, markers are usually ~20-30px above/below columns
            const topAnchorSearch = { x: baseColX - 25, y: baseColY - 30 };
            const bottomAnchorSearch = { x: baseColX - 25, y: baseColY + (questions.length * 28.5) + 10 };

            const nearbyTop = this._findMarkersNear(topAnchorSearch, 60);
            const nearbyBottom = this._findMarkersNear(bottomAnchorSearch, 60);

            let offsetX = 0;
            let offsetY = 0;

            if (nearbyTop.length > 0) {
                // Priority: Align to top marker of column
                offsetX = nearbyTop[0].x - topAnchorSearch.x;
                offsetY = nearbyTop[0].y - topAnchorSearch.y;
            } else if (nearbyBottom.length > 0) {
                // Fallback: Align to bottom marker
                offsetX = nearbyBottom[0].x - bottomAnchorSearch.x;
                offsetY = nearbyBottom[0].y - bottomAnchorSearch.y;
            }

            if (offsetX !== 0 || offsetY !== 0) {
                questions.forEach(q => q.options.forEach(opt => {
                    opt.x += offsetX;
                    opt.y += offsetY;
                }));
            }
        }

        return aligned;
    }

    _findMarkersNear(pt, radius) {
        return this.markers.filter(m => {
            const dist = Math.sqrt(Math.pow(m.x - pt.x, 2) + Math.pow(m.y - pt.y, 2));
            return dist < radius;
        });
    }
}
