from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from crud.servico import get_servicos
from db.session import get_db
from schemas.servico import ServicoResponse


# Rotas relacionadas aos serviços
router = APIRouter(
    prefix="/servicos",
    tags=["Serviços"],
)


# Retorna os serviços ativos
@router.get(
    "/",
    response_model=list[ServicoResponse],
)
async def listar_servicos(
    db: AsyncSession = Depends(get_db),
):
    return await get_servicos(db)