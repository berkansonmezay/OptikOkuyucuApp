/**
 * OMR Engine - Optical Mark Recognition
 * Handles image processing to detect marked bubbles on optical forms.
 */

export class OMREngine {
    constructor(config = {}) {
        this.threshold = config.threshold || 128; // Binarization threshold
        this.bubbleRadius = config.bubbleRadius || 14; // Increased from 10 for closer shots
        this.detectionThreshold = config.detectionThreshold || 0.12; // Lowered from 0.25 for better sensitivity
    }

    /**
     * Processes an image (ImageData) and returns detected marks.
     * @param {ImageData} imageData 
     * @param {Object} gridDefinition - Mapping of bubbles to coordinates
     */
    processImage(imageData, gridDefinition) {
        const grayscale = this._toGrayscale(imageData);
        const binarized = this._binarize(grayscale);

        const results = {};

        for (const [subject, questions] of Object.entries(gridDefinition)) {
            results[subject] = questions.map(q => {
                return this._detectMark(binarized, q.options, imageData.width);
            });
        }

        return results;
    }

    /**
     * Converts RGBA ImageData to single-channel Grayscale
     */
    _toGrayscale(imageData) {
        const data = imageData.data;
        const gray = new Uint8ClampedArray(data.length / 4);
        for (let i = 0; i < data.length; i += 4) {
            // Standard Luminance formula: 0.299R + 0.587G + 0.114B
            gray[i / 4] = 0.299 * data[i] + 0.587 * data[i + 1] + 0.114 * data[i + 2];
        }
        return gray;
    }

    /**
     * Simple threshold binarization
     */
    _binarize(grayData) {
        return grayData.map(v => v < this.threshold ? 0 : 255);
    }

    /**
     * Detects which option is marked for a specific question
     * @param {Uint8ClampedArray} binarized 
     * @param {Array} options - List of {label, x, y} coordinates for bubbles
     * @param {number} width - Image width
     */
    _detectMark(binarized, options, width) {
        let markedOptions = [];

        for (const option of options) {
            const density = this._calculateDensity(binarized, option.x, option.y, width);
            if (density > this.detectionThreshold) {
                markedOptions.push(option.label);
            }
        }

        if (markedOptions.length > 1) return "*"; // Multi-mark
        return markedOptions.length === 1 ? markedOptions[0] : " "; // Space for unmarked
    }

    /**
     * Calculates the ratio of dark pixels in a circular area around (x, y)
     */
    _calculateDensity(binarized, centerX, centerY, width) {
        let darkPixels = 0;
        let totalProcessed = 0;
        const radius = this.bubbleRadius;

        for (let y = centerY - radius; y <= centerY + radius; y++) {
            for (let x = centerX - radius; x <= centerX + radius; x++) {
                // Check if point is inside circle
                const dx = x - centerX;
                const dy = y - centerY;
                if (dx * dx + dy * dy <= radius * radius) {
                    const idx = y * width + x;
                    if (binarized[idx] === 0) { // Dark pixel
                        darkPixels++;
                    }
                    totalProcessed++;
                }
            }
        }

        return totalProcessed > 0 ? darkPixels / totalProcessed : 0;
    }
}
