"""GraphQL external API queries."""
import strawberry
from typing import List, Optional


@strawberry.type
class IMDBResult:
    title: Optional[str]
    year: Optional[str]
    imdb_id: Optional[str]
    poster: Optional[str]
    type: Optional[str]


@strawberry.type
class WikipediaResult:
    title: Optional[str]
    extract: Optional[str]
    url: Optional[str]
    thumbnail: Optional[str]


@strawberry.type
class MusicBrainzResult:
    id: Optional[str]
    title: Optional[str]
    type: Optional[str]
    artist: Optional[str]
    year: Optional[str]


@strawberry.type
class ExternalQuery:
    @strawberry.field
    async def search_imdb(self, query: str) -> List[IMDBResult]:
        """Search IMDB for movies."""
        from app.services.external_apis import search_imdb
        results = await search_imdb(query)
        return [
            IMDBResult(
                title=r.get("title"),
                year=r.get("year"),
                imdb_id=r.get("imdb_id"),
                poster=r.get("poster"),
                type=r.get("type"),
            )
            for r in results
        ]
    
    @strawberry.field
    async def search_wikipedia(self, query: str, lang: str = "ru") -> List[WikipediaResult]:
        """Search Wikipedia."""
        from app.services.external_apis import search_wikipedia
        results = await search_wikipedia(query, lang)
        return [
            WikipediaResult(
                title=r.get("title"),
                extract=r.get("extract"),
                url=r.get("url"),
                thumbnail=r.get("thumbnail"),
            )
            for r in results
        ]
    
    @strawberry.field
    async def search_musicbrainz(self, query: str, entityType: str = "recording") -> List[MusicBrainzResult]:
        """Search MusicBrainz."""
        from app.services.external_apis import search_musicbrainz
        results = await search_musicbrainz(query, entityType)
        return [
            MusicBrainzResult(
                id=r.get("id"),
                title=r.get("title"),
                type=r.get("type"),
                artist=r.get("artist"),
                year=r.get("year"),
            )
            for r in results
        ]
