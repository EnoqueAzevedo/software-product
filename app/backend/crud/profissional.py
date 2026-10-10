from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.profissionais import Profissional
from models.especialista_servico import EspecialistaServico

async def get_profissionais_por_servico(
    db: AsyncSession,
    servico_id: int,
):
    result = await db.execute(
        select(Profissional)
        .join(
            EspecialistaServico,
            Profissional.id
            == EspecialistaServico.profissional_id,
        )
        .where(
            EspecialistaServico.servico_id == servico_id
        )
    )

    return result.scalars().all()

async def get_profissionais(db: AsyncSession):
    result = await db.execute(
        select(Profissional)
    )

    return result.scalars().all()