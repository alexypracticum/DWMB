"""
API v1 router — versioned API endpoints.
All endpoints are prefixed with /api/v1/.
"""
from fastapi import APIRouter

router = APIRouter(prefix="/api/v1", tags=["api-v1"])

# Import and include v1 sub-routers
from . import entities, kinds, relations, search

router.include_router(entities.router, prefix="/entities", tags=["entities"])
router.include_router(kinds.router, prefix="/kinds", tags=["kinds"])
router.include_router(relations.router, prefix="/relations", tags=["relations"])
router.include_router(search.router, prefix="/search", tags=["search"])
# GraphQL is available at /graphql (not versioned)
