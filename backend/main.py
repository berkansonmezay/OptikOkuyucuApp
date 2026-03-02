from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from omr_processor import PythonOMREngine
import uvicorn
import base64
import json

app = FastAPI()
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

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
