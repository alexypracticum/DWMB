"""
Last.fm API integration for DWMB.
Provides listening history, top tracks/artists/albums with MusicBrainz cross-reference.
"""
import logging
import asyncio
import time
from typing import Optional, List, Dict

import httpx

logger = logging.getLogger(__name__)

LASTFM_BASE = "https://ws.audioscrobbler.com/2.0/"
LASTFM_MIN_INTERVAL = 0.25  # 250ms between requests (Last.fm allows ~5/sec)

_api_last_call: Dict[str, float] = {}


async def _rate_limit():
    now = time.time()
    last = _api_last_call.get("lastfm", 0)
    wait = LASTFM_MIN_INTERVAL - (now - last)
    if wait > 0:
        await asyncio.sleep(wait)
    _api_last_call["lastfm"] = time.time()


def _get_api_key() -> Optional[str]:
    from app.config import get_settings
    return get_settings().LASTFM_API_KEY


async def _lastfm_request(method: str, params: Dict) -> Optional[Dict]:
    """Make a request to Last.fm API with caching and rate limiting."""
    api_key = _get_api_key()
    if not api_key:
        logger.warning("No LASTFM_API_KEY configured")
        return None

    from app.services.cache import cache_get, cache_set

    # Build cache key from method + sorted params
    param_str = "&".join(f"{k}={v}" for k, v in sorted(params.items()) if v)
    cache_key = f"lastfm:{method}:{param_str}"
    cached = await cache_get(cache_key)
    if cached is not None:
        return cached

    await _rate_limit()

    try:
        async with httpx.AsyncClient() as client:
            resp = await client.get(
                LASTFM_BASE,
                params={"method": method, "api_key": api_key, "format": "json", **params},
                timeout=10.0,
                headers={"User-Agent": "DWMB/1.0 (https://github.com/alexypracticum/DWMB)"},
            )
            if resp.status_code == 200:
                data = resp.json()
                if "error" not in data or data.get("error") == 0:
                    # Cache different TTLs by method type
                    ttl = 3600 if "getinfo" in method or "getRecentTracks" in method else 86400
                    await cache_set(cache_key, data, ttl=ttl)
                    return data
                else:
                    logger.warning("Last.fm API error %s: %s", method, data.get("message"))
            else:
                logger.warning("Last.fm HTTP %s for %s", resp.status_code, method)
    except Exception as e:
        logger.error("Last.fm request failed (%s): %s", method, e)
    return None


# ─── Public API Functions ───────────────────────────────────────


async def lastfm_status() -> Dict:
    """Check if Last.fm API is configured."""
    api_key = _get_api_key()
    return {
        "configured": bool(api_key),
        "message": "Last.fm API настроен" if api_key else "Last.fm API ключ не задан (LASTFM_API_KEY в .env)",
    }


async def get_user_info(username: str) -> Optional[Dict]:
    """Get Last.fm user profile info."""
    data = await _lastfm_request("user.getinfo", {"user": username})
    if not data or "user" not in data:
        return None
    u = data["user"]
    return {
        "username": u.get("name"),
        "realname": u.get("realname"),
        "url": u.get("url"),
        "image": _extract_image(u.get("image")),
        "playcount": int(u.get("playcount", 0)),
        "registered": u.get("registered", {}).get("unixtime"),
    }


async def get_recent_tracks(username: str, limit: int = 50, page: int = 1) -> List[Dict]:
    """Get user's recent listening history (scrobbles)."""
    data = await _lastfm_request("user.getrecenttracks", {"user": username, "limit": limit, "page": page})
    if not data or "recenttracks" not in data:
        return []
    tracks = data["recenttracks"].get("track", [])
    if isinstance(tracks, dict):
        tracks = [tracks]  # Last.fm returns single item as dict
    results = []
    for t in tracks:
        if t.get("@attr", {}).get("nowplaying"):
            continue  # Skip now-playing marker
        results.append(_parse_track(t))
    return results


async def get_top_tracks(username: str, period: str = "overall", limit: int = 20) -> List[Dict]:
    """Get user's most played tracks. period: 7day|1month|3months|6months|12months|overall"""
    data = await _lastfm_request("user.gettoptracks", {"user": username, "period": period, "limit": limit})
    if not data or "toptracks" not in data:
        return []
    tracks = data["toptracks"].get("track", [])
    results = []
    for i, t in enumerate(tracks):
        parsed = _parse_track(t)
        parsed["rank"] = i + 1
        parsed["playcount"] = int(t.get("playcount", 0))
        results.append(parsed)
    return results


