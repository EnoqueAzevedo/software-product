
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from crud.agendamento import get_horarios_disponiveis
from db.session import get_db


router = APIRouter(
    prefix="/agendamentos",
    tags=["Agendamentos"],
)


@router.get("/horarios")
async def listar_horarios_disponiveis(
    servico_id: int = Query(..., gt=0),
    profissional_id: int = Query(..., gt=0),
    data_agendamento: date = Query(..., alias="data"),
    db: AsyncSession = Depends(get_db),
):
    return await get_horarios_disponiveis(
        db=db,
        servico_id=servico_id,
        profissional_id=profissional_id,
        data_agendamento=data_agendamento,
    )