import os
import httpx
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from app.routes import auth, entities, search, admin, stats, ai, editor_api, profile, page_management, theme_editor
from app.middleware.theme import ThemeMiddleware
from app.middleware.kinds import KindsMiddleware
from app.config import get_settings

app = FastAPI(title="DWMB Meta-System", docs_url="/docs", redoc_url=None)

app.add_middleware(KindsMiddleware)
app.add_middleware(ThemeMiddleware)

app.mount("/static", StaticFiles(directory="app/static"), name="static")

media_dir = os.path.join(os.path.dirname(__file__), "media")
os.makedirs(os.path.join(media_dir, "uploads"), exist_ok=True)


@app.api_route("/media/proxy", methods=["GET"])
async def media_proxy(url: str):
    """Proxy MinIO/external URLs to bypass CORS and Docker-internal hostnames."""
    settings = get_settings()
    # Replace Docker-internal MinIO hostname with public endpoint
    target_url = url.replace(f"http://{settings.MINIO_ENDPOINT}", f"http://{settings.MINIO_PUBLIC_ENDPOINT}")
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(target_url, follow_redirects=True)
        content_type = resp.headers.get("content-type", "application/octet-stream")
        return StreamingResponse(
            iter([resp.content]),
            media_type=content_type,
            headers={"Cache-Control": "public, max-age=86400"},
        )


app.mount("/media", StaticFiles(directory=media_dir), name="media")

app.include_router(auth.router)
app.include_router(entities.router)
app.include_router(search.router)
app.include_router(admin.router)
app.include_router(stats.router)
app.include_router(ai.router)
app.include_router(editor_api.router)
app.include_router(profile.router)
app.include_router(page_management.router)
app.include_router(theme_editor.router)
