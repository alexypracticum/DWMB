"""GraphQL schema for DWMB."""
import strawberry
from strawberry.fastapi import GraphQLRouter

from .queries import Query
from .mutations import Mutation

schema = strawberry.Schema(query=Query, mutation=Mutation)

graphql_router = GraphQLRouter(schema)
