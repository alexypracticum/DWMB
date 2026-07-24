"""
External API integrations for DWMB.
Provides search and import from IMDB, Wikipedia, MusicBrainz.
"""
import logging
import asyncio
import time
from typing import Optional, List, Dict
import httpx

logger = logging.getLogger(__name__)

# Simple in-memory rate limiter for external APIs
_api_rate_limits: Dict[str, float] = {}
OMDB_MIN_INTERVAL = 0.5  # 500ms between requests (OMDb free tier: 1000/day)


def _check_rate_limit(api_name: str, min_interval: float = OMDB_MIN_INTERVAL) -> bool:
    """Check if we can make a request (rate limit)."""
    now = time.time()
    last_call = _api_rate_limits.get(api_name, 0)
    if now - last_call < min_interval:
        return False
    _api_rate_limits[api_name] = now
    return True


async def search_imdb(query: str, api_key: str = None) -> List[Dict]:
    """Search IMDB via OMDb API. Results are cached for 1 hour."""
    if not api_key:
        from app.config import get_settings
        api_key = get_settings().OMDB_API_KEY

    if not api_key:
        logger.warning("No OMDB_API_KEY configured")
        return []

    # Check cache
    from app.services.cache import cache_get, cache_set
    cache_key = f"omdb:search:{query.lower().strip()}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    # Rate limit
    if not _check_rate_limit("omdb"):
        await asyncio.sleep(0.5)

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                "http://www.omdbapi.com/",
                params={"s": query, "apikey": api_key, "type": "movie"},
                timeout=10.0
            )
            data = resp.json()

            if data.get("Response") == "True":
                results = [
                    {
                        "title": item.get("Title"),
                        "year": item.get("Year"),
                        "imdb_id": item.get("imdbID"),
                        "poster": item.get("Poster"),
                        "type": item.get("Type"),
                    }
                    for item in data.get("Search", [])[:10]
                ]
                await cache_set(cache_key, results, ttl=3600)  # Cache 1 hour
                return results
            return []
    except Exception as e:
        logger.error("IMDB search failed: %s", e)
        return []


async def get_imdb_details(imdb_id: str, api_key: str = None) -> Optional[Dict]:
    """Get detailed IMDB info by ID. Results are cached for 24 hours."""
    if not api_key:
        from app.config import get_settings
        api_key = get_settings().OMDB_API_KEY

    if not api_key:
        return None

    # Check cache
    from app.services.cache import cache_get, cache_set
    cache_key = f"omdb:details:{imdb_id}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    # Rate limit
    if not _check_rate_limit("omdb"):
        await asyncio.sleep(0.5)

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                "http://www.omdbapi.com/",
                params={"i": imdb_id, "apikey": api_key, "plot": "full"},
                timeout=10.0
            )
            data = resp.json()

            if data.get("Response") == "True":
                result = {
                    "title": data.get("Title"),
                    "year": data.get("Year"),
                    "imdb_id": data.get("imdbID"),
                    "poster": data.get("Poster"),
                    "plot": data.get("Plot"),
                    "director": data.get("Director"),
                    "actors": data.get("Actors"),
                    "genre": data.get("Genre"),
                    "rating": data.get("imdbRating"),
                    "runtime": data.get("Runtime"),
                    "rated": data.get("Rated"),
                    "released": data.get("Released"),
                    "language": data.get("Language"),
                    "country": data.get("Country"),
                    "awards": data.get("Awards"),
                    "metascore": data.get("Metascore"),
                    "votes": data.get("imdbVotes"),
                }
                await cache_set(cache_key, result, ttl=86400)  # Cache 24 hours
                return result
            return None
    except Exception as e:
        logger.error("IMDB details failed: %s", e)
        return None


