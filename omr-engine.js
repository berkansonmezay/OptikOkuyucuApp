/**
 * OMR Engine - Optical Mark Recognition using OpenCV.js
 * Handles image processing to detect marked bubbles on optical forms.
 * Features: Perspective correction, Adaptive thresholding, Contour detection.
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
        let gray = new cv.Mat();
        let paperContour = null;

        try {
            cv.cvtColor(src, gray, cv.COLOR_RGBA2GRAY);

            // Try detection with two different methods for maximum robustness
            paperContour = this._findPaperContour(gray, "canny");
            if (!paperContour) {
                paperContour = this._findPaperContour(gray, "adaptive");
            }

            if (!paperContour) {
                src.delete(); gray.delete();
                return null;
            }

            // 3. Perspective Warp (Straighten the paper)
            let warped = this._warpPerspective(src, paperContour);

            // 4. Final Processing for OMR
            let finalGray = new cv.Mat();
            cv.cvtColor(warped, finalGray, cv.COLOR_RGBA2GRAY);
            cv.adaptiveThreshold(finalGray, finalGray, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 15, 5);

            return {
                warpedImage: warped,
                processedOMR: finalGray
            };

        } catch (e) {
            console.error("OpenCV Processing Error:", e);
            return null;
        } finally {
            gray.delete();
            if (paperContour) paperContour.delete();
            src.delete();
        }
    }

    _findPaperContour(gray, method) {
        let processed = new cv.Mat();
        let contours = new cv.MatVector();
        let hierarchy = new cv.Mat();

        if (method === "canny") {
            cv.GaussianBlur(gray, processed, new cv.Size(5, 5), 0);
            cv.Canny(processed, processed, 30, 100); // Lowered thresholds
            let kernel = cv.getStructuringElement(cv.MORPH_RECT, new cv.Size(5, 5));
            cv.dilate(processed, processed, kernel);
            kernel.delete();
        } else {
            // Fallback: Use adaptive thresholding for high contrast areas
            cv.adaptiveThreshold(gray, processed, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 21, 5);
        }

        cv.findContours(processed, contours, hierarchy, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

        let bestContour = null;
        let maxArea = 0;

        for (let i = 0; i < contours.size(); ++i) {
            let cnt = contours.get(i);
            let area = cv.contourArea(cnt);
            if (area > 20000) { // Slightly lower threshold
                let peri = cv.arcLength(cnt, true);
                let approx = new cv.Mat();
                cv.approxPolyDP(cnt, approx, 0.02 * peri, true);

                // Be more lenient: 4 to 6 corners is often a distorted rectangle
                if (approx.rows >= 4 && approx.rows <= 6 && area > maxArea) {
                    // Check if it's convex enough
                    if (cv.isContourConvex(approx) || method === "adaptive") {
                        if (bestContour) bestContour.delete();
                        // If it has more than 4 points, take the convex hull to get 4 points
                        if (approx.rows > 4) {
                            let hull = new cv.Mat();
                            cv.convexHull(approx, hull, false, true);
                            bestContour = this._approximateToFourPoints(hull, peri);
                            hull.delete();
                            approx.delete();
                        } else {
                            bestContour = approx;
                        }
                        maxArea = area;
                    } else {
                        approx.delete();
                    }
                } else {
                    approx.delete();
                }
            }
        }

        processed.delete(); contours.delete(); hierarchy.delete();
        return bestContour;
    }

    _approximateToFourPoints(cnt, peri) {
        let approx = new cv.Mat();
        let epsilon = 0.02 * peri;
        // Iteratively adjust epsilon to find 4 points
        for (let j = 0; j < 10; j++) {
            cv.approxPolyDP(cnt, approx, epsilon, true);
            if (approx.rows === 4) break;
            if (approx.rows > 4) epsilon += 0.01 * peri;
            else epsilon -= 0.01 * peri;
        }
        return approx;
    }

    _warpPerspective(src, contour) {
        let corners = [];
        // Ensure we handle data properly regardless of mat type
        for (let i = 0; i < 4; i++) {
            corners.push({
                x: contour.data32S[i * 2],
                y: contour.data32S[i * 2 + 1]
            });
        }

        // Sort corners: TL, TR, BR, BL
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
                        if (n / total > this.detectionThreshold) {
                            markedOptions.push(opt.label);
                        }
                        roi.delete();
                    } catch (e) {
                        // ROI out of bounds, skip
                    }
                });

                if (markedOptions.length > 1) return "*";
                return markedOptions.length === 1 ? markedOptions[0] : " ";
            });
        }
        return results;
    }
}
