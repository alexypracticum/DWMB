"""
RBAC (Role-Based Access Control) models.

Tables:
- role: named roles (admin, editor, viewer)
- permission: granular permissions (entity.create, entity.read, etc.)
- role_permission: many-to-many role ↔ permission
- user_role: many-to-many user ↔ role
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Text, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base


class Role(Base):
    __tablename__ = "role"
    __table_args__ = {"schema": "meta"}

    role_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    role_code = Column(String, unique=True, nullable=False)
    role_name = Column(String, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    permissions = relationship("Permission", secondary="meta.role_permission", back_populates="roles")
    users = relationship("UserAccount", secondary="meta.user_role", back_populates="roles")


class Permission(Base):
    __tablename__ = "permission"
    __table_args__ = {"schema": "meta"}

    permission_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    permission_code = Column(String, unique=True, nullable=False)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    roles = relationship("Role", secondary="meta.role_permission", back_populates="permissions")


class RolePermission(Base):
    __tablename__ = "role_permission"
    __table_args__ = (
        UniqueConstraint("role_id", "permission_id"),
        {"schema": "meta"},
    )

    role_id = Column(UUID(as_uuid=True), ForeignKey("meta.role.role_id", ondelete="CASCADE"), primary_key=True)
    permission_id = Column(UUID(as_uuid=True), ForeignKey("meta.permission.permission_id", ondelete="CASCADE"), primary_key=True)


class UserRole(Base):
    __tablename__ = "user_role"
    __table_args__ = (
        UniqueConstraint("user_id", "role_id"),
        {"schema": "meta"},
    )

    user_id = Column(UUID(as_uuid=True), ForeignKey("meta.user_account.user_id", ondelete="CASCADE"), primary_key=True)
    role_id = Column(UUID(as_uuid=True), ForeignKey("meta.role.role_id", ondelete="CASCADE"), primary_key=True)
