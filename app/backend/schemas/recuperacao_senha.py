from pydantic import BaseModel, EmailStr, Field, model_validator


class SolicitarRecuperacao(BaseModel):
    email: EmailStr


class RedefinirSenha(BaseModel):
    token: str
    nova_senha: str = Field(min_length=8, max_length=128)
    confirmar_senha: str

    @model_validator(mode="after")
    def validar_senhas(self):
        if self.nova_senha != self.confirmar_senha:
            raise ValueError("As senhas não coincidem.")

        return self
