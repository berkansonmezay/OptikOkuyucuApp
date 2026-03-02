import cv2
import numpy as np
import base64
import json

class PythonOMREngine:
    """
    OMR engine with AUTO-CALIBRATION.
    Instead of fixed pixel coordinates, this engine:
    1. Detects corner squares for perspective warp
    2. Detects the pink header bars to find grid regions
    3. Scans for actual bubble positions within each region
    """
    
    def __init__(self):
        self.target_width = 800
        self.target_height = 1100
        self.detection_threshold = 0.30  # Lowered for better sensitivity

    def process_image_base64(self, base64_str, exam_data):
        try:
            encoded_data = base64_str.split(',')[1] if ',' in base64_str else base64_str
            nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            
            if img is None:
                return {"error": "Görüntü çözülemedi", "success": False}

            # Step 1: Find and warp paper
            warped = self._find_and_warp_paper(img)
            if warped is None:
                return {"error": "Kağıt algılanamadı.", "success": False}

            # Step 2: Fine-align using corner squares
            corners = self._detect_corner_squares(warped)
            if corners and len(corners) == 4:
                warped = self._warp_by_corners(warped, corners)
                print("OMR: ✓ Corner-aligned")
            else:
                print("OMR: ✗ Corner squares not found, using rough warp")

            # Step 3: Auto-detect grid positions
            grid = self._auto_detect_grid(warped, exam_data)
            
            # Step 4: Prepare for reading
            gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
            clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
            enhanced = clahe.apply(gray)
            _, thresh = cv2.threshold(enhanced, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)

            # Step 5: Read marks
            results = self._read_marks(thresh, gray, grid)

            # Generate debug image and encode as base64
            debug_image_b64 = None
            try:
                debug = warped.copy()
                self._draw_debug(debug, grid, results)
                cv2.imwrite("debug_output.jpg", debug)
                # Encode debug image as base64 for frontend preview
                _, buffer = cv2.imencode('.jpg', debug, [cv2.IMWRITE_JPEG_QUALITY, 75])
                debug_image_b64 = "data:image/jpeg;base64," + base64.b64encode(buffer).decode('utf-8')
                print("OMR: Debug image generated and encoded")
            except Exception as e:
                print(f"Debug save error: {e}")

            return {
                "booklet": results.get("KITAPCIK", "OKUNAMADI"),
                "answers": results,
                "debug_image": debug_image_b64,
                "success": True
            }
        except Exception as e:
            import traceback
            traceback.print_exc()
            return {"error": str(e), "success": False}

    def _auto_detect_grid(self, warped, exam_data):
        """
        Use FIXED calibrated coordinates for the LGS form.
        The corner-square warp ensures the paper is always mapped to 800x1100,
        so fixed coordinates are reliable and much more accurate than auto-detection.
        """
        grid = {}

        if not exam_data or 'subjects' not in exam_data:
            return grid

        subjects = exam_data.get('subjects', [])

        # ---- FIXED GRID COORDINATES for LGS Form (800x1100 target) ----
        # Corner squares map to ~(20, 20) on TL and ~(780, 1080) on BR.

        # Booklet bubbles (KITAPCIK TÜRÜ area)
        grid['KITAPCIK'] = [{
            'options': [
                {'label': 'A', 'x': 442, 'y': 262},
                {'label': 'B', 'x': 461, 'y': 262},
                {'label': 'C', 'x': 480, 'y': 262},
                {'label': 'D', 'x': 499, 'y': 262}
            ]
        }]

        # Subject column definitions
        opt_step = 21.0   # Measured distance between bubble centers A->B->C->D
        start_y = 410     # Y-coordinate of question 1 (below pink sub-headers)
        row_height = 30.5 # Vertical spacing between questions

        # Column X positions (A bubble), recalibrated from debug image
        # Each entry has 'aliases' for flexible subject name matching
        column_defs = [
            {'name': 'Türkçe',    'x': 52,  'aliases': ['türkçe', 'turkce']},
            {'name': 'İnkılap',   'x': 172, 'aliases': ['inkılap', 'inkilap', 'tarih', 't.c.']},
            {'name': 'Din',       'x': 290, 'aliases': ['din', 'din kültürü', 'din kul']},
            {'name': 'İngilizce', 'x': 410, 'aliases': ['ingilizce', 'İngilizce', 'yabancı', 'yabancı dil', 'ing']},
            {'name': 'Matematik', 'x': 548, 'aliases': ['matematik', 'mat']},
            {'name': 'Fen',       'x': 666, 'aliases': ['fen', 'fen bilimleri', 'fen bil']}
        ]

        for col_def in column_defs:
            matching = None
            for s in subjects:
                sname = s.get('name', '').lower()
                # Flexible matching: check all aliases
                for alias in col_def['aliases']:
                    if alias.lower() in sname or sname in alias.lower():
                        matching = s
                        break
                if matching:
                    break

            if matching:
                questions = []
                count = matching.get('questionCount', 20)
                col_x = col_def['x']

                for i in range(count):
                    cur_y = start_y + (i * row_height)
                    questions.append({
                        'options': [
                            {'label': 'A', 'x': col_x,                'y': cur_y},
                            {'label': 'B', 'x': col_x + opt_step,     'y': cur_y},
                            {'label': 'C', 'x': col_x + opt_step * 2, 'y': cur_y},
                            {'label': 'D', 'x': col_x + opt_step * 3, 'y': cur_y}
                        ]
                    })
                grid[matching['name']] = questions
            else:
                print(f"OMR: WARNING - No matching subject for '{col_def['name']}'")

        print(f"OMR: Fixed grid generated with {len(grid)} subjects")
        return grid

    def _detect_bubble_rows(self, gray, pink_bands):
        """Detect where bubble rows start and their spacing."""
        h, w = gray.shape
        
        # Look for the region below the last significant pink band
        # The answer area is in the lower 60% of the form
        search_start = int(h * 0.3)
        
        if len(pink_bands) >= 2:
            # Use the last pink band as reference
            last_band = max(pink_bands, key=lambda b: b['y'] if b['y'] > h * 0.25 else 0)
            search_start = last_band['y_end'] + 20
        
        # Binary threshold for bubble detection
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # Project horizontally: count dark pixels per row
        row_profile = np.sum(binary[search_start:, :] > 0, axis=1).astype(float)
        
        # Smooth the profile
        kernel_size = 5
        kernel = np.ones(kernel_size) / kernel_size
        smoothed = np.convolve(row_profile, kernel, mode='same')
        
        # Find peaks (rows with many dark pixels = bubble rows)
        threshold = np.mean(smoothed) * 0.7
        peak_rows = []
        in_peak = False
        peak_start = 0
        
        for i, val in enumerate(smoothed):
            if val > threshold and not in_peak:
                in_peak = True
                peak_start = i
            elif val <= threshold and in_peak:
                in_peak = False
                peak_center = search_start + (peak_start + i) // 2
                if peak_center < h - 20:
                    peak_rows.append(peak_center)
        
        if len(peak_rows) < 3:
            # Fallback
            return search_start + 30, 31.0, 20
        
        # Calculate row spacing from consecutive peaks
        spacings = [peak_rows[i+1] - peak_rows[i] for i in range(len(peak_rows)-1)]
        # Filter out outliers (gaps between sections)
        median_spacing = np.median(spacings)
        valid_spacings = [s for s in spacings if abs(s - median_spacing) < median_spacing * 0.3]
        
        if valid_spacings:
            avg_spacing = np.mean(valid_spacings)
        else:
            avg_spacing = median_spacing
        
        return peak_rows[0], avg_spacing, min(len(peak_rows), 20)

    def _detect_column_positions(self, gray, start_y, row_height, num_rows):
        """Detect X positions of answer columns by analyzing vertical projection."""
        h, w = gray.shape
        end_y = min(int(start_y + row_height * num_rows), h)
        
        # Binary threshold
        _, binary = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # Vertical projection within the answer area
        col_profile = np.sum(binary[int(start_y):end_y, :] > 0, axis=0).astype(float)
        
        # Smooth
        kernel = np.ones(5) / 5
        smoothed = np.convolve(col_profile, kernel, mode='same')
        
        # Find clusters of high density (column positions)
        threshold = np.mean(smoothed) * 0.5
        
        peaks = []
        in_peak = False
        peak_start = 0
        peak_sum = 0
        
        for i, val in enumerate(smoothed):
            if val > threshold and not in_peak:
                in_peak = True
                peak_start = i
                peak_sum = val
            elif val > threshold and in_peak:
                peak_sum += val
            elif val <= threshold and in_peak:
                in_peak = False
                peak_center = (peak_start + i) // 2
                peak_width = i - peak_start
                if peak_width > 15 and peak_width < 150:  # Reasonable column width
                    peaks.append({'x': peak_center, 'width': peak_width, 'strength': peak_sum})
        
        # Group nearby peaks into column groups (4 bubbles per question)
        if len(peaks) < 4:
            # Fallback
            return [
                {'x': 90, 'name': 'col1'},
                {'x': 210, 'name': 'col2'},
                {'x': 330, 'name': 'col3'},
                {'x': 450, 'name': 'col4'},
                {'x': 605, 'name': 'col5'},
                {'x': 725, 'name': 'col6'}
            ]
        
        # Merge peaks that are close together into column groups
        columns = []
        current_group = [peaks[0]]
        
        for i in range(1, len(peaks)):
            if peaks[i]['x'] - current_group[-1]['x'] < 40:
                current_group.append(peaks[i])
            else:
                # Save group center
                group_x = int(np.mean([p['x'] for p in current_group]))
                columns.append({'x': group_x, 'width': current_group[-1]['x'] - current_group[0]['x'] + current_group[-1]['width']})
                current_group = [peaks[i]]
        
        # Last group
        group_x = int(np.mean([p['x'] for p in current_group]))
        columns.append({'x': group_x, 'width': current_group[-1]['x'] - current_group[0]['x'] + current_group[-1]['width']})
        
        return columns

    def _find_bubbles_in_region(self, gray, y1, y2, x1, x2):
        """Find individual bubble positions in a specific region."""
        region = gray[y1:y2, x1:x2]
        _, binary = cv2.threshold(region, 0, 255, cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU)
        
        # Find circles using HoughCircles
        circles = cv2.HoughCircles(
            region, cv2.HOUGH_GRADIENT, 1, 15,
            param1=50, param2=20, minRadius=5, maxRadius=15
        )
        
        if circles is None:
            return None
        
        # Sort by X position
        bubbles = sorted(circles[0], key=lambda c: c[0])
        
        # Filter to get 4 evenly spaced bubbles (A, B, C, D)
        if len(bubbles) >= 4:
            labels = ['A', 'B', 'C', 'D']
            # Take the 4 most evenly spaced ones
            result = []
            for i, (bx, by, br) in enumerate(bubbles[:4]):
                result.append({
                    'label': labels[i] if i < 4 else '?',
                    'x': int(bx + x1),
                    'y': int(by + y1)
                })
            return result
        
        return None

    def _build_grid_from_detection(self, start_y, row_height, columns, exam_data):
        """Build the answer grid from detected positions."""
        grid = {}
        
        if not exam_data or 'subjects' not in exam_data:
            return grid
        
        # Map detected columns to subjects
        subject_names = ['Türkçe', 'İnkılap', 'Din', 'İngilizce', 'Matematik', 'Fen']
        subjects = exam_data.get('subjects', [])
        
        opt_step = 24.5  # Distance between A, B, C, D bubbles
        
        for col_idx, col in enumerate(columns):
            if col_idx >= len(subject_names):
                break
            
            # Find matching subject
            target_name = subject_names[col_idx]
            matching = None
            for s in subjects:
                if target_name.lower() in s.get('name', '').lower() or s.get('name', '').lower() in target_name.lower():
                    matching = s
                    break
            
            if matching:
                questions = []
                count = matching.get('questionCount', 20)
                col_x = col['x'] - int(opt_step * 1.5)  # Center the 4 options around the column center
                
                for i in range(count):
                    cur_y = start_y + (i * row_height)
                    questions.append({
                        'options': [
                            {'label': 'A', 'x': col_x + opt_step * 0, 'y': cur_y},
                            {'label': 'B', 'x': col_x + opt_step * 1, 'y': cur_y},
                            {'label': 'C', 'x': col_x + opt_step * 2, 'y': cur_y},
                            {'label': 'D', 'x': col_x + opt_step * 3, 'y': cur_y}
                        ]
                    })
                grid[matching['name']] = questions
        
        return grid

    # ============== PAPER & CORNER DETECTION ==============

    def _find_and_warp_paper(self, img):
        ratio = max(img.shape[0], img.shape[1]) / 800.0
        small = cv2.resize(img, (int(img.shape[1] / ratio), int(img.shape[0] / ratio)))
        gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)
        
        for method in ['canny', 'adaptive']:
            if method == 'canny':
                edged = cv2.Canny(gray, 50, 150)
            else:
                edged = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                                               cv2.THRESH_BINARY_INV, 11, 2)
            
            kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
            edged = cv2.dilate(edged, kernel, iterations=1)
            cnts, _ = cv2.findContours(edged, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]
            
            for c in cnts:
                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.02 * peri, True)
                if len(approx) == 4 and cv2.contourArea(approx) > (small.shape[0] * small.shape[1] * 0.2):
                    pts = approx.reshape(4, 2).astype(np.float32) * ratio
                    return self._four_point_warp(img, pts)
        
        # Fallback: entire image
        h, w = img.shape[:2]
        pts = np.array([[0, 0], [w, 0], [w, h], [0, h]], dtype=np.float32)
        return self._four_point_warp(img, pts)

    def _detect_corner_squares(self, img):
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        _, binary = cv2.threshold(gray, 80, 255, cv2.THRESH_BINARY_INV)
        
        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        binary = cv2.morphologyEx(binary, cv2.MORPH_OPEN, kernel)
        binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)
        
        cnts, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        h, w = img.shape[:2]
        candidates = []
        
        for c in cnts:
            area = cv2.contourArea(c)
            if area < 100 or area > 5000:
                continue
            x, y, bw, bh = cv2.boundingRect(c)
            aspect = float(bw) / bh if bh > 0 else 0
            extent = area / (bw * bh) if (bw * bh) > 0 else 0
            if 0.5 < aspect < 2.0 and extent > 0.6:
                cx = x + bw // 2
                cy = y + bh // 2
                candidates.append({'x': cx, 'y': cy, 'area': area})
        
        if len(candidates) < 4:
            return None
        
        corners_target = [(0, 0), (w, 0), (0, h), (w, h)]
        found = []
        for tx, ty in corners_target:
            best = None
            best_dist = float('inf')
            for c in candidates:
                dist = np.sqrt((c['x'] - tx)**2 + (c['y'] - ty)**2)
                if dist < best_dist and dist < max(w, h) * 0.25:
                    best_dist = dist
                    best = c
            if best:
                found.append((best['x'], best['y']))
            else:
                return None
        
        print(f"OMR: Corners at {found}")
        return found

    def _warp_by_corners(self, img, corners):
        src = np.array(corners, dtype=np.float32)
        # Map corner centers to known positions
        # These define the coordinate system for the entire grid
        m = 20  # Corner squares are ~20px from edge in 800x1100 space
        dst = np.array([
            [m, m],
            [self.target_width - m, m],
            [m, self.target_height - m],
            [self.target_width - m, self.target_height - m]
        ], dtype=np.float32)
        M = cv2.getPerspectiveTransform(src, dst)
        return cv2.warpPerspective(img, M, (self.target_width, self.target_height))

    def _four_point_warp(self, img, pts):
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[2] = pts[np.argmax(s)]
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]
        rect[3] = pts[np.argmax(diff)]
        dst = np.array([
            [0, 0], [self.target_width-1, 0],
            [self.target_width-1, self.target_height-1], [0, self.target_height-1]
        ], dtype="float32")
        M = cv2.getPerspectiveTransform(rect, dst)
        return cv2.warpPerspective(img, M, (self.target_width, self.target_height))

    # ============== MARK READING ==============

    def _read_marks(self, thresh, gray, grid):
        results = {}
        search_radius = 12  # Increased for better alignment tolerance
        
        for subject, questions in grid.items():
            subject_answers = []
            for q in questions:
                option_scores = []
                for opt in q['options']:
                    x, y = int(opt['x']), int(opt['y'])
                    y1 = max(0, y - search_radius)
                    y2 = min(thresh.shape[0], y + search_radius)
                    x1 = max(0, x - search_radius)
                    x2 = min(thresh.shape[1], x + search_radius)
                    
                    if y2 <= y1 or x2 <= x1:
                        option_scores.append((opt['label'], 0))
                        continue
                    
                    roi_bin = thresh[y1:y2, x1:x2]
                    fill_ratio = np.sum(roi_bin > 0) / roi_bin.size if roi_bin.size > 0 else 0
                    
                    roi_gray = gray[y1:y2, x1:x2]
                    darkness = 1.0 - (np.mean(roi_gray) / 255.0) if roi_gray.size > 0 else 0
                    
                    score = fill_ratio * 0.6 + darkness * 0.4
                    option_scores.append((opt['label'], score))
                
                if not option_scores:
                    subject_answers.append(" ")
                    continue
                
                option_scores.sort(key=lambda x: x[1], reverse=True)
                best_label, best_score = option_scores[0]
                second_score = option_scores[1][1] if len(option_scores) > 1 else 0
                
                if best_score > self.detection_threshold:
                    if best_score > second_score * 1.5 or (best_score > 0.5 and second_score < 0.3):
                        subject_answers.append(best_label)
                    elif second_score > self.detection_threshold:
                        subject_answers.append("*")
                    else:
                        subject_answers.append(best_label)
                else:
                    subject_answers.append(" ")
            
            if subject == 'KITAPCIK':
                results[subject] = subject_answers[0] if subject_answers else "OKUNAMADI"
            else:
                results[subject] = "".join(subject_answers)
        
        return results

    def _draw_debug(self, img, grid, results):
        for subject, questions in grid.items():
            for i, q in enumerate(questions):
                for opt in q['options']:
                    x, y = int(opt['x']), int(opt['y'])
                    cv2.circle(img, (x, y), 8, (0, 255, 0), 1)
                    if subject in results:
                        if subject == 'KITAPCIK':
                            if results[subject] == opt['label']:
                                cv2.circle(img, (x, y), 8, (0, 0, 255), 2)
                        else:
                            answer_str = results[subject]
                            if i < len(answer_str) and answer_str[i] == opt['label']:
                                cv2.circle(img, (x, y), 8, (0, 0, 255), 2)
