from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import HTMLResponse
from sqlalchemy.ext.asyncio import AsyncSession

from crud.cadastro_provisorio import (
    create_cadastro_provisorio,
    confirmar_cadastro_provisorio,
)
from db.session import get_db
from schemas.cadastro_provisorio import (
    CadastroProvisorioCreate,
    CadastroProvisorioResponse,
)
from services.email_service import enviar_email


router = APIRouter(
    prefix="/auth",
    tags=["Authentication"],
)


# Inicia um novo cadastro provisório
@router.post(
    "/register",
    response_model=CadastroProvisorioResponse,
)
async def register(
    cadastro_data: CadastroProvisorioCreate,
    db: AsyncSession = Depends(get_db),
):
    cadastro, erro = await create_cadastro_provisorio(
        db,
        cadastro_data,
    )

    if erro:
        raise HTTPException(
            status_code=400,
            detail=erro,
        )

    # Monta o link de confirmação enviado por e-mail
    link_confirmacao = (
        "http://127.0.0.1:8000/auth/confirm/"
        f"{cadastro.token_confirmacao}"
    )

    # Envia o e-mail de confirmação
    await enviar_email(
        destinatario=cadastro.email,
        assunto="Confirme seu cadastro no Agenda Pulcro",
        mensagem=(
            f"Olá, {cadastro.nome}!\n\n"
            "Seu cadastro no Agenda Pulcro foi criado.\n\n"
            "Para confirmar sua conta, acesse o link abaixo:\n\n"
            f"{link_confirmacao}\n\n"
            "Este link é válido por 24 horas.\n\n"
            "Se você não realizou este cadastro, ignore este e-mail."
        ),
    )

    return CadastroProvisorioResponse(
        mensagem=(
            "Cadastro provisório criado. "
            "Verifique seu e-mail para confirmar a conta."
        ),
        email=cadastro.email,
    )


# Confirma o cadastro quando o usuário acessa o link do e-mail
@router.get(
    "/confirm/{token}",
    response_class=HTMLResponse,
)
async def confirm(
    token: str,
    db: AsyncSession = Depends(get_db),
):
    usuario, erro = await confirmar_cadastro_provisorio(
        db,
        token,
    )

    if erro:
        return HTMLResponse(
            content=f"""
            <!DOCTYPE html>
            <html lang="pt-BR">
            <head>
                <meta charset="UTF-8">
                <title>Agenda Pulcro - Confirmação</title>
            </head>
            <body>
                <h1>Não foi possível confirmar</h1>
                <p>{erro}</p>
            </body>
            </html>
            """,
            status_code=400,
        )

    return HTMLResponse(
        content="""
        <!DOCTYPE html>
        <html lang="pt-BR">
        <head>
            <meta charset="UTF-8">
            <title>Agenda Pulcro - Conta confirmada</title>
        </head>
        <body>
            <h1>Conta confirmada com sucesso!</h1>
            <p>
                Seu e-mail foi confirmado e sua conta no
                Agenda Pulcro está ativa.
            </p>
            <p>
                Agora você pode voltar para o aplicativo e fazer login.
            </p>
        </body>
        </html>
        """,
        status_code=200,
    )