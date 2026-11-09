from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import get_current_user_id
from db.session import get_db
from crud.perfil import get_perfil, atualizar_perfil
from schemas.perfil import PerfilUpdate, PerfilResponse

router = APIRouter(
    prefix="/perfil",
    tags=["Perfil"],
)


@router.get("/", response_model=PerfilResponse)
async def buscar_perfil(
    usuario_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    perfil = await get_perfil(db, usuario_id)

    if not perfil:
        perfil = await atualizar_perfil(db, usuario_id, {})

    return perfil


@router.put("/", response_model=PerfilResponse)
async def atualizar(
    dados: PerfilUpdate,
    usuario_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    return await atualizar_perfil(
        db,
        usuario_id,
        dados.model_dump(exclude_unset=True),
    )