from __future__ import annotations

import os
from collections.abc import Generator

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

load_dotenv()

def build_database_url() -> str:
    configured_url = os.getenv("DATABASE_URL")
    if configured_url:
        return configured_url

    db_dialect = os.getenv("DB_DIALECT", "sqlite").strip().lower()
    if db_dialect == "sqlite":
        db_name = os.getenv("DB_NAME", "business_tools.db").strip() or "business_tools.db"
        return f"sqlite:///./{db_name}"

    db_user = os.getenv("DB_USER", "postgres")
    db_password = os.getenv("DB_PASSWORD", "postgres")
    db_host = os.getenv("DB_HOST", "127.0.0.1")
    db_port = os.getenv("DB_PORT", "5432")
    db_name = os.getenv("DB_NAME", "business_tools")
    db_driver = os.getenv("DB_DRIVER", "psycopg")
    return (
        f"{db_dialect}+{db_driver}://{db_user}:{db_password}@"
        f"{db_host}:{db_port}/{db_name}"
    )


DATABASE_URL = build_database_url()

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True,
    future=True,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine, future=True)
Base = declarative_base()


def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

