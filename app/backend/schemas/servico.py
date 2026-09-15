from pydantic import BaseModel, ConfigDict


# Dados usados para criar um serviço
class ServicoCreate(BaseModel):
    nome: str
    descricao: str | None = None
    duracao: int
    preco: float
    imagem_url: str | None = None


# Dados enviados pelo backend
class ServicoResponse(BaseModel):
    id: int
    nome: str
    descricao: str | None
    duracao: int
    preco: float
    ativo: bool
    imagem_url: str | None

    model_config = ConfigDict(from_attributes=True)