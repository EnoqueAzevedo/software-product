from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.perfil import Perfil
from models.usuario import Usuario
from schemas.perfil import PerfilResponse


async def get_perfil(db: AsyncSession, usuario_id: int):
    result = await db.execute(
        select(Perfil).where(Perfil.usuario_id == usuario_id)
    )
    return result.scalar_one_or_none()


async def get_usuario(db: AsyncSession, usuario_id: int):
    result = await db.execute(
        select(Usuario).where(Usuario.id == usuario_id)
    )
    return result.scalar_one_or_none()


async def get_perfil_completo(db: AsyncSession, usuario_id: int):
    perfil = await get_perfil(db, usuario_id)
    usuario = await get_usuario(db, usuario_id)

    # Se não existir perfil no banco, retorna um "esqueleto" para o front
    if not perfil:
        perfil = Perfil(usuario_id=usuario_id)
        db.add(perfil)
        await db.commit()
        await db.refresh(perfil)

    return PerfilResponse(
        id=perfil.id,
        usuario_id=perfil.usuario_id,
        nome=usuario.nome if usuario else "",
        telefone=perfil.telefone,
        genero=perfil.genero,
        data_nascimento=perfil.data_nascimento,
        imagem_url=perfil.imagem_url,
    )


async def atualizar_perfil(db: AsyncSession, usuario_id: int, dados: dict):
    # Separa o nome dos outros dados
    nome = dados.pop("nome", None)

    # Atualiza o Perfil
    perfil = await get_perfil(db, usuario_id)
    if not perfil:
        perfil = Perfil(usuario_id=usuario_id)
        db.add(perfil)

    for campo, valor in dados.items():
        setattr(perfil, campo, valor)

    # Atualiza o Nome na tabela Usuario
    if nome is not None:
        usuario = await get_usuario(db, usuario_id)
        if usuario:
            usuario.nome = nome

    await db.commit()
    await db.refresh(perfil)

    return await get_perfil_completo(db, usuario_id)