"""GraphQL schema for DWMB."""
import strawberry
from strawberry.fastapi import GraphQLRouter

from .queries import Query
from .geo import GeoQuery
from .external import ExternalQuery
from .mutations import Mutation
from .subscriptions import Subscription


@strawberry.type
class QueryRoot(Query, GeoQuery, ExternalQuery):
    pass


schema = strawberry.Schema(
    query=QueryRoot,
    mutation=Mutation,
    subscription=Subscription,
)

graphql_router = GraphQLRouter(schema)