async def get_top_artists(username: str, period: str = "overall", limit: int = 20) -> List[Dict]:
    """Get user's most played artists."""
    data = await _lastfm_request("user.gettopartists", {"user": username, "period": period, "limit": limit})
    if not data or "topartists" not in data:
        return []
    artists = data["topartists"].get("artist", [])
    results = []
    for i, a in enumerate(artists):
        results.append({
            "name": a.get("name"),
            "mbid": a.get("mbid"),
            "playcount": int(a.get("playcount", 0)),
            "rank": i + 1,
            "url": a.get("url"),
            "image": _extract_image(a.get("image")),
        })
    return results


async def get_top_albums(username: str, period: str = "overall", limit: int = 20) -> List[Dict]:
    """Get user's most played albums."""
    data = await _lastfm_request("user.gettopalbums", {"user": username, "period": period, "limit": limit})
    if not data or "topalbums" not in data:
        return []
    albums = data["topalbums"].get("album", [])
    results = []
    for i, a in enumerate(albums):
        artist = a.get("artist", {})
        results.append({
            "name": a.get("name"),
            "mbid": a.get("mbid"),
            "artist": artist.get("name"),
            "artist_mbid": artist.get("mbid"),
            "playcount": int(a.get("playcount", 0)),
            "rank": i + 1,
            "url": a.get("url"),
            "image": _extract_image(a.get("image")),
        })
    return results


async def get_track_info(artist: str, track: str) -> Optional[Dict]:
    """Get track details including MusicBrainz IDs."""
    data = await _lastfm_request("track.getinfo", {"artist": artist, "track": track})
    if not data or "track" not in data:
        return None
    t = data["track"]
    artist_data = t.get("artist", {})
    album_data = t.get("album", {})
    return {
        "name": t.get("name"),
        "mbid": t.get("mbid"),
        "artist": artist_data.get("name"),
        "artist_mbid": artist_data.get("mbid"),
        "album": album_data.get("title"),
        "album_mbid": album_data.get("mbid"),
        "duration": int(t.get("duration", 0)),
        "listeners": int(t.get("listeners", 0)),
        "playcount": int(t.get("playcount", 0)),
        "url": t.get("url"),
        "image": _extract_image(t.get("image")),
        "tags": [tag.get("name") for tag in t.get("toptags", {}).get("tag", [])[:5]],
        "wiki": t.get("wiki", {}).get("summary", ""),
    }


# ─── Cross-reference with MusicBrainz ──────────────────────────


async def resolve_with_musicbrainz(track_data: Dict) -> Dict:
    """Resolve a Last.fm track with MusicBrainz data.
    
    If the track has a MusicBrainz ID, fetch full details from MusicBrainz.
    Otherwise, search by artist + track name.
    """
    from app.services.external_apis import get_musicbrainz_details, search_musicbrainz

    mbid = track_data.get("mbid")
    result = {"musicbrainz": None, "source": "lastfm"}

    if mbid:
        # Try direct MBID lookup for recording
        mb_data = await get_musicbrainz_details(mbid, "recording")
        if mb_data:
            result["musicbrainz"] = mb_data
            result["source"] = "musicbrainz_mbid"
            return result

    # Fallback: search by artist + track name
    artist = track_data.get("artist", "")
    track = track_data.get("name", track_data.get("track", ""))
    if artist and track:
        query = f"{artist} {track}"
        results = await search_musicbrainz(query, "recording")
        if results:
            # Take the first result and get full details
            first = results[0]
            mb_data = await get_musicbrainz_details(first["id"], "recording")
            if mb_data:
                result["musicbrainz"] = mb_data
                result["source"] = "musicbrainz_search"
                return result

    # Also try artist lookup
    if artist:
        artist_results = await search_musicbrainz(artist, "artist")
        if artist_results:
            result["artist_mbid"] = artist_results[0].get("id")

    return result


# ─── Import to DWMB ────────────────────────────────────────────


