import os

from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase


load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL não foi encontrada no arquivo .env")


# Engine assíncrono
engine = create_async_engine(
    DATABASE_URL,
    echo=True,
)


# Fábrica de sessões
SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


# Classe base dos nossos models
class Base(DeclarativeBase):
    pass


# Dependency usada pelo FastAPI
async def get_db():
    async with SessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()


# Teste da conexão
async def test_connection():
    async with engine.begin() as connection:
        print("Conexão com PostgreSQL bem-sucedida!")
