"""
AI service for OpenAI integration.
Handles embeddings, chat, and entity parsing.
"""
import time
import json
from typing import Optional
from uuid import UUID

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import get_settings
from app.models.ai import AiConfig, AiTaskLog, AiSuggestion
from app.models.projections import ProjectionState


class AIService:
    """OpenAI API integration service."""

    def __init__(self):
        settings = get_settings()
        self.api_key = settings.AI_API_KEY
        self.model_embedding = settings.AI_MODEL_EMBEDDING
        self.model_chat = settings.AI_MODEL_CHAT
        self.base_url = "https://api.openai.com/v1"
        self.config_id = None

    async def load_config(self, db: AsyncSession):
        """Load AI configuration from database."""
        result = await db.execute(
            select(AiConfig).where(AiConfig.is_active == True).limit(1)
        )
        config = result.scalar_one_or_none()
        if config:
            if config.api_key_enc:
                self.api_key = self.decrypt_api_key(config.api_key_enc)
            self.model_embedding = config.model_embedding
            self.model_chat = config.model_chat
            self.base_url = config.api_base_url or "https://api.openai.com/v1"
            self.config_id = config.config_id
            return config
        return None

    def encrypt_api_key(self, key: str) -> bytes:
        """Encrypt API key (placeholder - store as bytes)."""
        return key.encode()

    def decrypt_api_key(self, encrypted: bytes) -> str:
        """Decrypt API key."""
        return encrypted.decode() if encrypted else ""

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

    async def _log_task(
        self,
        db: AsyncSession,
        task_type: str,
        model_used: str = None,
        input_tokens: int = 0,
        output_tokens: int = 0,
        duration_ms: int = 0,
        entity_id: UUID = None,
        status: str = "success",
        error_message: str = None,
        payload: dict = None,
    ):
        """Log an AI task to the database."""
        cost_usd = 0.0
        if task_type == "embedding":
            cost_usd = input_tokens * 0.00000002  # text-embedding-3-small pricing
        elif task_type == "chat":
            cost_usd = input_tokens * 0.00000015 + output_tokens * 0.0000006  # gpt-4o-mini pricing

        log_entry = AiTaskLog(
            task_type=task_type,
            model_used=model_used,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cost_usd=cost_usd,
            duration_ms=duration_ms,
            entity_id=entity_id,
            status=status,
            error_message=error_message,
            payload=payload,
        )
        db.add(log_entry)
        await db.flush()

    async def get_embedding(self, text: str, db: AsyncSession = None) -> Optional[list[float]]:
        """Generate embedding vector for text."""
        if not self.api_key:
            return None

        start = time.time()
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/embeddings",
                    headers=self._headers(),
                    json={"input": text, "model": self.model_embedding},
                    timeout=30.0,
                )
                duration_ms = int((time.time() - start) * 1000)

                if response.status_code == 200:
                    data = response.json()
                    embedding = data["data"][0]["embedding"]
                    usage = data.get("usage", {})

                    if db:
                        await self._log_task(
                            db, "embedding", self.model_embedding,
                            input_tokens=usage.get("prompt_tokens", 0),
                            duration_ms=duration_ms,
                        )
                    return embedding
                else:
                    if db:
                        await self._log_task(
                            db, "embedding", self.model_embedding,
                            duration_ms=duration_ms, status="error",
                            error_message=f"HTTP {response.status_code}",
                        )
        except Exception as e:
            duration_ms = int((time.time() - start) * 1000)
            if db:
                await self._log_task(
                    db, "embedding", self.model_embedding,
                    duration_ms=duration_ms, status="error",
                    error_message=str(e),
                )
        return None

    async def chat_completion(
        self, messages: list[dict], temperature: float = 0.7,
        db: AsyncSession = None
    ) -> Optional[str]:
        """Get chat completion from OpenAI."""
        if not self.api_key:
            return None

        start = time.time()
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/chat/completions",
                    headers=self._headers(),
                    json={
                        "model": self.model_chat,
                        "messages": messages,
                        "temperature": temperature,
                    },
                    timeout=60.0,
                )
                duration_ms = int((time.time() - start) * 1000)

                if response.status_code == 200:
                    data = response.json()
                    content = data["choices"][0]["message"]["content"]
                    usage = data.get("usage", {})

                    if db:
                        await self._log_task(
                            db, "chat", self.model_chat,
                            input_tokens=usage.get("prompt_tokens", 0),
                            output_tokens=usage.get("completion_tokens", 0),
                            duration_ms=duration_ms,
                        )
                    return content
                else:
                    if db:
                        await self._log_task(
                            db, "chat", self.model_chat,
                            duration_ms=duration_ms, status="error",
                            error_message=f"HTTP {response.status_code}",
                        )
        except Exception as e:
            duration_ms = int((time.time() - start) * 1000)
            if db:
                await self._log_task(
                    db, "chat", self.model_chat,
                    duration_ms=duration_ms, status="error",
                    error_message=str(e),
                )
        return None

    async def parse_entity_text(
        self, text: str, entity_type: str = "movie", db: AsyncSession = None
    ) -> Optional[dict]:
        """
        Use AI to parse free text into structured entity data.
        """
        prompt = f"""Parse the following text into structured data for a {entity_type}.
Return a JSON object with fields like title, description, year, genre, rating, etc.
Only return valid JSON, no explanation.

Text: {text}"""

        result = await self.chat_completion(
            [{"role": "user", "content": prompt}], temperature=0.3, db=db
        )
        if result:
            try:
                return json.loads(result)
            except json.JSONDecodeError:
                return None
        return None

    async def update_embeddings_batch(
        self,
        db: AsyncSession,
        entity_id: Optional[UUID] = None,
        limit: int = 100,
    ) -> int:
        """
        Update embeddings for projection states in batch.
        Returns count of updated states.
        """
        query = select(ProjectionState).where(
            ProjectionState.embedding.is_(None)
        )
        if entity_id:
            query = query.join(ProjectionState.entity).where(
                ProjectionState.entity_id == entity_id
            )
        query = query.limit(limit)

        result = await db.execute(query)
        states = result.scalars().all()

        updated = 0
        for state in states:
            text = self._extract_text_for_embedding(state.state_data)
            embedding = await self.get_embedding(text, db)
            if embedding:
                state.embedding = embedding
                updated += 1

        await db.commit()
        return updated

    def _extract_text_for_embedding(self, state_data: dict) -> str:
        """Extract searchable text from projection state data."""
        parts = []
        for key in ["title", "description", "name", "label"]:
            if key in state_data:
                parts.append(str(state_data[key]))
        return " ".join(parts) if parts else str(state_data)

    async def hybrid_search(
        self,
        db: AsyncSession,
        query: str,
        kind_filter: list[str] = None,
        year_range: tuple[int, int] = None,
        limit: int = 20,
    ) -> list[dict]:
        """
        Hybrid search: vector similarity + SQL filters.
        Returns list of entities with scores.
        """
        from sqlalchemy import text

        sql_parts = ["""
            SELECT
                e.entity_id,
                e.entity_code,
                el.label,
                el.description,
                ek.kind_code,
                ps.state_data,
                1 - (ps.embedding <=> :query_embedding::vector) as similarity
            FROM meta.entity e
            JOIN meta.entity_label el ON el.entity_id = e.entity_id AND el.language_id = (SELECT language_id FROM meta.language WHERE code = 'ru' LIMIT 1) AND el.is_primary = true
            JOIN meta.entity_kind ek ON ek.kind_id = e.kind_id
            JOIN meta.entity_projection ep ON ep.entity_id = e.entity_id
            JOIN meta.projection_state ps ON ps.projection_id = ep.projection_id AND ps.is_current = true
            WHERE ps.embedding IS NOT NULL
        """]
        params = {}

        if kind_filter:
            sql_parts.append("AND ek.kind_code = ANY(:kind_filter)")
            params["kind_filter"] = kind_filter

        if year_range:
            sql_parts.append("AND (ps.state_data->>'year')::int BETWEEN :year_min AND :year_max")
            params["year_min"] = year_range[0]
            params["year_max"] = year_range[1]

        sql_parts.append("ORDER BY ps.embedding <=> :query_embedding::vector")
        sql_parts.append("LIMIT :limit")

        query_embedding = await self.get_embedding(query, db)
        if not query_embedding:
            return []

        params["query_embedding"] = str(query_embedding)
        params["limit"] = limit

        sql = text(" ".join(sql_parts))
        result = await db.execute(sql, params)

        matches = []
        for row in result:
            matches.append({
                "entity_id": str(row.entity_id),
                "entity_code": row.entity_code,
                "label": row.label,
                "description": row.description,
                "kind": row.kind_code,
                "state_data": row.state_data,
                "similarity": float(row.similarity),
            })

        return matches

    async def find_similar(
        self,
        db: AsyncSession,
        entity_id: UUID,
        limit: int = 5,
    ) -> list[dict]:
        """Find similar entities using embedding cosine distance."""
        from sqlalchemy import text

        sql = text("""
            SELECT
                e.entity_id,
                e.entity_code,
                el.label,
                ek.kind_code,
                1 - (ps.embedding <=> source.embedding) as similarity
            FROM meta.projection_state source
            JOIN meta.entity_projection ep ON ep.projection_id = source.projection_id
            JOIN meta.entity e ON e.entity_id = ep.entity_id
            JOIN meta.entity_label el ON el.entity_id = e.entity_id AND el.language_id = (SELECT language_id FROM meta.language WHERE code = 'ru' LIMIT 1) AND el.is_primary = true
            JOIN meta.entity_kind ek ON ek.kind_id = e.kind_id
            JOIN meta.projection_state ps ON ps.projection_id = (
                SELECT ep2.projection_id
                FROM meta.entity_projection ep2
                WHERE ep2.entity_id = e.entity_id
                LIMIT 1
            )
            WHERE source.projection_id = (
                SELECT ep3.projection_id
                FROM meta.entity_projection ep3
                WHERE ep3.entity_id = :entity_id
                LIMIT 1
            )
            AND e.entity_id != :entity_id
            AND ps.embedding IS NOT NULL
            AND source.embedding IS NOT NULL
            ORDER BY ps.embedding <=> source.embedding
            LIMIT :limit
        """)

        result = await db.execute(sql, {
            "entity_id": str(entity_id),
            "limit": limit,
        })

        similar = []
        for row in result:
            similar.append({
                "entity_id": str(row.entity_id),
                "entity_code": row.entity_code,
                "label": row.label,
                "kind": row.kind_code,
                "similarity": float(row.similarity),
            })

        return similar

    async def suggest_fields(
        self, db: AsyncSession, entity_id: UUID, state_data: dict
    ) -> list[dict]:
        """Use AI to suggest additional fields for an entity."""
        prompt = f"""Given this entity data:
{state_data}

Suggest 3-5 additional fields that could enrich this entity.
Return as JSON array of objects with "key" and "value" fields.
Only return valid JSON, no explanation."""

        result = await self.chat_completion(
            [{"role": "user", "content": prompt}], temperature=0.5, db=db
        )
        if result:
            try:
                suggestions = json.loads(result)
                # Store in database
                for s in suggestions:
                    ai_suggestion = AiSuggestion(
                        entity_id=entity_id,
                        suggestion_type="auto_field",
                        field_key=s.get("key"),
                        suggested_value=s.get("value"),
                        confidence=0.7,
                    )
                    db.add(ai_suggestion)
                await db.commit()
                return suggestions
            except json.JSONDecodeError:
                return []
        return []


# Lazy initialization
_ai_instance = None

def get_ai_service():
    """Get or create AIService instance (lazy init)."""
    global _ai_instance
    if _ai_instance is None:
        _ai_instance = AIService()
    return _ai_instance


# Backward compatibility - lazy proxy
class _AIProxy:
    def __getattr__(self, name):
        return getattr(get_ai_service(), name)

ai_service = _AIProxy()
