from datetime import date, datetime, time
from zoneinfo import ZoneInfo

from fastapi import HTTPException
from sqlalchemy import and_, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from models.agendamento import Agendamento
from models.especialista_servico import EspecialistaServico
from models.profissionais import Profissional  
from models.servico import Servico


FUSO_HORARIO = ZoneInfo("America/Sao_Paulo")


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
    agora = datetime.now(FUSO_HORARIO)

    if data_agendamento < agora.date():
        return []

    resultado_servico = await db.execute(
        select(Servico.duracao).where(
            Servico.id == servico_id,
            Servico.ativo.is_(True),
        )
    )

    duracao_servico = resultado_servico.scalar_one_or_none()

    if duracao_servico is None:
        return []

    resultado_associacao = await db.execute(
        select(EspecialistaServico.id).where(
            EspecialistaServico.servico_id == servico_id,
            EspecialistaServico.profissional_id == profissional_id,
        )
    )

    if resultado_associacao.scalar_one_or_none() is None:
        return []

    resultado = await db.execute(
        select(
            Agendamento.horario_inicio,
            Agendamento.duracao_minutos,
        ).where(
            Agendamento.profissional_id == profissional_id,
            Agendamento.data_agendamento == data_agendamento,
            Agendamento.status == "confirmado",
        )
    )

    agendamentos = resultado.all()

    horarios_ocupados = []

    for horario_inicio, duracao in agendamentos:
        inicio = horario_inicio.hour * 60 + horario_inicio.minute
        fim = inicio + duracao
        horarios_ocupados.append((inicio, fim))

    horarios_disponiveis = []

    inicio_almoco = 12 * 60
    fim_almoco = 13 * 60

    for hora in range(8, 18):
        inicio = hora * 60
        fim = inicio + duracao_servico

        horario_candidato = datetime.combine(
            data_agendamento,
            time(hour=hora),
            tzinfo=FUSO_HORARIO,
        )

        if horario_candidato <= agora:
            continue

        if inicio < fim_almoco and fim > inicio_almoco:
            continue

        conflito = any(
            inicio < fim_ocupado and fim > inicio_ocupado
            for inicio_ocupado, fim_ocupado in horarios_ocupados
        )

        if not conflito:
            horarios_disponiveis.append(f"{hora:02d}:00")

    return horarios_disponiveis


async def criar_agendamento(
    db: AsyncSession,
    usuario_id: int,
    servico_id: int,
    profissional_id: int,
    data_agendamento: date,
    horario_inicio: time,
):
    resultado_servico = await db.execute(
        select(Servico).where(
            Servico.id == servico_id,
            Servico.ativo.is_(True),
        )
    )

    servico = resultado_servico.scalar_one_or_none()

    if servico is None:
        raise HTTPException(
            status_code=404,
            detail="Serviço não encontrado ou inativo.",
        )

    if (
        horario_inicio.minute != 0
        or horario_inicio.second != 0
        or horario_inicio.microsecond != 0
        or not 8 <= horario_inicio.hour <= 17
    ):
        raise HTTPException(
            status_code=400,
            detail="Horário de início inválido.",
        )

    resultado_associacao = await db.execute(
        select(EspecialistaServico.id).where(
            EspecialistaServico.servico_id == servico_id,
            EspecialistaServico.profissional_id == profissional_id,
        )
    )

    if resultado_associacao.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=400,
            detail="Este profissional não realiza o serviço selecionado.",
        )

    horarios = await get_horarios_disponiveis(
        db=db,
        servico_id=servico_id,
        profissional_id=profissional_id,
        data_agendamento=data_agendamento,
    )

    horario_formatado = horario_inicio.strftime("%H:%M")

    if horario_formatado not in horarios:
        raise HTTPException(
            status_code=409,
            detail="Este horário não está mais disponível.",
        )

    novo_agendamento = Agendamento(
        usuario_id=usuario_id,
        servico_id=servico_id,
        profissional_id=profissional_id,
        data_agendamento=data_agendamento,
        horario_inicio=horario_inicio,
        duracao_minutos=servico.duracao,
        status="confirmado",
        criado_em=datetime.now(FUSO_HORARIO),
    )

    try:
        db.add(novo_agendamento)
        await db.commit()
        await db.refresh(novo_agendamento)
        return novo_agendamento

    except IntegrityError as erro:
        await db.rollback()

        if (
            getattr(erro.orig, "sqlstate", None) == "23P01"
            or getattr(erro.orig, "pgcode", None) == "23P01"
        ):
            raise HTTPException(
                status_code=409,
                detail="Este horário conflita com outro agendamento.",
            ) from erro

        raise

    except Exception:
        await db.rollback()
        raise


# Lista os agendamentos do usuário logado.
# historico=False -> próximos horários (confirmados e que ainda não começaram)
# historico=True  -> todo o resto (já passaram)
async def listar_agendamentos_usuario(
    db: AsyncSession,
    usuario_id: int,
    historico: bool,
):
    agora = datetime.now(FUSO_HORARIO)
    hoje = agora.date()
    hora_atual = agora.time()

    ainda_nao_comecou = or_(
        Agendamento.data_agendamento > hoje,
        and_(
            Agendamento.data_agendamento == hoje,
            Agendamento.horario_inicio > hora_atual,
        ),
    )

    proximo = and_(
        Agendamento.status == "confirmado",
        ainda_nao_comecou,
    )

    consulta = (
        select(
            Agendamento.id,
            Agendamento.servico_id,
            Servico.nome.label("servico_nome"),
            Servico.imagem_url,
            Agendamento.profissional_id,
            Profissional.nome_esp.label("profissional_nome"),
            Agendamento.data_agendamento.label("data"),
            Agendamento.horario_inicio.label("horario"),
            Agendamento.duracao_minutos,
            Agendamento.status,
        )
        .select_from(Agendamento)
        .join(Servico, Servico.id == Agendamento.servico_id)
        .join(Profissional, Profissional.id == Agendamento.profissional_id)
        .where(Agendamento.usuario_id == usuario_id)
    )

    if historico:
        consulta = consulta.where(~proximo).order_by(
            Agendamento.data_agendamento.desc(),
            Agendamento.horario_inicio.desc(),
        )
    else:
        consulta = consulta.where(proximo).order_by(
            Agendamento.data_agendamento.asc(),
            Agendamento.horario_inicio.asc(),
        )

    resultado = await db.execute(consulta)

    return [dict(linha) for linha in resultado.mappings().all()]


# Cancela um agendamento do usuário logado (remove do banco)
async def cancelar_agendamento(
    db: AsyncSession,
    usuario_id: int,
    agendamento_id: int,
):
    resultado = await db.execute(
        select(Agendamento).where(
            Agendamento.id == agendamento_id,
            Agendamento.usuario_id == usuario_id,
        )
    )

    agendamento = resultado.scalar_one_or_none()

    # Também cobre o caso de o agendamento ser de outro usuário
    if agendamento is None:
        raise HTTPException(
            status_code=404,
            detail="Agendamento não encontrado.",
        )

    inicio = datetime.combine(
        agendamento.data_agendamento,
        agendamento.horario_inicio,
        tzinfo=FUSO_HORARIO,
    )

    if inicio <= datetime.now(FUSO_HORARIO):
        raise HTTPException(
            status_code=400,
            detail="Não é possível cancelar um agendamento que já começou ou passou.",
        )

    try:
        await db.delete(agendamento)
        await db.commit()

    except Exception:
        await db.rollback()
        raise
