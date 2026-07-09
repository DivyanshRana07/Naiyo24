# pyrefly: ignore [missing-import]
"""
conftest.py — Shared pytest fixtures for the entire test suite.

Architecture:
  - `test_engine` is the single source of truth (one in-memory DB per test).
  - `db_session` and `client` BOTH depend on `test_engine`.
  - pytest guarantees a single `test_engine` instance per test function,
    so all fixtures in the same test share the SAME in-memory database.
  - No production database is ever touched.
"""

# pyrefly: ignore [missing-import]
import pytest
# pyrefly: ignore [missing-import]
from sqlalchemy import create_engine
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import sessionmaker
# pyrefly: ignore [missing-import]
from sqlalchemy.pool import StaticPool
# pyrefly: ignore [missing-import]
from fastapi.testclient import TestClient

from db import Base, get_db
from main import app
from models.db_models import User
# pyrefly: ignore [missing-import]
from jose import jwt
from datetime import datetime, timedelta
from core.security import SECRET_KEY, ALGORITHM, hash_password
import models.db_models  # noqa: F401


def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=60)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


TEST_DATABASE_URL = "sqlite:///:memory:"


# ---------------------------------------------------------------------------
# Engine fixture — ONE fresh in-memory DB per test function.
# All other fixtures that depend on this will share the SAME instance
# within a single test (pytest fixture caching guarantees this).
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def test_engine():
    """
    Creates a fresh in-memory SQLite engine for each test.
    All fixtures within the same test receive the same engine instance.
    """
    engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        # StaticPool ensures all sessions reuse the SAME connection.
        # Without this, each new Session gets a brand-new empty in-memory DB.
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    yield engine
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


# ---------------------------------------------------------------------------
# Session factory fixture — shared by both client and db_session
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def session_factory(test_engine):
    """
    Returns a sessionmaker bound to the test engine.
    Both `client` and `db_session` use this to ensure they share the same DB.
    """
    return sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


# ---------------------------------------------------------------------------
# Direct DB session — for asserting persisted state inside tests
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def db_session(session_factory):
    """
    Yields a SQLAlchemy session for direct DB queries inside tests.
    Closes cleanly regardless of test outcome.
    """
    session = session_factory()
    try:
        yield session
    finally:
        session.close()


# ---------------------------------------------------------------------------
# HTTP client — FastAPI TestClient with DB dependency override (NO auth)
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def client(session_factory):
    """
    FastAPI TestClient with get_db overridden to use the test DB.
    Uses the SAME session_factory as db_session → same in-memory database.
    Dependency overrides are always cleared after the test.
    """
    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Authenticated test user — seeds a User row and returns the ORM object
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def test_user(db_session):
    """
    Inserts a test user into the in-memory DB and returns the User object.
    Re-usable by any test that needs an authenticated context.
    """
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=hash_password("password123"),
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


# ---------------------------------------------------------------------------
# Authenticated HTTP client — sends a valid JWT on every request
# ---------------------------------------------------------------------------

@pytest.fixture(scope="function")
def auth_client(session_factory, test_user):
    """
    FastAPI TestClient that includes a valid Authorization header.
    Steps:
      1. Uses the same session_factory → same in-memory DB.
      2. Generates a JWT for the test_user seeded by the `test_user` fixture.
      3. Injects the token into the default request headers.
    """
    def override_get_db():
        db = session_factory()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db

    token = create_access_token({"sub": str(test_user.id)})

    with TestClient(app) as test_client:
        test_client.headers["Authorization"] = f"Bearer {token}"
        yield test_client

    app.dependency_overrides.clear()


# ---------------------------------------------------------------------------
# Payload factories exposed as fixtures
# ---------------------------------------------------------------------------

def make_party(
    name: str = "Acme Technologies Pvt Ltd",
    address: str = "101 Business Park Andheri East",
    city: str = "Mumbai",
    state_name: str = "Maharashtra",
    state_code: str = "27",
    postal_code: str = "400069",
    gstin: str | None = "27AABCU9603R1ZX",
) -> dict:
    """Returns a valid PartyDetails dict."""
    party = {
        "name": name,
        "address_line_1": address,
        "city": city,
        "state_name": state_name,
        "state_code": state_code,
        "postal_code": postal_code,
    }
    if gstin:
        party["gstin"] = gstin
    return party


def make_invoice_item(
    name: str = "Consulting Service",
    quantity: str = "10",
    price: str = "1000",
    gst_rate: str = "18",
) -> dict:
    return {
        "name": name,
        "quantity": quantity,
        "price": price,
        "gst_rate": gst_rate,
    }


@pytest.fixture
def party_factory():
    return make_party


@pytest.fixture
def item_factory():
    return make_invoice_item
