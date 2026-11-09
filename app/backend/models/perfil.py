from datetime import date

from sqlalchemy import Date, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base


class Perfil(Base):
    __tablename__ = "perfis"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        unique=True,
        nullable=False,
    )

    telefone: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    genero: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    data_nascimento: Mapped[date | None] = mapped_column(
        Date,
        nullable=True,
    )

    imagem_url: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )