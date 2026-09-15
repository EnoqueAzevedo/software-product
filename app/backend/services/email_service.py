import os
from email.message import EmailMessage

from aiosmtplib import send
from dotenv import load_dotenv


# Carrega as configurações do arquivo .env
load_dotenv()

MAIL_USERNAME = os.getenv("MAIL_USERNAME")
MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
MAIL_FROM = os.getenv("MAIL_FROM")
MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
MAIL_PORT = int(os.getenv("MAIL_PORT", "587"))


# Envia um e-mail usando o Gmail
async def enviar_email(
    destinatario: str,
    assunto: str,
    mensagem: str,
):
    email = EmailMessage()

    email["From"] = MAIL_FROM
    email["To"] = destinatario
    email["Subject"] = assunto

    email.set_content(mensagem)

    await send(
        email,
        hostname=MAIL_SERVER,
        port=MAIL_PORT,
        start_tls=True,
        username=MAIL_USERNAME,
        password=MAIL_PASSWORD,
    )