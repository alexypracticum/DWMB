"""GraphQL schema for DWMB."""
import strawberry
from strawberry.fastapi import GraphQLRouter

from .queries import Query
from .geo import GeoQuery
from .mutations import Mutation


@strawberry.type
class QueryRoot(Query, GeoQuery):
    pass


schema = strawberry.Schema(query=QueryRoot, mutation=Mutation)

graphql_router = GraphQLRouter(schema)
