"""
TMDB API integration service.
Provides search and import for movies, TV shows, and people.

Supports both v3 API keys and v4 JWT tokens.

API docs: https://developer.themoviedb.org/reference/intro/getting-started
"""
import asyncio
import logging
import httpx
from typing import Optional
from app.config import get_settings

logger = logging.getLogger(__name__)

TMDB_BASE_URL = "https://api.themoviedb.org/3"
TMDB_IMAGE_BASE = "https://image.tmdb.org/t/p"
MAX_RETRIES = 3
RETRY_BACKOFF = 1.0  # seconds, doubled each retry


class TMDBService:
    """Service for interacting with The Movie Database API."""

    def __init__(self):
        self.settings = get_settings()
        self.api_key = self.settings.TMDB_API_KEY
        self.base_url = TMDB_BASE_URL
        self.image_base = TMDB_IMAGE_BASE
        self._is_v4 = self._detect_v4_key()

    def _detect_v4_key(self) -> bool:
        """Detect if API key is a v4 JWT token."""
        if not self.api_key:
            return False
        parts = self.api_key.split(".")
        return len(parts) == 3  # JWT has 3 parts: header.payload.signature

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key)

    async def _request(self, endpoint: str, params: dict = None) -> Optional[dict]:
        """Make authenticated request to TMDB API with retry and rate-limit handling."""
        if not self.api_key:
            logger.warning("TMDB API key not configured, skipping request to %s", endpoint)
            return None

        url = f"{self.base_url}{endpoint}"
        params = params or {}
        params["language"] = "ru-RU"

        headers = {}
        if self._is_v4:
            headers["Authorization"] = f"Bearer {self.api_key}"
        else:
            params["api_key"] = self.api_key

        for attempt in range(MAX_RETRIES):
            async with httpx.AsyncClient(timeout=30) as client:
                try:
                    resp = await client.get(url, params=params, headers=headers)
                    if resp.status_code == 200:
                        return resp.json()
                    if resp.status_code == 429:
                        retry_after = int(resp.headers.get("Retry-After", RETRY_BACKOFF * (2 ** attempt)))
                        logger.warning("TMDB rate limit hit on %s, retrying after %ds (attempt %d/%d)",
                                       endpoint, retry_after, attempt + 1, MAX_RETRIES)
                        await asyncio.sleep(retry_after)
                        continue
                    logger.warning("TMDB API returned %d for %s: %s", resp.status_code, endpoint, resp.text[:200])
                    return None
                except httpx.TimeoutException:
                    logger.warning("TMDB timeout on %s (attempt %d/%d)", endpoint, attempt + 1, MAX_RETRIES)
                    await asyncio.sleep(RETRY_BACKOFF * (2 ** attempt))
                except httpx.RequestError as e:
                    logger.error("TMDB request error on %s: %s", endpoint, e)
                    return None

        logger.error("TMDB request failed after %d retries for %s", MAX_RETRIES, endpoint)
        return None

    # ─── Movies ───────────────────────────────────────────────

    async def search_movies(self, query: str, page: int = 1) -> list[dict]:
        """Search movies by title."""
        data = await self._request("/search/movie", {"query": query, "page": page})
        if not data:
            return []

        results = []
        for item in data.get("results", [])[:10]:
            results.append({
                "tmdb_id": item["id"],
                "title": item.get("title", ""),
                "original_title": item.get("original_title", ""),
                "year": self._extract_year(item.get("release_date")),
                "genre": ", ".join(g["name"] for g in self._get_genres(item.get("genre_ids", []))),
                "rating": item.get("vote_average", 0),
                "description": item.get("overview", ""),
                "poster": f"{self.image_base}/w500{item['poster_path']}" if item.get("poster_path") else None,
                "language": item.get("original_language", ""),
                "vote_count": item.get("vote_count", 0),
            })
        return results

    async def get_movie(self, tmdb_id: int) -> Optional[dict]:
        """Get detailed movie information."""
        data = await self._request(f"/movie/{tmdb_id}")
        if not data:
            return None

        # Get credits for director and cast
        credits = await self._request(f"/movie/{tmdb_id}/credits")
        director = ""
        cast = []
        if credits:
            for crew in credits.get("crew", []):
                if crew.get("job") == "Director":
                    director = crew.get("name", "")
                    break
            for person in credits.get("cast", [])[:10]:
                cast.append({
                    "name": person.get("name", ""),
                    "character": person.get("character", ""),
                    "tmdb_id": person.get("id"),
                })

        # Get production companies
        companies = [c.get("name", "") for c in data.get("production_companies", [])]

        # Get languages
        languages = [l.get("name", "") for l in data.get("spoken_languages", [])]

        return {
            "tmdb_id": data["id"],
            "title": data.get("title", ""),
            "original_title": data.get("original_title", ""),
            "year": self._extract_year(data.get("release_date")),
            "genre": ", ".join(g["name"] for g in data.get("genres", [])),
            "rating": data.get("vote_average", 0),
            "description": data.get("overview", ""),
            "poster": f"{self.image_base}/w500{data['poster_path']}" if data.get("poster_path") else None,
            "runtime": data.get("runtime"),
            "budget": data.get("budget"),
            "revenue": data.get("revenue"),
            "tagline": data.get("tagline", ""),
            "country": ", ".join(c.get("name", "") for c in data.get("production_countries", [])),
            "language": ", ".join(languages),
            "production_company": ", ".join(companies),
            "director": director,
            "cast": cast,
            "imdb_id": data.get("imdb_id"),
            "vote_count": data.get("vote_count", 0),
        }

    async def get_movie_credits(self, tmdb_id: int) -> dict:
        """Get movie credits (cast and crew)."""
        data = await self._request(f"/movie/{tmdb_id}/credits")
        if not data:
            return {"cast": [], "crew": []}

        cast = []
        for person in data.get("cast", [])[:20]:
            cast.append({
                "tmdb_id": person.get("id"),
                "name": person.get("name", ""),
                "character": person.get("character", ""),
                "order": person.get("order", 99),
                "profile_path": person.get("profile_path"),
            })

        crew = []
        for person in data.get("crew", []):
            crew.append({
                "tmdb_id": person.get("id"),
                "name": person.get("name", ""),
                "job": person.get("job", ""),
                "department": person.get("department", ""),
                "profile_path": person.get("profile_path"),
            })

        return {"cast": cast, "crew": crew}

    # ─── People ───────────────────────────────────────────────

    async def search_persons(self, query: str, page: int = 1) -> list[dict]:
        """Search people by name."""
        data = await self._request("/search/person", {"query": query, "page": page})
        if not data:
            return []

        results = []
        for item in data.get("results", [])[:10]:
            known = item.get("known_for", [])
            known_for = []
            for k in known:
                if k.get("media_type") == "movie":
                    known_for.append(k.get("title", ""))
                elif k.get("media_type") == "tv":
                    known_for.append(k.get("name", ""))

            results.append({
                "tmdb_id": item["id"],
                "name": item.get("name", ""),
                "birthday": item.get("birthday"),
                "birthplace": item.get("place_of_birth", ""),
                "biography": item.get("biography", ""),
                "poster": f"{self.image_base}/w186{item['profile_path']}" if item.get("profile_path") else None,
                "known_for": ", ".join(known_for[:3]),
                "popularity": item.get("popularity", 0),
            })
        return results

    async def get_person(self, tmdb_id: int) -> Optional[dict]:
        """Get detailed person information."""
        data = await self._request(f"/person/{tmdb_id}")
        if not data:
            return None

        # Get filmography
        credits = await self._request(f"/person/{tmdb_id}/combined_credits")
        filmography = []
        if credits:
            for item in credits.get("cast", [])[:10]:
                if item.get("media_type") == "movie":
                    filmography.append({
                        "tmdb_id": item.get("id"),
                        "title": item.get("title", ""),
                        "character": item.get("character", ""),
                        "year": self._extract_year(item.get("release_date")),
                    })

        return {
            "tmdb_id": data["id"],
            "name": data.get("name", ""),
            "birthday": data.get("birthday"),
            "deathday": data.get("deathday"),
            "birthplace": data.get("place_of_birth", ""),
            "biography": data.get("biography", ""),
            "poster": f"{self.image_base}/w186{data['profile_path']}" if data.get("profile_path") else None,
            "known_for_department": data.get("known_for_department", ""),
            "filmography": filmography,
        }

    # ─── Genres ───────────────────────────────────────────────

    async def get_genres(self) -> list[dict]:
        """Get all movie genres."""
        data = await self._request("/genre/movie/list")
        if not data:
            return []
        return [{"tmdb_id": g["id"], "name": g["name"]} for g in data.get("genres", [])]

    # ─── Helpers ──────────────────────────────────────────────

    def _extract_year(self, date_str: str) -> Optional[int]:
        """Extract year from date string."""
        if date_str and len(date_str) >= 4:
            try:
                return int(date_str[:4])
            except ValueError:
                pass
        return None

    def _get_genres(self, genre_ids: list[int]) -> list[dict]:
        """Get genre names from IDs (uses cached list)."""
        # This would need a genre cache in production
        genre_map = {
            28: {"name": "Боевик"}, 12: {"name": "Приключения"}, 16: {"name": "Мультфильм"},
            35: {"name": "Комедия"}, 80: {"name": "Криминал"}, 99: {"name": "Документальный"},
            18: {"name": "Драма"}, 10751: {"name": "Семейный"}, 14: {"name": "Фэнтези"},
            36: {"name": "Исторический"}, 27: {"name": "Ужасы"}, 10402: {"name": "Музыка"},
            9648: {"name": "Детектив"}, 10749: {"name": "Мелодрама"}, 878: {"name": "Фантастика"},
            10770: {"name": "ТВ фильм"}, 53: {"name": "Триллер"}, 10752: {"name": "Военный"},
            37: {"name": "Вестерн"},
        }
        return [genre_map.get(gid, {"name": str(gid)}) for gid in genre_ids]


# Singleton instance
tmdb_service = TMDBService()
