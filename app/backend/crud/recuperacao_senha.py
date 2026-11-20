import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from sqlalchemy import select, update, delete
from crud.user import get_user, password_hash
from models.user import User


from models.recuperacao_senha import RecuperacaoSenha


def gerar_token_recuperacao() -> tuple[str, str]:
    token = secrets.token_urlsafe(32)

    token_hash = hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()

    return token, token_hash


async def criar_token_recuperacao(db, usuario_id: int):
    # Remove tokens anteriores
    await db.execute(
        delete(RecuperacaoSenha).where(
            RecuperacaoSenha.usuario_id == usuario_id
        )
    )

    token, token_hash = gerar_token_recuperacao()

    recuperacao = RecuperacaoSenha(
        usuario_id=usuario_id,
        token_hash=token_hash,
        expira_em=datetime.now(timezone.utc) + timedelta(minutes=30),
        utilizado=False
    )

    db.add(recuperacao)
    await db.flush()

    return token


async def redefinir_senha(db, token: str, nova_senha: str):
    token_hash = hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()

    agora = datetime.now(timezone.utc)

    # Bloqueia o registro durante a validação
    result = await db.execute(
        select(RecuperacaoSenha)
        .where(
            RecuperacaoSenha.token_hash == token_hash,
            RecuperacaoSenha.utilizado.is_(False),
            RecuperacaoSenha.expira_em > agora
        )
        .with_for_update()
    )

    recuperacao = result.scalar_one_or_none()

    if not recuperacao:
        return False

    usuario = await get_user(db, recuperacao.usuario_id)

    if not usuario:
        return False

    # Atualiza a senha usando Argon2
    usuario.senha = password_hash.hash(nova_senha)

    # Invalida o token
    recuperacao.utilizado = True

    # Remove outros tokens do mesmo usuário
    await db.execute(
        delete(RecuperacaoSenha).where(
            RecuperacaoSenha.usuario_id == usuario.id,
            RecuperacaoSenha.id != recuperacao.id
        )
    )

    await db.flush()

    return True
