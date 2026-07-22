"""
Entity routes — split into submodules for maintainability.
"""
from fastapi import APIRouter

router = APIRouter(tags=["entities"])

from .crud import router as crud_router
from .projections import router as projections_router
from .relations import router as relations_router
from .media import router as media_router

router.include_router(crud_router)
router.include_router(projections_router)
router.include_router(relations_router)
router.include_router(media_router)
