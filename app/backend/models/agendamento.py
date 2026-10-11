
from datetime import date, datetime, time

from sqlalchemy import BigInteger, Date, DateTime, ForeignKey, Time, Text
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base


class Agendamento(Base):
    __tablename__ = "agendamentos"

    id: Mapped[int] = mapped_column(
        BigInteger,
        primary_key=True,
        index=True,
    )

    usuario_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("usuarios.id"),
        nullable=False,
    )

    servico_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("servicos.id"),
        nullable=False,
    )

    profissional_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("profissionais.id"),
        nullable=False,
    )

    data_agendamento: Mapped[date] = mapped_column(
        Date,
        nullable=False,
    )

    horario_inicio: Mapped[time] = mapped_column(
        Time,
        nullable=False,
    )

    status: Mapped[str] = mapped_column(
        Text,
        nullable=False,
        default="confirmado",
    )

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )