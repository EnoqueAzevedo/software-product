from sqlalchemy import Boolean, Integer, Numeric, Text
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base


# Representa a tabela servicos do banco
class Servico(Base):
    __tablename__ = "servicos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    nome: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    descricao: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    duracao: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    preco: Mapped[float] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )

    ativo: Mapped[bool] = mapped_column(
        Boolean,
        default=True,
        nullable=False,
    )

    imagem_url: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )