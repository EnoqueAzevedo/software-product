import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from crud.cadastro_provisorio import limpar_cadastros_expirados
from db.session import SessionLocal

from routes.test_routes import router
from routes.health import router as health_router
from routes.user import router as user_router
from routes.auth import router as auth_router
from routes.servico import router as servico_router


# Executa a limpeza periodicamente
async def tarefa_limpeza():
    while True:
        async with SessionLocal() as db:
            await limpar_cadastros_expirados(db)

        # Aguarda 1 hora para executar novamente
        await asyncio.sleep(3600)


# Executa tarefas quando o backend inicia e encerra
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Faz uma limpeza ao iniciar o backend
    async with SessionLocal() as db:
        await limpar_cadastros_expirados(db)

    # Inicia a limpeza automática
    tarefa = asyncio.create_task(tarefa_limpeza())

    yield

    # Encerra a tarefa quando o backend for desligado
    tarefa.cancel()


app = FastAPI(
    lifespan=lifespan,
)


# Permite que o Flutter Web converse com o backend
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Disponibiliza os arquivos de imagens
app.mount(
    "/static",
    StaticFiles(directory="static"),
    name="static",
)


# Registra as rotas da aplicação
app.include_router(router)
app.include_router(health_router)
app.include_router(user_router)
app.include_router(auth_router)
app.include_router(servico_router)


# Rota principal
@app.get("/")
def read_root():
    return {"mensagem": "funcionando"}