from fastapi import APIRouter

router = APIRouter()

@router.get("/test")
def test_router():
    return {"mensagem": "sucesso"}