from datetime import datetime, timedelta, timezone
import secrets

from pwdlib import PasswordHash
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from models.cadastro_provisorio import CadastroProvisorio
from models.user import User
from schemas.cadastro_provisorio import CadastroProvisorioCreate


# Gerenciador usado para proteger as senhas
password_hash = PasswordHash.recommended()


# Remove cadastros provisórios que já expiraram
async def limpar_cadastros_expirados(
    db: AsyncSession,
):
    agora = datetime.now(timezone.utc)

    await db.execute(
        delete(CadastroProvisorio).where(
            CadastroProvisorio.expira_em < agora
        )
    )

    await db.commit()


# Cria um cadastro provisório
async def create_cadastro_provisorio(
    db: AsyncSession,
    cadastro_data: CadastroProvisorioCreate,
):
    # Confere se as duas senhas são iguais
    if cadastro_data.senha != cadastro_data.confirmacao_senha:
        return None, "As senhas não coincidem"

    # Verifica se o e-mail já pertence a uma conta definitiva
    result = await db.execute(
        select(User).where(User.email == cadastro_data.email)
    )

    usuario = result.scalar_one_or_none()

    if usuario:
        return None, "Este e-mail já está cadastrado"

    # Verifica se o e-mail já possui cadastro provisório
    result = await db.execute(
        select(CadastroProvisorio).where(
            CadastroProvisorio.email == cadastro_data.email
        )
    )

    cadastro_existente = result.scalar_one_or_none()

    if cadastro_existente:
        return None, "Este e-mail já possui um cadastro pendente"

    # Gera um token exclusivo para confirmação
    token = secrets.token_urlsafe(32)

    # Define validade de 24 horas
    expira_em = datetime.now(timezone.utc) + timedelta(hours=24)

    # Protege a senha antes de salvar
    senha_hash = password_hash.hash(cadastro_data.senha)

    # Cria o registro provisório
    cadastro = CadastroProvisorio(
        token_confirmacao=token,
        nome=cadastro_data.nome,
        email=cadastro_data.email,
        senha=senha_hash,
        expira_em=expira_em,
        confirmado=False,
    )

    db.add(cadastro)
    await db.commit()

    return cadastro, None


# Confirma um cadastro provisório e cria o usuário definitivo
async def confirmar_cadastro_provisorio(
    db: AsyncSession,
    token: str,
):
    # Procura o cadastro pelo token
    result = await db.execute(
        select(CadastroProvisorio).where(
            CadastroProvisorio.token_confirmacao == token
        )
    )

    cadastro = result.scalar_one_or_none()

    if not cadastro:
        return None, "Token de confirmação inválido"

    # Verifica se o token ainda está dentro do prazo
    agora = datetime.now(timezone.utc)

    if cadastro.expira_em < agora:
        await db.delete(cadastro)
        await db.commit()
        return None, "O token de confirmação expirou"

    # Verifica se o cadastro já foi confirmado
    if cadastro.confirmado:
        return None, "Este cadastro já foi confirmado"

    # Verifica se o e-mail já pertence a um usuário
    result = await db.execute(
        select(User).where(User.email == cadastro.email)
    )

    usuario_existente = result.scalar_one_or_none()

    if usuario_existente:
        return None, "Este e-mail já está cadastrado"

    # Cria o usuário definitivo usando a senha já protegida
    usuario = User(
        nome=cadastro.nome,
        email=cadastro.email,
        senha=cadastro.senha,
    )

    db.add(usuario)

    # Marca o cadastro como confirmado
    cadastro.confirmado = True

    # Remove o cadastro provisório após a conversão
    await db.delete(cadastro)

    await db.commit()
    await db.refresh(usuario)

    return usuario, None