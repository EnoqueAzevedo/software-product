from datetime import date, time

from pydantic import BaseModel, ConfigDict, Field


class AgendamentoCreate(BaseModel):
    servico_id: int = Field(gt=0)
    profissional_id: int = Field(gt=0)
    data_agendamento: date
    horario_inicio: time

    model_config = ConfigDict(extra="forbid")


class AgendamentoResponse(BaseModel):
    id: int
    usuario_id: int
    servico_id: int
    profissional_id: int
    data_agendamento: date
    horario_inicio: time
    duracao_minutos: int
    status: str

    model_config = ConfigDict(from_attributes=True)


# Agendamento com os nomes do serviço e do profissional
# (usado na tela "Meus Agendamentos" do app)
class AgendamentoDetalhe(BaseModel):
    id: int
    servico_id: int
    servico_nome: str
    imagem_url: str | None = None
    profissional_id: int
    profissional_nome: str
    data: date
    horario: time
    duracao_minutos: int
    status: str
