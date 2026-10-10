from sqlalchemy import Integer
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base

class EspecialistaServico(Base):
    __tablename__ = "especialistas_servicos"

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )

    profissional_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    servico_id: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )



