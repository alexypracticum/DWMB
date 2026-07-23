from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase
from app.config import get_settings

settings = get_settings()
import os
# Allow override for testing
test_db_url = os.getenv("TEST_DATABASE_URL")
db_url = test_db_url if test_db_url else settings.DATABASE_URL
engine = create_async_engine(db_url, echo=False)
async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


class Base(DeclarativeBase):
    pass


async def get_db():
    async with async_session() as session:
        try:
            # Set RLS session variable
            from app.middleware.rls import get_current_user_id
            user_id = get_current_user_id()
            if user_id:
                from sqlalchemy import text
                await session.execute(text(f"SET LOCAL app.current_user_id = '{user_id}'"))
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