async def import_lastfm_track(db, track_data: Dict, user_id, musicbrainz_data: Optional[Dict] = None) -> Dict:
    """Import a Last.fm track as a song entity with optional MusicBrainz cross-reference."""
    import hashlib, json
    from uuid import uuid4
    from sqlalchemy import select, func
    from app.models.entities import Entity, EntityLabel
    from app.models.kinds import EntityKind, EntityKindLabel
    from app.models.projections import EntityProjection, ProjectionState, OntologyTemplate
    from app.services.language import get_language_id

    artist = track_data.get("artist", "")
    track_name = track_data.get("name", track_data.get("track", ""))
    mbid = track_data.get("mbid", "")

    # Build entity code
    entity_code = f"lastfm_{mbid}" if mbid else f"lastfm_{_slugify(artist)}_{_slugify(track_name)}"

    # Check if already exists
    existing = await db.execute(select(Entity).where(Entity.entity_code == entity_code))
    if existing.scalar_one_or_none():
        return {"status": "exists", "entity_code": entity_code, "message": "Track already imported"}

    # Get or create song kind
    kind = (await db.execute(select(EntityKind).where(EntityKind.kind_code == "song"))).scalars().first()
    if not kind:
        kind = EntityKind(
            kind_code="song",
            parent_kind_id=None,
            description="Song/music track",
            is_abstract=False,
            sort_order=100,
            version_id=1,
        )
        db.add(kind)
        await db.flush()
        ru_lang_id = await get_language_id(db, "ru")
        db.add(EntityKindLabel(kind_id=kind.kind_id, language_id=ru_lang_id, label="Песня", description="Song/track"))

    # Version
    version_result = await db.execute(select(func.max(Entity.version_id)))
    version_id = (version_result.scalar() or 0) + 1

    # Create entity
    eid = uuid4()
    image_url = _extract_image(track_data.get("image")) if "image" in track_data else None
    entity = Entity(
        entity_id=eid,
        entity_code=entity_code,
        kind_id=kind.kind_id,
        status="active",
        image_url=image_url,
        owner_id=user_id,
        version_id=version_id,
    )
    db.add(entity)
    await db.flush()

    # Label
    ru_lang_id = await get_language_id(db, "ru")
    label = EntityLabel(
        entity_id=eid,
        language_id=ru_lang_id,
        label=f"{artist} — {track_name}",
        description=f"Last.fm: {track_data.get('playcount', 0)} plays",
        is_primary=True,
        owner_id=user_id,
        version_id=version_id,
    )
    db.add(label)

    # Projection
    tmpl = (await db.execute(
        select(OntologyTemplate).where(
            OntologyTemplate.kind_id == kind.kind_id,
            OntologyTemplate.is_active == True,
        ).limit(1)
    )).scalars().first()

    proj_id = uuid4()
    proj = EntityProjection(
        projection_id=proj_id,
        entity_id=eid,
        model_id=tmpl.model_id if tmpl else uuid4(),
        template_id=tmpl.template_id if tmpl else None,
        projection_code=entity_code,
        projection_name=f"{artist} — {track_name}",
        confidence=1.0,
        version_id=version_id,
    )
    db.add(proj)
    await db.flush()

    # State data — merge Last.fm + MusicBrainz
    state_data = {
        "lastfm_name": track_name,
        "lastfm_artist": artist,
        "lastfm_mbid": mbid,
        "lastfm_url": track_data.get("url", ""),
        "lastfm_playcount": track_data.get("playcount", 0),
        "lastfm_listeners": track_data.get("listeners", 0),
        "lastfm_duration": track_data.get("duration", 0),
        "lastfm_tags": track_data.get("tags", []),
        "lastfm_image": _extract_image(track_data.get("image")) if "image" in track_data else None,
        "source": "lastfm",
    }

    # Enrich with MusicBrainz data
    if musicbrainz_data and musicbrainz_data.get("musicbrainz"):
        mb = musicbrainz_data["musicbrainz"]
        state_data["musicbrainz_id"] = mb.get("id", "")
        state_data["musicbrainz_artist"] = mb.get("artist", "")
        state_data["musicbrainz_year"] = mb.get("year", "")
        state_data["musicbrainz_duration"] = mb.get("duration", "")
        state_data["source"] = musicbrainz_data.get("source", "lastfm")
        # Use MusicBrainz artist name if available
        if mb.get("artist"):
            label.description = f"MusicBrainz: {mb['artist']}"
            state_data["artist"] = mb["artist"]

    state_hash = hashlib.sha256(
        json.dumps(state_data, sort_keys=True, default=str).encode()
    ).hexdigest()

    db.add(ProjectionState(
        projection_id=proj_id,
        state_data=state_data,
        state_hash=state_hash,
        is_current=True,
        version_id=version_id,
    ))

    return {
        "status": "created",
        "entity_id": str(eid),
        "entity_code": entity_code,
        "title": f"{artist} — {track_name}",
    }


