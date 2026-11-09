from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from auth.dependencies import get_current_user_id
from db.session import get_db
from crud.perfil import atualizar_perfil, get_perfil_completo
from schemas.perfil import PerfilResponse, PerfilUpdate
from services.supabase_storage import upload_imagem

router = APIRouter(
    prefix="/perfil",
    tags=["Perfil"],
)


@router.get("/", response_model=PerfilResponse)
async def buscar_perfil(
    usuario_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    return await get_perfil_completo(db, usuario_id)


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


@router.post("/foto")
async def upload_foto(
    foto: UploadFile = File(...),
    usuario_id: int = Depends(get_current_user_id),
):
    if not foto.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="O arquivo deve ser uma imagem.")

    conteudo = await foto.read()
    
    if len(conteudo) > 5 * 1024 * 1024:
        raise HTTPException(status_code=413, detail="Imagem muito grande (máx 5MB).")

    url_publica = await upload_imagem(usuario_id, conteudo, foto.content_type)
    
    return {"imagem_url": url_publica}