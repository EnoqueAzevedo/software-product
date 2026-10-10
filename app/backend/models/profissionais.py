from sqlalchemy import Text
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base 

class Profissional(Base):
    __tablename__ = "profissionais"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    nome_esp: Mapped[str] =mapped_column(
        Text,
        nullable=False,
    )

    especialidade: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    foto: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )