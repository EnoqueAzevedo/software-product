from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, Identity, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base


class RecuperacaoSenha(Base):
    __tablename__ = "recuperacao_senhas"

    id: Mapped[int] = mapped_column(
        BigInteger,
        Identity(always=True),
        primary_key=True
    )

    usuario_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("usuarios.id", ondelete="CASCADE"),
        nullable=False
    )

    token_hash: Mapped[str] = mapped_column(
        Text,
        unique=True,
        nullable=False
    )

    expira_em: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False
    )

    utilizado: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False
    )

    criado_em: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now()
    )
