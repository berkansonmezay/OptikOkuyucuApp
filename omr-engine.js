/**
 * OMR Engine - Optical Mark Recognition using OpenCV.js
 * Handles image processing to detect marked bubbles on optical forms.
 * Features: Perspective correction, Adaptive thresholding, Contour detection.
 */

export class OMREngine {
    constructor(config = {}) {
        this.bubbleRadius = config.bubbleRadius || 5;
        this.detectionThreshold = config.detectionThreshold || 0.6; // Dark pixel ratio
        this.targetWidth = 800;
        this.targetHeight = 1100;
    }

    /**
     * Main entry point: Process raw camera frame
     */
    processFrame(canvas) {
        if (!window.cv) return null;

        let src = cv.imread(canvas);
        let processed = new cv.Mat();

        // 1. Pre-process for contour detection
        cv.cvtColor(src, processed, cv.COLOR_RGBA2GRAY);
        cv.GaussianBlur(processed, processed, new cv.Size(5, 5), 0);
        cv.adaptiveThreshold(processed, processed, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 11, 2);

        // 2. Find contours (look for the paper rectangle)
        let contours = new cv.MatVector();
        let hierarchy = new cv.Mat();
        cv.findContours(processed, contours, hierarchy, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

        let paperContour = null;
        let maxArea = 0;

        for (let i = 0; i < contours.size(); ++i) {
            let contour = contours.get(i);
            let area = cv.contourArea(contour);
            if (area > 50000) { // Minimum area to be a paper
                let peri = cv.arcLength(contour, true);
                let approx = new cv.Mat();
                cv.approxPolyDP(contour, approx, 0.02 * peri, true);

                if (approx.rows === 4 && area > maxArea) {
                    paperContour = approx;
                    maxArea = area;
                }
            }
        }

        if (!paperContour) {
            src.delete(); processed.delete(); contours.delete(); hierarchy.delete();
            return null;
        }

        // 3. Perspective Warp (Straighten the paper)
        let warped = this._warpPerspective(src, paperContour);

        // 4. Final Processing for OMR
        let finalGray = new cv.Mat();
        cv.cvtColor(warped, finalGray, cv.COLOR_RGBA2GRAY);
        cv.adaptiveThreshold(finalGray, finalGray, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C, cv.THRESH_BINARY_INV, 15, 5);

        // Cleanup intermediate
        src.delete(); processed.delete(); contours.delete(); hierarchy.delete(); paperContour.delete();

        return {
            warpedImage: warped,
            processedOMR: finalGray
        };
    }

    _warpPerspective(src, contour) {
        let corners = [];
        for (let i = 0; i < 4; i++) {
            corners.push({ x: contour.data32S[i * 2], y: contour.data32S[i * 2 + 1] });
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

    /**
     * Reads marks from warped/processed image
     */
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
                    let roi = processedOMR.roi(rect);
                    let n = cv.countNonZero(roi);
                    let total = rect.width * rect.height;
                    if (n / total > this.detectionThreshold) {
                        markedOptions.push(opt.label);
                    }
                    roi.delete();
                });

                if (markedOptions.length > 1) return "*";
                return markedOptions.length === 1 ? markedOptions[0] : " ";
            });
        }
        return results;
    }
}
