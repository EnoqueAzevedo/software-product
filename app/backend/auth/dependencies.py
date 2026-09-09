from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer

from auth.security import get_user_id_from_token


# Define de onde o FastAPI vai pegar o token
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/users/login"
)


# Obtém o ID do usuário autenticado
async def get_current_user_id(
    token: str = Depends(oauth2_scheme),
):
    user_id = get_user_id_from_token(token)

    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Token inválido ou expirado",
        )

    return int(user_id)