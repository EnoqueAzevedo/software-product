import os
import uuid
import httpx
from fastapi import HTTPException

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
SUPABASE_BUCKET = os.getenv("SUPABASE_BUCKET", "perfil")


async def upload_imagem(usuario_id: int, conteudo: bytes, content_type: str) -> str:
    # Garante extensão correta (ex: image/jpeg -> jpeg)
    extensao = content_type.split("/")[-1]
    nome_arquivo = f"perfil_{usuario_id}_{uuid.uuid4().hex}.{extensao}"

    url = f"{SUPABASE_URL}/storage/v1/object/{SUPABASE_BUCKET}/{nome_arquivo}"

    headers = {
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": content_type,
        "x-upsert": "true",
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(url, headers=headers, content=conteudo)

    if resp.status_code not in (200, 201):
        raise HTTPException(
            status_code=500,
            detail=f"Erro ao subir imagem no Supabase: {resp.text}"
        )

    # Retorna a URL pública
    return (
        f"{SUPABASE_URL}/storage/v1/object/public/"
        f"{SUPABASE_BUCKET}/{nome_arquivo}"
    )