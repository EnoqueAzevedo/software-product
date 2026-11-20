
import os

import httpx
from dotenv import load_dotenv

load_dotenv()

BREVO_API_KEY = os.getenv("BREVO_API_KEY")
BREVO_FROM_EMAIL = os.getenv("BREVO_FROM_EMAIL")
BREVO_FROM_NAME = os.getenv(
    "BREVO_FROM_NAME",
    "Agenda Pulcro"
)

if not BREVO_API_KEY:
    raise ValueError(
        "BREVO_API_KEY não encontrada no .env"
    )

if not BREVO_FROM_EMAIL:
    raise ValueError(
        "BREVO_FROM_EMAIL não encontrada no .env"
    )


async def enviar_email(
    destinatario: str,
    assunto: str,
    mensagem: str,
):
    url = "https://api.brevo.com/v3/smtp/email"

    headers = {
        "api-key": BREVO_API_KEY,
        "Content-Type": "application/json",
        "Accept": "application/json",
    }

    payload = {
        "sender": {
            "name": BREVO_FROM_NAME,
            "email": BREVO_FROM_EMAIL,
        },
        "to": [
            {
                "email": destinatario,
            }
        ],
        "subject": assunto,
        "textContent": mensagem,
    }

    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.post(
            url,
            headers=headers,
            json=payload,
        )

    if response.status_code != 201:
        raise RuntimeError(
            f"Erro ao enviar e-mail pelo Brevo: "
            f"{response.status_code} - {response.text}"
        )
