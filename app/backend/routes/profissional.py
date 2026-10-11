from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from crud.profissional import get_profissionais_por_servico
from db.session import get_db
from schemas.profissional import ProfissionalResponse


router = APIRouter(
    prefix="/profissionais",
    tags=["Profissionais"],
)


@router.get(
    "/servico/{servico_id}",
    response_model=list[ProfissionalResponse],
)
async def listar_profissionais_por_servico(
    servico_id: int,
    db: AsyncSession = Depends(get_db),
):
    return await get_profissionais_por_servico(
        db=db,
        servico_id=servico_id,
    )

