from pydantic import BaseModel, ConfigDict, EmailStr


class UserCreate(BaseModel):
    nome: str
    email: EmailStr
    senha: str


class UserLogin(BaseModel):
    email: EmailStr
    senha: str
    

class UserResponse(BaseModel):
    id: int
    nome: str
    email: EmailStr

    model_config = ConfigDict(
        from_attributes=True
    )