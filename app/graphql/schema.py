"""GraphQL schema for DWMB."""
import strawberry
from strawberry.fastapi import GraphQLRouter

from .queries import Query

schema = strawberry.Schema(query=Query)

graphql_router = GraphQLRouter(schema)