async def import_top_tracks(db, username: str, user_id, period: str = "overall", limit: int = 20, with_musicbrainz: bool = True) -> Dict:
    """Import user's top tracks from Last.fm as entities.
    
    Optionally cross-references each track with MusicBrainz for richer metadata.
    """
    tracks = await get_top_tracks(username, period, limit)
    if not tracks:
        return {"imported": 0, "message": "No tracks found or Last.fm API not configured"}

    imported = 0
    skipped = 0
    errors = 0
    results = []

    for track in tracks:
        try:
            # Cross-reference with MusicBrainz
            mb_data = None
            if with_musicbrainz:
                mb_data = await resolve_with_musicbrainz(track)

            result = await import_lastfm_track(db, track, user_id, mb_data)
            if result["status"] == "created":
                imported += 1
                results.append(result)
            elif result["status"] == "exists":
                skipped += 1
        except Exception as e:
            logger.error("Failed to import track %s: %s", track.get("name"), e)
            errors += 1

    return {
        "imported": imported,
        "skipped": skipped,
        "errors": errors,
        "message": f"Импортировано {imported} треков, пропущено {skipped}, ошибок {errors}",
        "tracks": results,
    }


# ─── Widget: Часто слушаю ──────────────────────────────────────


async def get_frequently_played(db, user_id, limit: int = 10) -> List[Dict]:
    """Get top frequently played tracks from the database for a user.
    
    Queries entities of kind 'song' that were imported from Last.fm,
    ordered by playcount.
    """
    from uuid import UUID
    from sqlalchemy import select
    from app.models.entities import Entity
    from app.models.kinds import EntityKind
    from app.models.projections import EntityProjection, ProjectionState

    kind = (await db.execute(
        select(EntityKind).where(EntityKind.kind_code == "song")
    )).scalars().first()
    if not kind:
        return []

    # Get all song entities with Last.fm data
    query = (
        select(Entity, ProjectionState)
        .join(EntityProjection, EntityProjection.entity_id == Entity.entity_id)
        .join(ProjectionState, ProjectionState.projection_id == EntityProjection.projection_id)
        .where(
            Entity.kind_id == kind.kind_id,
            Entity.owner_id == user_id,
            ProjectionState.is_current == True,
        )
        .order_by(ProjectionState.state_data["lastfm_playcount"].as_float().desc())
        .limit(limit)
    )

    result = await db.execute(query)
    rows = result.all()

    tracks = []
    for entity, ps in rows:
        sd = ps.state_data or {}
        tracks.append({
            "entity_id": str(entity.entity_id),
            "entity_code": entity.entity_code,
            "title": sd.get("lastfm_name", ""),
            "artist": sd.get("lastfm_artist", sd.get("artist", "")),
            "playcount": sd.get("lastfm_playcount", 0),
            "duration": sd.get("lastfm_duration", 0),
            "url": sd.get("lastfm_url", ""),
            "image": entity.image_url or sd.get("lastfm_image"),
            "tags": sd.get("lastfm_tags", []),
            "source": sd.get("source", ""),
        })
    return tracks


# ─── Helpers ────────────────────────────────────────────────────


def _parse_track(raw: Dict) -> Dict:
    """Parse a Last.fm track JSON object into a clean dict."""
    artist = raw.get("artist", {})
    album = raw.get("album", {})
    return {
        "name": raw.get("name"),
        "mbid": raw.get("mbid"),
        "artist": artist.get("#text", "") if isinstance(artist, dict) else str(artist),
        "artist_mbid": artist.get("mbid", "") if isinstance(artist, dict) else "",
        "album": album.get("#text", "") if isinstance(album, dict) else str(album),
        "album_mbid": album.get("mbid", "") if isinstance(album, dict) else "",
        "url": raw.get("url"),
        "date": raw.get("date", {}).get("#text", "") if isinstance(raw.get("date"), dict) else "",
        "image": raw.get("image"),
    }


def _extract_image(images) -> Optional[str]:
    """Extract the largest image URL from Last.fm image array."""
    if not images:
        return None
    if isinstance(images, str):
        return images
    if isinstance(images, list) and images:
        # Last.fm returns images as [{"#text": "...", "size": "small|medium|large|extralarge"}]
        # Prefer largest
        for size in ("extralarge", "large", "medium"):
            for img in images:
                if isinstance(img, dict) and img.get("size") == size:
                    url = img.get("#text", "")
                    if url:
                        return url
        # Fallback to last image
        last = images[-1]
        if isinstance(last, dict):
            return last.get("#text")
        return str(last)
    return None


def _slugify(text: str) -> str:
    """Simple slug for entity codes."""
    import re
    text = text.lower().strip()
    text = re.sub(r"[^\w\s-]", "", text)
    text = re.sub(r"[\s_]+", "_", text)
    return text[:50]
