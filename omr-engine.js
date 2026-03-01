/**
 * OMR Engine - Optical Mark Recognition using OpenCV.js
 * Handles image processing to detect marked bubbles on optical forms.
 * Features: Performance downscaling, Robust perspective correction, Adaptive thresholding.
 */

export class OMREngine {
    constructor(config = {}) {
        this.bubbleRadius = config.bubbleRadius || 5;
        this.detectionThreshold = config.detectionThreshold || 0.4;
        this.targetWidth = 800;
        this.targetHeight = 1100;
    }

    /**
     * Main entry point: Process raw camera frame
     */
    processFrame(canvas) {
        if (!window.cv || !cv.imread) return null;

        let src = cv.imread(canvas);
        let paperContour = null;
        let small = null;
        let gray = null;

        try {
            // 1. Downscale image for MUCH faster and more reliable contour detection
            let ratio = src.rows / 500;
            small = new cv.Mat();
            let dsize = new cv.Size(Math.round(src.cols / ratio), 500);
            cv.resize(src, small, dsize, 0, 0, cv.INTER_AREA);

            gray = new cv.Mat();
            cv.cvtColor(small, gray, cv.COLOR_RGBA2GRAY);

            // 2. Find Paper Contour on the SMALL image
            let smallContour = this._findPaperContour(gray);

            if (smallContour && smallContour.rows === 4) {
                paperContour = new cv.Mat(4, 1, cv.CV_32SC2);
                for (let i = 0; i < 4; i++) {
                    paperContour.data32S[i * 2] = Math.round(smallContour.data32S[i * 2] * ratio);
                    paperContour.data32S[i * 2 + 1] = Math.round(smallContour.data32S[i * 2 + 1] * ratio);
                }
                smallContour.delete();
            }

            if (!paperContour) return null;

            // 3. Perspective Warp
            let warped = this._warpPerspective(src, paperContour);

            // 4. Final Processing for OMR
            let finalGray = new cv.Mat();
            cv.cvtColor(warped, finalGray, cv.COLOR_RGBA2GRAY);
            cv.adaptiveThreshold(finalGray, finalGray, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 15, 5);

            return { warpedImage: warped, processedOMR: finalGray };

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

    _findPaperContour(gray) {
        let processed = new cv.Mat();
        let contours = new cv.MatVector();
        let hierarchy = new cv.Mat();

        try {
            cv.GaussianBlur(gray, processed, new cv.Size(5, 5), 0);
            cv.Canny(processed, processed, 30, 100);
            let kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(5, 5));
            cv.dilate(processed, processed, kernel);
            kernel.delete();

            // SPEED FIX: Use RETR_EXTERNAL instead of RETR_LIST to avoid thousands of bubble contours
            cv.findContours(processed, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
            console.log(`_findPaperContour: ${contours.size()} contours found`);

            let bestContour = null;
            let maxArea = 0;

            for (let i = 0; i < contours.size(); ++i) {
                let cnt = contours.get(i);
                let area = cv.contourArea(cnt);
                if (area < 10000) continue;

                let peri = cv.arcLength(cnt, true);
                let approx = new cv.Mat();
                cv.approxPolyDP(cnt, approx, 0.02 * peri, true);

                if (approx.rows >= 4 && approx.rows <= 6 && area > maxArea) {
                    let hull = new cv.Mat();
                    cv.convexHull(approx, hull, false, true);
                    let hullPeri = cv.arcLength(hull, true);
                    let finalApprox = new cv.Mat();

                    for (let epsilon = 0.01; epsilon < 0.1; epsilon += 0.01) {
                        cv.approxPolyDP(hull, finalApprox, epsilon * hullPeri, true);
                        if (finalApprox.rows === 4) break;
                    }

                    if (finalApprox.rows === 4) {
                        if (bestContour) bestContour.delete();
                        bestContour = finalApprox.clone();
                        maxArea = area;
                        console.log(`Paper candidate! Area: ${Math.round(area)}`);
                    }
                    hull.delete(); finalApprox.delete(); approx.delete();
                } else {
                    approx.delete();
                }
            }
            return bestContour;
        } catch (e) {
            console.error("_findPaperContour Error:", e);
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
        for (const [subject, questions] of Object.entries(grid)) {
            results[subject] = questions.map(q => {
                let markedOptions = [];
                q.options.forEach(opt => {
                    let rect = new cv.Rect(
                        Math.max(0, opt.x - this.bubbleRadius),
                        Math.max(0, opt.y - this.bubbleRadius),
                        this.bubbleRadius * 2,
                        this.bubbleRadius * 2
                    );
                    try {
                        let roi = processedOMR.roi(rect);
                        let n = cv.countNonZero(roi);
                        let total = rect.width * rect.height;
                        if (n / total > this.detectionThreshold) markedOptions.push(opt.label);
                        roi.delete();
                    } catch (e) { }
                });
                if (markedOptions.length > 1) return "*";
                return markedOptions.length === 1 ? markedOptions[0] : " ";
            });
        }
        return results;
    }
}
