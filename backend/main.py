from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from omr_processor import PythonOMREngine
import uvicorn
import base64
import json

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine = PythonOMREngine()

class OMRRequest(BaseModel):
    image: str # Base64
    examData: Dict[str, Any]

@app.get("/")
async def root():
    return {"status": "Optik Okuyucu Python Backend Çalışıyor"}

@app.post("/process-omr")
async def process_omr(request: OMRRequest):
    try:
        result = engine.process_image_base64(request.image, request.examData)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

import socket

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

if __name__ == "__main__":
    local_ip = get_local_ip()
    print("\n" + "="*50)
    print("OPTİK OKUYUCU BACKEND BAŞLATILIYOR")
    print(f"YEREL IP ADRESİNİZ: {local_ip}")
    print(f"Uygulamada şu adresi kullanın: http://{local_ip}:8000/process-omr")
    print("="*50 + "\n")
    uvicorn.run(app, host="0.0.0.0", port=8000)
