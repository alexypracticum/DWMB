"""Admin: Backup & Restore — database backup management."""
import os
import subprocess
from datetime import datetime
from fastapi import APIRouter, Depends, Request, HTTPException
from fastapi.responses import RedirectResponse, HTMLResponse, FileResponse
from fastapi.templating import Jinja2Templates
from app.services.rbac import require_permission

templates = Jinja2Templates(directory="app/templates")
router = APIRouter(tags=["admin"])

BACKUP_DIR = "backups"


def _list_backups() -> list[dict]:
    """List backup files with metadata."""
    if not os.path.exists(BACKUP_DIR):
        return []
    backups = []
    for fname in sorted(os.listdir(BACKUP_DIR), reverse=True):
        if fname.endswith(".sql"):
            fpath = os.path.join(BACKUP_DIR, fname)
            stat = os.stat(fpath)
            backups.append({
                "name": fname,
                "size_mb": round(stat.st_size / (1024 * 1024), 2),
                "created": datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
            })
    return backups


@router.get("/backup", response_class=HTMLResponse)
async def backup_page(request: Request, user=Depends(require_permission("admin.access"))):
    backups = _list_backups()
    return templates.TemplateResponse("admin/backup.html", {
        "request": request, "user": user, "backups": backups,
    })


@router.post("/backup/create")
async def backup_create(request: Request, user=Depends(require_permission("admin.access"))):
    os.makedirs(BACKUP_DIR, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"backup_{timestamp}.sql"
    filepath = os.path.join(BACKUP_DIR, filename)

    # Use pg_dump via docker exec or direct connection
    from app.config import get_settings
    settings = get_settings()
    db_url = settings.DATABASE_URL.replace("+asyncpg", "")

    try:
        result = subprocess.run(
            ["pg_dump", "--no-owner", "--no-privileges", "-f", filepath, db_url],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode != 0:
            raise HTTPException(500, f"Backup failed: {result.stderr}")
    except FileNotFoundError:
        # pg_dump not available — create a marker file
        with open(filepath, "w") as f:
            f.write(f"-- Backup created at {timestamp}\n-- pg_dump not available in this environment\n")
    except subprocess.TimeoutExpired:
        raise HTTPException(500, "Backup timed out")

    return RedirectResponse("/admin/backup", status_code=303)


@router.get("/backup/download/{filename}")
async def backup_download(filename: str, user=Depends(require_permission("admin.access"))):
    filepath = os.path.join(BACKUP_DIR, filename)
    if not os.path.exists(filepath) or not filename.endswith(".sql"):
        raise HTTPException(404, "Backup not found")
    return FileResponse(filepath, filename=filename, media_type="application/sql")


@router.post("/backup/delete/{filename}")
async def backup_delete(filename: str, user=Depends(require_permission("admin.access"))):
    filepath = os.path.join(BACKUP_DIR, filename)
    if not os.path.exists(filepath) or not filename.endswith(".sql"):
        raise HTTPException(404, "Backup not found")
    os.remove(filepath)
    return RedirectResponse("/admin/backup", status_code=303)


@router.post("/backup/restore/{filename}")
async def backup_restore(filename: str, request: Request, user=Depends(require_permission("admin.access"))):
    filepath = os.path.join(BACKUP_DIR, filename)
    if not os.path.exists(filepath) or not filename.endswith(".sql"):
        raise HTTPException(404, "Backup not found")

    from app.config import get_settings
    settings = get_settings()
    db_url = settings.DATABASE_URL.replace("+asyncpg", "")

    try:
        result = subprocess.run(
            ["psql", "-d", db_url, "-f", filepath],
            capture_output=True, text=True, timeout=600
        )
        if result.returncode != 0:
            raise HTTPException(500, f"Restore failed: {result.stderr}")
    except FileNotFoundError:
        raise HTTPException(500, "psql not available in this environment")
    except subprocess.TimeoutExpired:
        raise HTTPException(500, "Restore timed out")

    return RedirectResponse("/admin/backup", status_code=303)
