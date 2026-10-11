from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.agendamento import Agendamento
from models.servico import Servico

async def get_agendamentos_por_profissional_e_data(
    db: AsyncSession,
    profissional_id: int,
    data_agendamento: date,
):
    resultado = await db.execute(
        select(Agendamento).where(
            Agendamento.profissional_id == profissional_id,
            Agendamento.data_agendamento == data_agendamento,
            Agendamento.status == "confirmado",
        )
    )

    return resultado.scalars().all()

async def get_horarios_disponiveis(
    db: AsyncSession,
    servico_id: int,
    profissional_id: int,
    data_agendamento: date,
):
    # Não permitir datas passadas.
    hoje = datetime.now(
        ZoneInfo("America/Sao_Paulo")
    ).date()

    if data_agendamento < hoje:
        return []

    # Buscar a duração do serviço escolhido.
    resultado_servico = await db.execute(
        select(Servico.duracao).where(
            Servico.id == servico_id,
            Servico.ativo.is_(True),
        )
    )

    duracao_servico = resultado_servico.scalar_one_or_none()

    if duracao_servico is None:
        return []

    # Buscar os agendamentos confirmados e a duração
    # de cada serviço já reservado para esse profissional.
    resultado = await db.execute(
        select(
            Agendamento.horario_inicio,
            Servico.duracao,
        )
        .join(
            Servico,
            Servico.id == Agendamento.servico_id,
        )
        .where(
            Agendamento.profissional_id == profissional_id,
            Agendamento.data_agendamento == data_agendamento,
            Agendamento.status == "confirmado",
        )
    )

    agendamentos = resultado.all()

    # Converter os horários ocupados para minutos do dia.
    horarios_ocupados = []

    for horario_inicio, duracao in agendamentos:
        inicio = (
            horario_inicio.hour * 60
            + horario_inicio.minute
        )

        fim = inicio + duracao

        horarios_ocupados.append((inicio, fim))

    # Gerar horários de início de hora em hora,
    # das 08:00 às 17:00, inclusive.
    horarios_disponiveis = []

    agora = datetime.now(
        ZoneInfo("America/Sao_Paulo")
    )

    for hora in range(8, 18):
        inicio = hora * 60
        fim = inicio + duracao_servico

        # Não permitir horários no passado.
        horario_candidato = datetime.combine(
            data_agendamento,
            time(hour=hora),
            tzinfo=ZoneInfo("America/Sao_Paulo"),
        )

        if horario_candidato <= agora:
            continue

        # Não permitir início durante o almoço.
        # Também impede serviços que atravessem o almoço.
        inicio_almoco = 12 * 60
        fim_almoco = 13 * 60

        if inicio < fim_almoco and fim > inicio_almoco:
            continue

        # Verificar sobreposição com outros agendamentos.
        conflito = any(
            inicio < fim_ocupado
            and fim > inicio_ocupado
            for inicio_ocupado, fim_ocupado
            in horarios_ocupados
        )

        if not conflito:
            horarios_disponiveis.append(
                f"{hora:02d}:00"
            )

    return horarios_disponiveis