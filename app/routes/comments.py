"""
Comments routes — CRUD for entity comments.
"""
from fastapi import APIRouter, Depends, Request, Form, HTTPException
from fastapi.responses import RedirectResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from uuid import UUID

from app.database import get_db
from app.models.comments import Comment
from app.models.users import UserAccount
from app.services.auth import require_auth, get_current_user

router = APIRouter(tags=["comments"])


@router.post("/entity/{entity_id}/comment", summary="Добавить комментарий", description="Добавить комментарий к сущности")
async def add_comment(
    entity_id: str,
    request: Request,
    content: str = Form(...),
    parent_id: str = Form(None),
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Add a comment to an entity."""
    eid = UUID(entity_id)

    if not content.strip():
        raise HTTPException(400, "Comment cannot be empty")

    comment = Comment(
        entity_id=eid,
        user_id=user.user_id,
        parent_id=UUID(parent_id) if parent_id else None,
        content=content.strip(),
    )
    db.add(comment)
    await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}#comments", status_code=303)


@router.post("/comment/{comment_id}/delete", summary="Удалить комментарий", description="Удалить комментарий (свой или любой для admin)")
async def delete_comment(
    comment_id: str,
    db: AsyncSession = Depends(get_db),
    user: UserAccount = Depends(require_auth),
):
    """Delete a comment (own comments or admin)."""
    cid = UUID(comment_id)
    result = await db.execute(select(Comment).where(Comment.comment_id == cid))
    comment = result.scalar_one_or_none()

    if not comment:
        raise HTTPException(404)

    # Only author or admin can delete
    if comment.user_id != user.user_id and not user.is_admin:
        raise HTTPException(403)

    entity_id = comment.entity_id
    await db.delete(comment)
    await db.commit()

    return RedirectResponse(url=f"/entity/{entity_id}#comments", status_code=303)
