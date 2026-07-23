"""
External API integrations for DWMB.
Provides search and import from IMDB, Wikipedia, MusicBrainz.
"""
import logging
from typing import Optional, List, Dict
import httpx

logger = logging.getLogger(__name__)


async def search_imdb(query: str, api_key: str = None) -> List[Dict]:
    """Search IMDB via OMDb API."""
    if not api_key:
        from app.config import get_settings
        api_key = get_settings().TMDB_API_KEY
    
    if not api_key:
        logger.warning("No API key for IMDB search")
        return []
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                "http://www.omdbapi.com/",
                params={"s": query, "apikey": api_key, "type": "movie"},
                timeout=10.0
            )
            data = resp.json()
            
            if data.get("Response") == "True":
                return [
                    {
                        "title": item.get("Title"),
                        "year": item.get("Year"),
                        "imdb_id": item.get("imdbID"),
                        "poster": item.get("Poster"),
                        "type": item.get("Type"),
                    }
                    for item in data.get("Search", [])[:10]
                ]
            return []
    except Exception as e:
        logger.error("IMDB search failed: %s", e)
        return []


async def get_imdb_details(imdb_id: str, api_key: str = None) -> Optional[Dict]:
    """Get detailed IMDB info by ID."""
    if not api_key:
        from app.config import get_settings
        api_key = get_settings().TMDB_API_KEY
    
    if not api_key:
        return None
    
    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                "http://www.omdbapi.com/",
                params={"i": imdb_id, "apikey": api_key},
                timeout=10.0
            )
            data = resp.json()
            
            if data.get("Response") == "True":
                return {
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
                }
            return None
    except Exception as e:
        logger.error("IMDB details failed: %s", e)
        return None


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
