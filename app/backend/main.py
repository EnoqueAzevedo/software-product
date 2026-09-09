from fastapi import FastAPI

from routes.test_routes import router
from routes.health import router as health_router
from routes.user import router as user_router

app = FastAPI()

app.include_router(router)
app.include_router(health_router)
app.include_router(user_router)


@app.get("/")
def read_root():
    return {"mensagem": "funcionando"}