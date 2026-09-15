from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.servico import Servico
from schemas.servico import ServicoCreate


# Cria um novo serviço
async def create_servico(
    db: AsyncSession,
    servico_data: ServicoCreate,
):
    servico = Servico(
        nome=servico_data.nome,
        descricao=servico_data.descricao,
        duracao=servico_data.duracao,
        preco=servico_data.preco,
    )

    db.add(servico)
    await db.commit()
    await db.refresh(servico)

    return servico


# Busca todos os serviços ativos
async def get_servicos(
    db: AsyncSession,
):
    result = await db.execute(
        select(Servico).where(
            Servico.ativo == True
        )
    )

    return result.scalars().all()


# Busca um serviço pelo ID
async def get_servico(
    db: AsyncSession,
    servico_id: int,
):
    result = await db.execute(
        select(Servico).where(
            Servico.id == servico_id
        )
    )

    return result.scalar_one_or_none()