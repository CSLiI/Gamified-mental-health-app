from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Get DATABASE_URL from environment
DATABASE_URL = os.getenv("DATABASE_URL")

if DATABASE_URL is None:
    raise ValueError("DATABASE_URL not found in environment variables. Check your .env file.")

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,           # Test connections before using
    pool_recycle=300,              # Recycle connections every 5 minutes
    pool_size=5,                   # Reduce connection pool size
    max_overflow=10,               # Max overflow connections
    connect_args={
        "options": "-c statement_timeout=30000",  # 30 second timeout
        "sslmode": "require",      # Force SSL
        "connect_timeout": 10       # Connection timeout in seconds
    }
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()



# Dependency for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()