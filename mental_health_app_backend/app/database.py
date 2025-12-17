from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os
import time
import logging

# Load environment variables from .env file, forcing override so a stale shell env (e.g. sqlite URL) cannot mask Supabase settings
load_dotenv(override=True)

# Get DATABASE_URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

# Basic diagnostics (printed once at import) to help trace connection issues
_raw_url = DATABASE_URL or "<missing>"
print(f"[DB INIT] Effective DATABASE_URL loaded: { _raw_url[:80] + ('...' if len(_raw_url) > 80 else '') }")
if DATABASE_URL and DATABASE_URL.startswith("sqlite"):
    print("[DB INIT][WARN] Using sqlite URL; .env override may have failed or you intentionally set local dev.")

if DATABASE_URL is None:
    raise ValueError("DATABASE_URL not found in environment variables. Check your .env file.")

# Add SSL and timeout parameters to URL if not already present
if DATABASE_URL and "?" not in DATABASE_URL:
    DATABASE_URL += "?sslmode=require&connect_timeout=30"
elif DATABASE_URL and "sslmode" not in DATABASE_URL:
    DATABASE_URL += "&sslmode=require&connect_timeout=30"

# Log connection target for debugging (masking credentials)
if DATABASE_URL:
    try:
        from urllib.parse import urlparse
        parsed = urlparse(DATABASE_URL)
        print(f"[DB INIT] Target Host: {parsed.hostname}, Port: {parsed.port}")
    except Exception:
        pass

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,            # Test connections before using
    pool_recycle=300,              # Recycle connections every 5 minutes
    pool_size=5,                   # Increased pool for concurrent requests
    max_overflow=10,               # Total max = 15 connections (allow bursts)
    pool_timeout=30,               # Wait up to 30s for a connection from pool
    pool_use_lifo=True             # Return most recently used connections first
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
    db = None
    retries = 3
    for attempt in range(retries):
        try:
            db = SessionLocal()
            # Explicitly check connection health to trigger pool recovery or fail fast
            db.execute(text("SELECT 1"))
            break
        except Exception as e:
            if db:
                db.close()
            if attempt < retries - 1:
                # Exponential backoff: 0.5s, 1.0s, etc.
                time.sleep(0.5 * (attempt + 1))
                continue
            else:
                # If all retries fail, log it and raise
                logging.getLogger("database").error(f"Failed to get DB session after {retries} attempts: {e}")
                raise

    try:
        yield db
    finally:
        if db:
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