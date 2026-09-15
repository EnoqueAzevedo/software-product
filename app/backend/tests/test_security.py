from fastapi import HTTPException
from auth.security import create_access_token, get_user_id_from_token
from auth.dependencies import get_current_user_id

def test_create_and_read_token():
    token = create_access_token({"sub": "123"})

    user_id = get_user_id_from_token(token)

    assert user_id == "123"

def test_invalid_token():
    user_id = get_user_id_from_token("token_invalido")

    assert user_id is None

def test_token_with_invalid_sub():
    token = create_access_token({"sub": "abc"})

    user_id = get_user_id_from_token(token)

    assert user_id == "abc"

import pytest


@pytest.mark.anyio
async def test_current_user_invalid_sub():
    token = create_access_token({"sub": "abc"})

    with pytest.raises(HTTPException) as exc:
        await get_current_user_id(token)

    assert exc.value.status_code == 401
    assert exc.value.detail == "Token inválido ou expirado"

#def test_current_user_invalid_token():
#    with pytest.raises(HTTPException) as exc:
#        import asyncio
#        asyncio.run(get_current_user_id("token_invalido"))
#
#    assert exc.value.status_code == 401
#    assert exc.value.detail == "Token inválido ou expirado"