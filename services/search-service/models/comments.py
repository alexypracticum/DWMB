"""
Comment model — comments on entities.
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class Comment(Base):
    __tablename__ = "comment"
    __table_args__ = {"schema": "meta"}

    comment_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    entity_id = Column(UUID(as_uuid=True), ForeignKey("meta.entity.entity_id", ondelete="CASCADE"), nullable=False)
    user_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id", ondelete="SET NULL"))
    parent_id = Column(UUID(as_uuid=True), ForeignKey("meta.comment.comment_id", ondelete="CASCADE"))
    content = Column(Text, nullable=False)
    is_approved = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    entity = relationship("Entity", backref="comments")
    user = relationship("UserAccount")
    parent = relationship("Comment", remote_side="Comment.comment_id", backref="replies")
