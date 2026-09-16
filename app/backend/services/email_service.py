import os

import httpx
from dotenv import load_dotenv

load_dotenv()

SENDGRID_API_KEY = os.getenv("SENDGRID_API_KEY")
SENDGRID_FROM_EMAIL = os.getenv("SENDGRID_FROM_EMAIL")


# Confere se as configurações do SendGrid existem
if not SENDGRID_API_KEY:
    raise ValueError(
        "SENDGRID_API_KEY não encontrada no .env"
    )

if not SENDGRID_FROM_EMAIL:
    raise ValueError(
        "SENDGRID_FROM_EMAIL não encontrada no .env"
    )


# Envia e-mail usando a API HTTPS do SendGrid
async def enviar_email(
    destinatario: str,
    assunto: str,
    mensagem: str,
):
    url = "https://api.sendgrid.com/v3/mail/send"

    headers = {
        "Authorization": f"Bearer {SENDGRID_API_KEY}",
        "Content-Type": "application/json",
    }

    payload = {
        "personalizations": [
            {
                "to": [
                    {
                        "email": destinatario,
                    }
                ]
            }
        ],
        "from": {
            "email": SENDGRID_FROM_EMAIL,
            "name": "Agenda Pulcro",
        },
        "subject": assunto,
        "content": [
            {
                "type": "text/plain",
                "value": mensagem,
            }
        ],
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.post(
            url,
            headers=headers,
            json=payload,
        )

    # SendGrid retorna 202 quando o e-mail foi aceito
    if response.status_code != 202:
        raise RuntimeError(
            f"Erro ao enviar e-mail pelo SendGrid: "
            f"{response.status_code} - {response.text}"
        )