async def import_imdb_movie(db, imdb_data: Dict, user_id) -> Dict:
    """Import an OMDb movie as an entity in the database.

    Args:
        db: AsyncSession
        imdb_data: Dict from get_imdb_details()
        user_id: UUID of the importing user

    Returns:
        Dict with entity_id and status
    """
    import hashlib, json
    from uuid import uuid4
    from sqlalchemy import select
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate
    from app.models.languages import Language
    from app.services.language import get_language_id

    imdb_id = imdb_data.get("imdb_id", "")
    entity_code = f"omdb_{imdb_id}"

    # Check if already exists
    existing = await db.execute(select(Entity).where(Entity.entity_code == entity_code))
    if existing.scalar_one_or_none():
        return {"status": "exists", "entity_code": entity_code, "message": "Movie already imported"}

    # Get or create film kind
    kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "film"))).scalars().first()
    if not kind:
        kind = EntityKind(
            kind_code="film",
            description="Film/movie entity",
            is_abstract=False,
            sort_order=100,
            version_id=1,
        )
        db.add(kind)
        await db.flush()
        ru_lang_id = await get_language_id(db, "ru")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label="Фильм", description="Film"))

    # Get version
    from sqlalchemy import func
    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Create entity
    eid = uuid4()
    entity = Entity(
        entity_id=eid,
        entity_code=entity_code,
        kind_id=kind.kind_id,
        status="active",
        image_url=imdb_data.get("poster"),
        owner_id=user_id,
        version_id=version_id,
    )
    db.add(entity)
    await db.flush()

    # Create label
    ru_lang_id = await get_language_id(db, "ru")
    label = EntityLabel(
        entity_id=eid,
        language_id=ru_lang_id,
        label=imdb_data.get("title", ""),
        description=imdb_data.get("plot", ""),
        is_primary=True,
        owner_id=user_id,
        version_id=version_id,
    )
    db.add(label)

    # Get template for film kind
    tmpl = (await db.execute(
        select(OntologyTemplate).where(OntologyTemplate.kind_id == kind.kind_id, OntologyTemplate.is_active == True).limit(1)
    )).scalars().first()

    # Create projection
    proj_id = uuid4()
    proj = EntityProjection(
        projection_id=proj_id,
        entity_id=eid,
        model_id=tmpl.model_id if tmpl else uuid4(),
        template_id=tmpl.template_id if tmpl else None,
        projection_code=entity_code,
        projection_name=imdb_data.get("title", ""),
        confidence=1.0,
        version_id=version_id,
    )
    db.add(proj)
    await db.flush()

    # Create state data
    state_data = {
        "imdb_id": imdb_id,
        "title": imdb_data.get("title", ""),
        "year": imdb_data.get("year", ""),
        "poster": imdb_data.get("poster", ""),
        "plot": imdb_data.get("plot", ""),
        "director": imdb_data.get("director", ""),
        "actors": imdb_data.get("actors", ""),
        "genre": imdb_data.get("genre", ""),
        "rating": imdb_data.get("rating", ""),
        "runtime": imdb_data.get("runtime", ""),
        "rated": imdb_data.get("rated", ""),
        "released": imdb_data.get("released", ""),
        "language": imdb_data.get("language", ""),
        "country": imdb_data.get("country", ""),
        "awards": imdb_data.get("awards", ""),
        "metascore": imdb_data.get("metascore", ""),
        "votes": imdb_data.get("votes", ""),
    }
    state_hash = hashlib.sha256(json.dumps(state_data, sort_keys=True, default=str).encode()).hexdigest()

    db.add(ProjectionState(
        projection_id=proj_id,
        state_data=state_data,
        state_hash=state_hash,
        is_current=True,
        version_id=version_id,
    ))

    return {"status": "created", "entity_id": str(eid), "entity_code": entity_code}


async def search_wikipedia(query: str, lang: str = "ru") -> List[Dict]:
    """Search Wikipedia API."""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"https://{lang}.wikipedia.org/api/rest_v1/page/summary/{query}",
                timeout=10.0,
                headers={"User-Agent": "DWMB/1.0"}
            )
            
            if resp.status_code == 200:
                data = resp.json()
                return [{
                    "title": data.get("title"),
                    "extract": data.get("extract"),
                    "url": data.get("content_urls", {}).get("desktop", {}).get("page"),
                    "thumbnail": data.get("thumbnail", {}).get("source"),
                }]
            return []
    except Exception as e:
        logger.error("Wikipedia search failed: %s", e)
        return []


async def get_wikipedia_page(title: str, lang: str = "ru") -> Optional[Dict]:
    """Get Wikipedia page content."""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"https://{lang}.wikipedia.org/api/rest_v1/page/summary/{title}",
                timeout=10.0,
                headers={"User-Agent": "DWMB/1.0"}
            )
            
            if resp.status_code == 200:
                data = resp.json()
                return {
                    "title": data.get("title"),
                    "extract": data.get("extract"),
                    "url": data.get("content_urls", {}).get("desktop", {}).get("page"),
                    "thumbnail": data.get("thumbnail", {}).get("source"),
                    "description": data.get("description"),
                }
            return None
    except Exception as e:
        logger.error("Wikipedia page failed: %s", e)
        return None


async def search_musicbrainz(query: str, entity_type: str = "recording") -> List[Dict]:
    """Search MusicBrainz API."""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"https://musicbrainz.org/ws/2/{entity_type}",
                params={"query": query, "fmt": "json", "limit": 10},
                timeout=10.0,
                headers={"User-Agent": "DWMB/1.0 (contact@example.com)"}
            )
            
            if resp.status_code == 200:
                data = resp.json()
                results = []
                
                for item in data.get(f"{entity_type}s", []):
                    result = {
                        "id": item.get("id"),
                        "title": item.get("title") or item.get("name"),
                        "type": entity_type,
                    }
                    
                    if entity_type == "recording" and "artist-credit" in item:
                        artists = [a.get("name") for a in item["artist-credit"]]
                        result["artist"] = ", ".join(artists)
                    
                    if "first-release-date" in item:
                        result["year"] = item["first-release-date"][:4]
                    
                    results.append(result)
                
                return results
            return []
    except Exception as e:
        logger.error("MusicBrainz search failed: %s", e)
        return []


async def get_musicbrainz_artist(artist_id: str) -> Optional[Dict]:
    """Get MusicBrainz artist details."""
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                f"https://musicbrainz.org/ws/2/artist/{artist_id}",
                params={"fmt": "json"},
                timeout=10.0,
                headers={"User-Agent": "DWMB/1.0 (contact@example.com)"}
            )
            
            if resp.status_code == 200:
                data = resp.json()
                return {
                    "id": data.get("id"),
                    "name": data.get("name"),
                    "type": data.get("type"),
                    "country": data.get("country"),
                    "disambiguation": data.get("disambiguation"),
                    "life-span": data.get("life-span"),
                }
            return None
    except Exception as e:
        logger.error("MusicBrainz artist failed: %s", e)
        return None
