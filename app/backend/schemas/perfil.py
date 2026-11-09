from datetime import date

from pydantic import BaseModel, ConfigDict


class PerfilUpdate(BaseModel):
    telefone: str | None = None
    genero: str | None = None
    data_nascimento: date | None = None
    imagem_url: str | None = None


class PerfilResponse(BaseModel):
    id: int
    usuario_id: int
    telefone: str | None
    genero: str | None
    data_nascimento: date | None
    imagem_url: str | None

    model_config = ConfigDict(
        from_attributes=True
    )