from pydantic import BaseModel, ConfigDict, Field


class ProfissionalResponse(BaseModel):
    id: int
    nome: str = Field(validation_alias="nome_esp")
    especialidade: str | None
    foto_url: str | None = Field(validation_alias="foto")

    model_config = ConfigDict(from_attributes=True)

