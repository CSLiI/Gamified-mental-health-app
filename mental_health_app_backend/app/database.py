from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os
import time
import logging

# Load environment variables from .env file
load_dotenv()

# Get DATABASE_URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL is None:
    raise ValueError("DATABASE_URL not found in environment variables. Check your .env file.")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,            # Test connections before using
    pool_recycle=300,              # Recycle connections every 5 minutes
    pool_size=8,                   # Increased from 5 to handle initial burst
    max_overflow=3,                # Modest overflow for peak load
    pool_timeout=15,               # Wait at most 15s for a connection from pool
    pool_use_lifo=True,            # Return most recently used connections first
    connect_args={
        "options": "-c statement_timeout=30000",   # 30s statement timeout
        "sslmode": "require",                       # Supabase requires SSL
        "connect_timeout": 10                        # 10s TCP connect timeout
    }
)
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    expire_on_commit=False,   # Avoid implicit lazy loads after commit
    bind=engine,
)
Base = declarative_base()



# Dependency for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        try:
            db.close()
        except Exception:
            pass


# Proactive connection check with simple retry to surface clearer errors
def _ping_database_with_retries(max_attempts: int = 3, delay_seconds: int = 2) -> None:
    logger = logging.getLogger("database")
    last_err = None
    for attempt in range(1, max_attempts + 1):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
                logger.info("Database connectivity OK (attempt %d)", attempt)
                return
        except Exception as e:
            last_err = e
            logger.warning(
                "Database connection attempt %d failed: %s", attempt, repr(e)
            )
            time.sleep(delay_seconds)
    # If still failing, raise with helpful guidance
    raise RuntimeError(
        (
            "Unable to connect to the database after %d attempts.\n"
            "Current DATABASE_URL: %s\n"
            "Tips:\n"
            "- Verify internet connectivity and that Supabase pooler is reachable.\n"
            "- Check that your machine/network allows outbound TCP 5432.\n"
            "- Confirm credentials and sslmode=require in DATABASE_URL.\n"
            "- For local dev, set DATABASE_URL to a local Postgres or SQLite (e.g., 'sqlite:///./dev.db')."
        )
        % (max_attempts, DATABASE_URL)
    )


# Attempt ping on module import to fail fast with retries
try:
    _ping_database_with_retries()
except RuntimeError:
    # Do not crash import; FastAPI will surface errors on first request.
    # Logging provides guidance while keeping app boot resilient.
    pass


# Optional: utility to dispose engine on app shutdown to free connections
def dispose_engine():
    try:
        engine.dispose()
    except Exception:
        pass