import cv2
import numpy as np
import base64
from pyzbar.pyzbar import decode
import json

class PythonOMREngine:
    def __init__(self):
        self.target_width = 800
        self.target_height = 1100
        self.bubble_radius = 10
        self.detection_threshold = 0.30

    def process_image_base64(self, base64_str, exam_data):
        # Decode base64 to OpenCV image
        encoded_data = base64_str.split(',')[1] if ',' in base64_str else base64_str
        nparr = np.frombuffer(base64.b64decode(encoded_data), np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return {"error": "Görüntü çözülemedi"}

        # 1. Perspective Warp
        warped = self._warp_perspective(img)
        if warped is None:
            return {"error": "Kağıt algılanamadı. Lütfen daha düz ve yakın çekin."}

        # 2. Preprocessing
        gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        
        # CLAHE for glare resistance
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
        gray = clahe.apply(gray)
        
        # Thresholding
        thresh = cv2.adaptiveThreshold(gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                     cv2.THRESH_BINARY_INV, 21, 10)

        # 3. QR Detection fallback for alignment
        qr_data = self._detect_qr(warped)
        
        # 4. Grid Alignment & Reading
        # (Assuming the grid generation logic is similar to JS)
        grid = self._generate_grid(exam_data)
        results = self._read_marks(thresh, grid)

        return {
            "booklet": results.get("KITAPCIK", "OKUNAMADI"),
            "answers": results,
            "success": True
        }

    def _warp_perspective(self, img):
        # Simplified contour detection for the paper
        ratio = img.shape[0] / 600.0
        orig = img.copy()
        small = cv2.resize(img, (int(img.shape[1] / ratio), 600))
        
        gray = cv2.cvtColor(small, cv2.COLOR_BGR2GRAY)
        gray = cv2.GaussianBlur(gray, (5, 5), 0)
        edged = cv2.Canny(gray, 75, 200)

        cnts, _ = cv2.findContours(edged.copy(), cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)
        cnts = sorted(cnts, key=cv2.contourArea, reverse=True)[:5]

        screenCnt = None
        for c in cnts:
            peri = cv2.arcLength(c, True)
            approx = cv2.approxPolyDP(c, 0.02 * peri, True)
            if len(approx) == 4:
                screenCnt = approx
                break

        if screenCnt is None:
            return None

        # Warp logic
        pts = screenCnt.reshape(4, 2) * ratio
        rect = np.zeros((4, 2), dtype="float32")
        s = pts.sum(axis=1)
        rect[0] = pts[np.argmin(s)]
        rect[3] = pts[np.argmax(s)]
        diff = np.diff(pts, axis=1)
        rect[1] = pts[np.argmin(diff)]
        rect[2] = pts[np.argmax(diff)]

        dst = np.array([
            [0, 0],
            [self.target_width - 1, 0],
            [0, self.target_height - 1],
            [self.target_width - 1, self.target_height - 1]], dtype="float32")

        M = cv2.getPerspectiveTransform(rect, dst)
        return cv2.warpPerspective(orig, M, (self.target_width, self.target_height))

    def _detect_qr(self, img):
        decoded_objects = decode(img)
        for obj in decoded_objects:
            return obj.data.decode('utf-8')
        return None

    def _generate_grid(self, exam):
        # Ported from JS grid logic
        grid = {}
        # Booklet
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
            {'name': 'Türkçe', 'x': 64},
            {'name': 'İnkılap', 'x': 184},
            {'name': 'Din', 'x': 304},
            {'name': 'İngilizce', 'x': 424},
            {'name': 'Matematik', 'x': 578},
            {'name': 'Fen', 'x': 698}
        ]

        for col in columns:
            matching_subject = next((s for s in exam['subjects'] if col['name'].lower() in s['name'].lower()), None)
            if matching_subject:
                questions = []
                count = matching_subject.get('questionCount', 20)
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
                grid[matching_subject['name']] = questions
        return grid

    def _read_marks(self, thresh, grid):
        results = {}
        search_size = 6
        
        for subject, questions in grid.items():
            subject_answers = []
            for q in questions:
                marked_options = []
                for opt in q['options']:
                    x, y = int(opt['x']), int(opt['y'])
                    # Region of interest
                    roi = thresh[y-search_size:y+search_size, x-search_size:x+search_size]
                    if roi.size == 0: continue
                    
                    intensity = np.mean(roi) / 255.0
                    if intensity > self.detection_threshold:
                        marked_options.append(opt['label'])
                
                if len(marked_options) == 1:
                    subject_answers.append(marked_options[0])
                elif len(marked_options) > 1:
                    subject_answers.append("*") # Double mark
                else:
                    subject_answers.append(" ") # Empty
            
            if subject == 'KITAPCIK':
                 results[subject] = subject_answers[0] if subject_answers else "OKUNAMADI"
            else:
                 results[subject] = "".join(subject_answers)
                 
        return results
