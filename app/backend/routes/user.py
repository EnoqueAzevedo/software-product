from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from auth.security import create_access_token
from auth.dependencies import get_current_user_id
from fastapi.security import OAuth2PasswordRequestForm

from db.session import get_db
from schemas.user import UserCreate, UserLogin, UserResponse
from crud.user import (
    create_user,
    authenticate_user,
    delete_user,
    get_user,
    get_users,
)

router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


@router.post("/", response_model=UserResponse)
async def create(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
):
    return await create_user(db, user_data)


@router.get("/", response_model=list[UserResponse])
async def list_users(
    db: AsyncSession = Depends(get_db),
):
    return await get_users(db)


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    user_data = UserLogin(
        email=form_data.username,
        senha=form_data.password,
    )

    user = await authenticate_user(db, user_data)

    if not user:
        raise HTTPException(
            status_code=401,
            detail="Email ou senha inválidos",
        )

    access_token = create_access_token(
        data={
            "sub": str(user.id),
        }
    )

    return {
        "access_token": access_token,
        "token_type": "bearer",
    }

@router.get("/me", response_model=UserResponse)
async def me(
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    user = await get_user(db, user_id)

    if not user:
        raise HTTPException(
            status_code=404,
            detail="Usuário não encontrado",
        )

    return user