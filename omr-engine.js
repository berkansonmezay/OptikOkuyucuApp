/**
 * OMR Engine - Optical Mark Recognition using OpenCV.js
 * Handles image processing to detect marked bubbles on optical forms.
 * Features: Performance downscaling, Aspect Ratio verification, Extreme point recovery, Debug Overlays.
 */

export class OMREngine {
    constructor(config = {}) {
        this.bubbleRadius = config.bubbleRadius || 10;
        this.detectionThreshold = config.detectionThreshold || 0.30; // Relaxed from 0.35 for better dark-image/glare tolerance
        this.targetWidth = 800;
        this.targetHeight = 1100;
        this.markers = []; // Store detected markers
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
            // More balanced adaptive threshold
            cv.adaptiveThreshold(finalGray, finalGray, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 21, 10);

            // 5. Marker Detection for Alignment
            this.markers = this._detectMarkers(finalGray);

            return { warpedImage: warped, processedOMR: finalGray, markers: this.markers };

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
                if (area > 50 && area < 1200 && aspectRatio > 0.6 && aspectRatio < 1.4) {
                    let extent = area / (rect.width * rect.height);
                    if (extent > 0.65) { // Likely a square
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
        const W_SCALE = 10.0;     // 800 / 80
        const H_SCALE = 13.75;   // 1100 / 80
        const X_OFF_PX = 1.12; // Adjusted for Top-LEFT QR placement (90px / 80px)
        const Y_OFF_PX = 1.12; // Adjusted for Top-LEFT QR placement (90px / 80px)

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
     */
    drawDebugGrid(canvas, grid) {
        const ctx = canvas.getContext('2d');

        // Draw Grid Bubbles and Search Areas
        ctx.lineWidth = 1;
        for (const subject in grid) {
            grid[subject].forEach(q => {
                q.options.forEach(opt => {
                    // Actual Bubble Location
                    ctx.strokeStyle = 'rgba(0, 255, 0, 0.4)';
                    ctx.beginPath();
                    ctx.arc(opt.x, opt.y, this.bubbleRadius, 0, Math.PI * 2);
                    ctx.stroke();

                    // Search Window Box (Diagnostic)
                    const ss = 6; // Current searchSize
                    ctx.strokeStyle = 'rgba(0, 255, 0, 0.15)';
                    ctx.strokeRect(
                        opt.x - this.bubbleRadius - ss,
                        opt.y - this.bubbleRadius - ss,
                        (this.bubbleRadius + ss) * 2,
                        (this.bubbleRadius + ss) * 2
                    );
                });
            });
        }

        // Draw Detected Markers
        ctx.strokeStyle = '#ff3b30';
        ctx.lineWidth = 2;
        this.markers.forEach(m => {
            ctx.strokeRect(m.x - m.w / 2, m.y - m.h / 2, m.w, m.h);
            // Small crosshair
            ctx.beginPath();
            ctx.moveTo(m.x - 3, m.y); ctx.lineTo(m.x + 3, m.y);
            ctx.moveTo(m.x, m.y - 3); ctx.lineTo(m.x, m.y + 3);
            ctx.stroke();
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

    readMarks(processedOMR, grid) {
        const results = {};
        const searchSize = 6; // Increased from 4 for better alignment tolerance

        // Align grid if markers are available
        const alignedGrid = this._alignGrid(grid);

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
                return markedOptions.length === 1 ? markedOptions[0] : " ";
            });
        }
        return results;
    }

    /**
     * Adjusts grid coordinates based on detected markers.
     * Logic: 
     * 1. Booklet Area (centered top): Uses markers near (482, 240)
     * 2. Subject Columns: Uses markers near column start/end points
     */
    _alignGrid(grid) {
        if (!this.markers || this.markers.length < 1) return grid;

        const aligned = JSON.parse(JSON.stringify(grid));

        // 1. Booklet Alignment
        if (aligned['KITAPCIK']) {
            const bookletCentroid = { x: 482, y: 240 };
            const nearbyMarkers = this._findMarkersNear(bookletCentroid, 180);
            if (nearbyMarkers.length >= 1) {
                const observedCentroid = nearbyMarkers.reduce((acc, m) => ({ x: acc.x + m.x / nearbyMarkers.length, y: acc.y + m.y / nearbyMarkers.length }), { x: 0, y: 0 });
                const offsetX = observedCentroid.x - bookletCentroid.x;
                const offsetY = observedCentroid.y - bookletCentroid.y;

                // Debug log for alignment
                console.log(`OMR: Aligned KITAPCIK using ${nearbyMarkers.length} markers. Offset: (${Math.round(offsetX)}, ${Math.round(offsetY)})`);

                aligned['KITAPCIK'].forEach(q => q.options.forEach(opt => {
                    opt.x += offsetX;
                    opt.y += offsetY;
                }));
            }
        }

        // 2. Subjects column alignment
        for (const [subject, questions] of Object.entries(aligned)) {
            if (subject === 'KITAPCIK') continue;

            const firstOpt = questions[0].options[0];
            const columnX = firstOpt.x;

            const topMarkers = this._findMarkersNear({ x: columnX + 30, y: 380 }, 100);
            if (topMarkers.length > 0) {
                const offsetX = topMarkers[0].x - (columnX - 20);
                const offsetY = topMarkers[0].y - 370;

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
