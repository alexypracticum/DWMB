"""
AI Microservice for DWMB.
Handles embeddings, chat, and entity parsing.
"""
import os
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="DWMB AI Service", version="1.0.0")

# Configuration
OPENAI_API_KEY = os.getenv("AI_API_KEY", "")
OPENAI_BASE_URL = os.getenv("AI_BASE_URL", "https://api.openai.com/v1")
EMBEDDING_MODEL = os.getenv("AI_MODEL_EMBEDDING", "text-embedding-3-small")
CHAT_MODEL = os.getenv("AI_MODEL_CHAT", "gpt-4o-mini")


class EmbeddingRequest(BaseModel):
    text: str
    model: str = EMBEDDING_MODEL


class EmbeddingResponse(BaseModel):
    embedding: List[float]
    model: str
    dimensions: int


class ChatRequest(BaseModel):
    messages: List[dict]
    model: str = CHAT_MODEL
    temperature: float = 0.7
    max_tokens: int = 1000


class ChatResponse(BaseModel):
    content: str
    model: str
    usage: dict


class ParseTextRequest(BaseModel):
    text: str
    entity_type: Optional[str] = None


class ParseTextResponse(BaseModel):
    entities: List[dict]
    raw_response: str


@app.get("/health")
async def health():
    return {"status": "ok", "service": "ai-service"}


@app.post("/embeddings", response_model=EmbeddingResponse)
async def create_embedding(request: EmbeddingRequest):
    """Create embedding for text."""
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=503, detail="AI API key not configured")
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{OPENAI_BASE_URL}/embeddings",
                headers={"Authorization": f"Bearer {OPENAI_API_KEY}"},
                json={"input": request.text, "model": request.model},
                timeout=30.0
            )
            data = resp.json()
            
            if "data" in data and len(data["data"]) > 0:
                return EmbeddingResponse(
                    embedding=data["data"][0]["embedding"],
                    model=data["model"],
                    dimensions=len(data["data"][0]["embedding"])
                )
            else:
                raise HTTPException(status_code=500, detail="Failed to create embedding")
    except Exception as e:
        logger.error(f"Embedding error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Chat with LLM."""
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=503, detail="AI API key not configured")
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{OPENAI_BASE_URL}/chat/completions",
                headers={"Authorization": f"Bearer {OPENAI_API_KEY}"},
                json={
                    "model": request.model,
                    "messages": request.messages,
                    "temperature": request.temperature,
                    "max_tokens": request.max_tokens
                },
                timeout=60.0
            )
            data = resp.json()
            
            if "choices" in data and len(data["choices"]) > 0:
                return ChatResponse(
                    content=data["choices"][0]["message"]["content"],
                    model=data["model"],
                    usage=data.get("usage", {})
                )
            else:
                raise HTTPException(status_code=500, detail="Failed to get chat response")
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/parse-text", response_model=ParseTextResponse)
async def parse_text(request: ParseTextRequest):
    """Parse text to extract entities."""
    if not OPENAI_API_KEY:
        raise HTTPException(status_code=503, detail="AI API key not configured")
    
    try:
        system_prompt = """Extract entities from the text. Return a JSON array of objects with:
        - name: entity name
        - type: entity type (person, organization, location, etc.)
        - description: brief description
        Only return the JSON array, no other text."""
        
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{OPENAI_BASE_URL}/chat/completions",
                headers={"Authorization": f"Bearer {OPENAI_API_KEY}"},
                json={
                    "model": CHAT_MODEL,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": request.text}
                    ],
                    "temperature": 0.3
                },
                timeout=30.0
            )
            data = resp.json()
            
            content = data["choices"][0]["message"]["content"]
            
            # Try to parse JSON from response
            import json
            try:
                entities = json.loads(content)
            except:
                entities = []
            
            return ParseTextResponse(
                entities=entities,
                raw_response=content
            )
    except Exception as e:
        logger.error(f"Parse text error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
