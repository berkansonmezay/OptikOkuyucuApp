import cv2
import numpy as np
import base64
import json

class PythonOMREngine:
    """
    High-accuracy OMR engine using corner-square (registration mark) alignment.
    
    Strategy:
    1. Detect the 4 solid black corner squares on the optical form
    2. Use their centers for a precise 4-point perspective warp
    3. This guarantees pixel-perfect alignment of the bubble grid
    4. Read bubbles using relative positions from corner anchors
    """
    
    def __init__(self):
        self.target_width = 800
        self.target_height = 1100
        self.detection_threshold = 0.35

    def process_image_base64(self, base64_str, exam_data):
        """Main entry: base64 image -> OMR results"""
        try:
            encoded_data = base64_str.split(',')[1] if ',' in base64_str else base64_str
            nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return {"error": "Görüntü çözülemedi", "success": False}

            # Step 1: Find paper contour first (rough crop)
            warped = self._find_and_warp_paper(img)
            if warped is None:
                return {"error": "Kağıt algılanamadı. Lütfen formu düz ve tam çerçevede tutun.", "success": False}

            # Step 2: Detect corner squares on the warped image for fine alignment
            corners = self._detect_corner_squares(warped)
            
            if corners is not None and len(corners) == 4:
                # Re-warp using corner squares for pixel-perfect alignment
                warped = self._warp_by_corners(warped, corners)
                print(f"OMR: Corner squares found! Fine alignment applied.")
            else:
                print(f"OMR: Corner squares not found ({len(corners) if corners else 0}/4). Using rough alignment.")

            # Step 3: Preprocess for bubble reading
            gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
            
            # CLAHE for glare resistance
            clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(gray)
            
            # Otsu threshold for clean binary
            _, thresh = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

            # Step 4: Generate grid & read marks
            grid = self._generate_grid(exam_data)
            results = self._read_marks(thresh, gray, grid)

            # Save debug image
            try:
                debug = warped.copy()
                self._draw_debug(debug, grid, results)
                cv2.imwrite("debug_output.jpg", debug)
                print("OMR: Debug image saved as debug_output.jpg")
            except Exception as e:
                print(f"OMR: Debug save failed: {e}")

            return {
                "booklet": results.get("KITAPCIK", "OKUNAMADI"),
                "answers": results,
                "success": True
            }
        except Exception as e:
            print(f"OMR Error: {e}")
            import traceback
            traceback.print_exc()
            return {"error": str(e), "success": False}

    def _find_and_warp_paper(self, img):
        """Detect the paper rectangle and warp to standard size."""
        ratio = max(img.shape[0], img.shape[1]) / 800.0
        small = cv2.resize(img, (int(img.shape[1] / ratio), int(img.shape[0] / ratio)))
        
        gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)
        
        # Try multiple edge detection approaches
        for method in ['canny', 'adaptive']:
            if method == 'canny':
                edged = cv2.Canny(gray, 50, 150)
            else:
                thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                               cv2.THRESH_BINARY_INV, 11, 2)
                edged = thresh
            
            # Dilate to close gaps
            kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
            edged = cv2.dilate(edged, kernel, iterations=1)
            
            cnts, _ = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]
            
            for c in cnts:
                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.02 * peri, True)
                
                # Must be a quadrilateral with significant area
                if len(approx) == 4 and cv2.contourArea(approx) > (small.shape[0] * small.shape[1] * 0.2):
                    pts = approx.reshape(4, 2).astype(np.float32) * ratio
                    return self._four_point_warp(img, pts)
        
        # Fallback: use entire image
        h, w = img.shape[:2]
        pts = np.array([[0, 0], [w, 0], [w, h], [0, h]], dtype=np.float32)
        return self._four_point_warp(img, pts)

    def _detect_corner_squares(self, img):
        """
        Detect the 4 solid black registration squares at the corners of the form.
        These are typically 10-20px solid black squares placed at specific positions.
        """
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Strong threshold to find solid black regions
        _, binary = cv2.threshold(gray, 80, 255, cv2.THRESH_BINARY_INV)
        
        # Clean up noise
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel, iterations=1)
        binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel, iterations=1)
        
        cnts, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        # Filter for square-like shapes
        h, w = img.shape[:2]
        candidates = []
        
        for c in cnts:
            area = cv2.contourArea(c)
            if area < 100 or area > 5000:  # Corner squares are small but not tiny
                continue
            
            x, y, bw, bh = cv2.boundingRect(c)
            aspect = float(bw) / bh if bh > 0 else 0
            extent = area / (bw * bh) if (bw * bh) > 0 else 0
            
            # Must be roughly square (aspect 0.5-2.0) and filled (extent > 0.6)
            if 0.5 < aspect < 2.0 and extent > 0.6:
                cx = x + bw // 2
                cy = y + bh // 2
                candidates.append({'x': cx, 'y': cy, 'area': area, 'w': bw, 'h': bh})
        
        if len(candidates) < 4:
            print(f"OMR: Only {len(candidates)} square candidates found.")
            return None
        
        # Identify the 4 corner squares (closest to each corner of the image)
        corners_target = [
            (0, 0),          # Top-left
            (w, 0),          # Top-right
            (0, h),          # Bottom-left
            (w, h)           # Bottom-right
        ]
        
        found_corners = []
        for tx, ty in corners_target:
            # Find the candidate closest to this corner, within 25% of image dimensions
            best = None
            best_dist = float('inf')
            max_dist = max(w, h) * 0.25
            
            for c in candidates:
                dist = np.sqrt((c['x'] - tx) ** 2 + (c['y'] - ty) ** 2)
                if dist < best_dist and dist < max_dist:
                    best_dist = dist
                    best = c
            
            if best:
                found_corners.append((best['x'], best['y']))
            else:
                print(f"OMR: No corner square found near ({tx}, {ty})")
                return None
        
        print(f"OMR: Corner squares detected at: {found_corners}")
        return found_corners

    def _warp_by_corners(self, img, corners):
        """Re-warp using detected corner square centers for pixel-perfect alignment."""
        # corners: [top-left, top-right, bottom-left, bottom-right]
        src = np.array(corners, dtype=np.float32)
        
        # Small margin: corner squares are slightly inside the printable area
        margin = 15
        dst = np.array([
            [margin, margin],
            [self.target_width - margin, margin],
            [margin, self.target_height - margin],
            [self.target_width - margin, self.target_height - margin]
        ], dtype=np.float32)
        
        M = cv2.getPerspectiveTransform(src, dst)
        return cv2.warpPerspective(img, M, (self.target_width, self.target_height))

    def _four_point_warp(self, img, pts):
        """Standard 4-point perspective warp with point ordering."""
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]   # Top-left
        rect[2] = pts[np.argmax(s)]   # Bottom-right
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)] # Top-right
        rect[3] = pts[np.argmax(diff)] # Bottom-left

        dst = np.array([
            [0, 0],
            [self.target_width - 1, 0],
            [self.target_width - 1, self.target_height - 1],
            [0, self.target_height - 1]
        ], dtype="float32")

        M = cv2.getPerspectiveTransform(rect, dst)
        return cv2.warpPerspective(img, M, (self.target_width, self.target_height))

    def _generate_grid(self, exam):
        """Generate bubble positions for the standard 800x1100 warped form."""
        grid = {}
        
        # Booklet section (A/B/C/D near top-center)
        grid['KITAPCIK'] = [{
            'options': [
                {'label': 'A', 'x': 440, 'y': 240},
                {'label': 'B', 'x': 468, 'y': 240},
                {'label': 'C', 'x': 496, 'y': 240},
                {'label': 'D', 'x': 524, 'y': 240}
            ]
        }]
        
        if not exam or 'subjects' not in exam:
            return grid

        start_y = 385
        row_height = 33.5
        opt_step = 24.5
        columns = [
            {'name': 'Türkçe',    'x': 64},
            {'name': 'İnkılap',   'x': 184},
            {'name': 'Din',       'x': 304},
            {'name': 'İngilizce', 'x': 424},
            {'name': 'Matematik', 'x': 578},
            {'name': 'Fen',       'x': 698}
        ]

        for col in columns:
            matching = None
            for s in exam.get('subjects', []):
                if col['name'].lower() in s.get('name', '').lower() or s.get('name', '').lower() in col['name'].lower():
                    matching = s
                    break
            
            if matching:
                questions = []
                count = matching.get('questionCount', 20)
                for i in range(count):
                    cur_y = start_y + (i * row_height)
                    questions.append({
                        'options': [
                            {'label': 'A', 'x': col['x'] + opt_step * 0, 'y': cur_y},
                            {'label': 'B', 'x': col['x'] + opt_step * 1, 'y': cur_y},
                            {'label': 'C', 'x': col['x'] + opt_step * 2, 'y': cur_y},
                            {'label': 'D', 'x': col['x'] + opt_step * 3, 'y': cur_y}
                        ]
                    })
                grid[matching['name']] = questions
        return grid

    def _read_marks(self, thresh, gray, grid):
        """Read marked bubbles using both binary and grayscale analysis."""
        results = {}
        search_radius = 8  # Generous search window
        
        for subject, questions in grid.items():
            subject_answers = []
            for q in questions:
                # For each question, find the darkest option
                option_scores = []
                
                for opt in q['options']:
                    x, y = int(opt['x']), int(opt['y'])
                    
                    # Bounds check
                    y1 = max(0, y - search_radius)
                    y2 = min(thresh.shape[0], y + search_radius)
                    x1 = max(0, x - search_radius)
                    x2 = min(thresh.shape[1], x + search_radius)
                    
                    if y2 <= y1 or x2 <= x1:
                        option_scores.append((opt['label'], 0))
                        continue
                    
                    # Binary analysis (from threshold image)
                    roi_bin = thresh[y1:y2, x1:x2]
                    fill_ratio = np.sum(roi_bin > 0) / roi_bin.size if roi_bin.size > 0 else 0
                    
                    # Grayscale analysis (raw darkness)
                    roi_gray = gray[y1:y2, x1:x2]
                    darkness = 1.0 - (np.mean(roi_gray) / 255.0) if roi_gray.size > 0 else 0
                    
                    # Combined score (weighted)
                    score = fill_ratio * 0.6 + darkness * 0.4
                    option_scores.append((opt['label'], score))
                
                # Find marked options 
                if not option_scores:
                    subject_answers.append(" ")
                    continue
                
                # Sort by score descending
                option_scores.sort(key=lambda x: x[1], reverse=True)
                best_label, best_score = option_scores[0]
                
                # Dynamic threshold: marked bubble should be significantly darker
                second_score = option_scores[1][1] if len(option_scores) > 1 else 0
                
                if best_score > self.detection_threshold:
                    # Check if there's a clear winner (best is much stronger than 2nd)
                    if best_score > second_score * 1.5 or (best_score > 0.5 and second_score < 0.3):
                        subject_answers.append(best_label)
                    elif second_score > self.detection_threshold:
                        subject_answers.append("*")  # Double mark
                    else:
                        subject_answers.append(best_label)
                else:
                    subject_answers.append(" ")  # Not marked
            
            if subject == 'KITAPCIK':
                results[subject] = subject_answers[0] if subject_answers else "OKUNAMADI"
            else:
                results[subject] = "".join(subject_answers)
                 
        return results

    def _draw_debug(self, img, grid, results):
        """Draw debug visualization on the warped image."""
        for subject, questions in grid.items():
            for i, q in enumerate(questions):
                for opt in q['options']:
                    x, y = int(opt['x']), int(opt['y'])
                    # Green circle for each bubble position
                    cv2.circle(img, (x, y), 8, (0, 255, 0), 1)
                    
                    # Red filled circle if marked
                    if subject in results:
                        if subject == 'KITAPCIK':
                            if results[subject] == opt['label']:
                                cv2.circle(img, (x, y), 8, (0, 0, 255), 2)
                        else:
                            answer_str = results[subject]
                            if i < len(answer_str) and answer_str[i] == opt['label']:
                                cv2.circle(img, (x, y), 8, (0, 0, 255), 2)
