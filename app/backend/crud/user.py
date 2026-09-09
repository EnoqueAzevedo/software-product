from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pwdlib import PasswordHash

from models.user import User
from schemas.user import UserCreate, UserLogin

password_hash = PasswordHash.recommended()

async def create_user(db: AsyncSession,user_data: UserCreate):
    user = User(
        nome=user_data.nome,
        email=user_data.email,
        senha=password_hash.hash(user_data.senha),
    )

    db.add(user)

    await db.commit()
    await db.refresh(user)

    return user


async def authenticate_user(
    db: AsyncSession,
    user_data: UserLogin,
):
    result = await db.execute(
        select(User).where(User.email == user_data.email)
    )

    user = result.scalar_one_or_none()

    if not user:
        return None

    if not password_hash.verify(user_data.senha, user.senha):
        return None

    return user


async def get_user(
    db: AsyncSession,
    user_id: int,
):
    result = await db.execute(
        select(User).where(User.id == user_id)
    )

    return result.scalar_one_or_none()


async def get_users(
    db: AsyncSession,
):
    result = await db.execute(
        select(User)
    )

    return result.scalars().all()


async def delete_user(
    db: AsyncSession,
    user_id: int,
):
    user = await get_user(db, user_id)

    if not user:
        return None

    await db.delete(user)
    await db.commit()

    return user