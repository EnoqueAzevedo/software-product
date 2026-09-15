from pydantic import BaseModel, EmailStr


# Dados recebidos para iniciar um cadastro
class CadastroProvisorioCreate(BaseModel):
    nome: str
    email: EmailStr
    senha: str
    confirmacao_senha: str


# Resposta devolvida após criar o cadastro provisório
class CadastroProvisorioResponse(BaseModel):
    mensagem: str
    email: EmailStr