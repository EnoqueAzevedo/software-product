import os

import resend
from dotenv import load_dotenv

load_dotenv()

RESEND_API_KEY = os.getenv("RESEND_API_KEY")

if not RESEND_API_KEY:
    raise ValueError("RESEND_API_KEY não encontrada no .env")

resend.api_key = RESEND_API_KEY


# Envia e-mail usando a API HTTPS do Resend
async def enviar_email(
    destinatario: str,
    assunto: str,
    mensagem: str,
):
    params = {
        "from": "Agenda Pulcro <onboarding@resend.dev>",
        "to": [destinatario],
        "subject": assunto,
        "text": mensagem,
    }

    await resend.Emails.send_async(params)

