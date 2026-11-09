from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.perfil import Perfil


async def get_perfil(
    db: AsyncSession,
    usuario_id: int,
):
    result = await db.execute(
        select(Perfil).where(Perfil.usuario_id == usuario_id)
    )

    return result.scalar_one_or_none()


async def atualizar_perfil(
    db: AsyncSession,
    usuario_id: int,
    dados: dict,
):
    perfil = await get_perfil(db, usuario_id)

    if not perfil:
        perfil = Perfil(usuario_id=usuario_id)
        db.add(perfil)

    for campo, valor in dados.items():
        setattr(perfil, campo, valor)

    await db.commit()
    await db.refresh(perfil)

    return perfil