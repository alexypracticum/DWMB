"""
API v1 GraphQL endpoint.
Proxies to the existing GraphQL schema.
"""
from fastapi import APIRouter
from strawberry.fastapi import GraphQLRouter

from app.graphql.schema import schema

router = APIRouter()

# Mount the existing GraphQL schema under /api/v1/graphql
graphql_router = GraphQLRouter(schema)
router.include_router(graphql_router)
