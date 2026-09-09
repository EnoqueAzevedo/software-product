import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from jose import JWTError, jwt

# Carrega o arquivo .env
load_dotenv()

# Chave usada para assinar o token
SECRET_KEY = os.getenv("SECRET_KEY")

if not SECRET_KEY:
    raise ValueError("SECRET_KEY não encontrada no arquivo .env")

# Algoritmo do JWT
ALGORITHM = "HS256"

# Validade do token
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Cria um token JWT
def create_access_token(data: dict):
    to_encode = data.copy()

    # Define a expiração
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    to_encode.update({"exp": expire})

    # Assina e cria o token
    encoded_jwt = jwt.encode(to_encode,
        SECRET_KEY,
        algorithm=ALGORITHM,
    )

    return encoded_jwt

# Verifica e decodifica o token
def decode_access_token(token: str):
    try:
        # Valida o token
        payload = jwt.decode(
            token,
            SECRET_KEY,
            algorithms=[ALGORITHM],
        )

        return payload

    except JWTError:
        # Token inválido
        return None

    # Verifica o token e retorna o ID do usuário
def get_user_id_from_token(token: str):
    payload = decode_access_token(token)

    if not payload:
        return None

    return payload.get("sub")