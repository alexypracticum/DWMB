"""
Admin routes — split into submodules for maintainability.
Combined into a single router for backwards compatibility.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/admin", tags=["admin"])

# Import and include all sub-module routers
from .dashboard import router as dashboard_router
from .kinds import router as kinds_router
from .templates import router as templates_router
from .fields import router as fields_router
from .models import router as models_router
from .ai import router as ai_router
from .relation_types import router as relation_types_router
from .languages import router as languages_router
from .ui_translations import router as ui_translations_router
from .users import router as users_router
from .plugins import router as plugins_router

router.include_router(dashboard_router)
router.include_router(kinds_router)
router.include_router(templates_router)
router.include_router(fields_router)
router.include_router(models_router)
router.include_router(ai_router)
router.include_router(relation_types_router)
router.include_router(languages_router)
router.include_router(ui_translations_router)
router.include_router(users_router)
router.include_router(plugins_router)
