from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column

from db.session import Base


# Guarda o cadastro enquanto o e-mail não foi confirmado
class CadastroProvisorio(Base):
    __tablename__ = "cadastros_provisorios"

    # Identifica o cadastro provisório através do token
    token_confirmacao: Mapped[str] = mapped_column(
        Text,
        primary_key=True,
    )

    nome: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    email: Mapped[str] = mapped_column(
        Text,
        unique=True,
        nullable=False,
        index=True,
    )

    # Guarda somente o hash da senha
    senha: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    # Data e hora limite para confirmação
    expira_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )

    # Indica se o e-mail já foi confirmado
    confirmado: Mapped[bool] = mapped_column(
        Boolean,
        default=False,
        nullable=False,
    )

    # Data e hora em que o cadastro foi criado
    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )
    

# token_confirmacao ← identificador técnico
# nome
# email
# senha             ← hash
# expira_em         ← 24 horas
# confirmado        ← false
# criado_em