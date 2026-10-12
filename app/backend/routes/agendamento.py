
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import get_current_user_id
from crud.agendamento import (
    criar_agendamento,
    get_horarios_disponiveis,
)
from db.session import get_db
from schemas.agendamento import (
    AgendamentoCreate,
    AgendamentoResponse,
)


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


@router.post(
    "/",
    response_model=AgendamentoResponse,
    status_code=201,
)
async def registrar_agendamento(
    dados: AgendamentoCreate,
    usuario_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    return await criar_agendamento(
        db=db,
        usuario_id=usuario_id,
        servico_id=dados.servico_id,
        profissional_id=dados.profissional_id,
        data_agendamento=dados.data_agendamento,
        horario_inicio=dados.horario_inicio,
    )