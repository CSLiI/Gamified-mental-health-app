from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import (
    auth_routes, 
    mood_routes, 
    user_routes, 
    journal_routes, 
    todo_routes,
    character_routes,
    interest_routes,
    achievement_routes,
    reward_routes,
    journal_prompt_routes,
    friend_routes,
    social,
    daily_routes,
    quest_routes,
    level_routes,
    pet_routes,
    mystery_box_routes,
    comeback_routes,
    builtin_rewards_routes
)
from app.database import engine
from app import models
import uvicorn
import logging
import traceback
import asyncio
from fastapi import Request
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware

# Configure logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("api")

app = FastAPI(
    title="Mental Health Gamified App API",
    description="Backend API for a gamified mental health application for students",
    version="2.0.0"
)


# ==================== REQUEST TIMEOUT MIDDLEWARE ====================
class TimeoutMiddleware(BaseHTTPMiddleware):
    """
    Middleware to timeout slow requests and prevent worker hangs.
    This is critical for single-worker deployments like Render free tier.
    """
    async def dispatch(self, request: Request, call_next):
        # Skip timeout for health checks (they should be fast)
        if request.url.path in ["/health", "/health/deep", "/"]:
            return await call_next(request)
        
        try:
            # 60 second timeout for most requests
            return await asyncio.wait_for(call_next(request), timeout=60.0)
        except asyncio.TimeoutError:
            logger.warning(f"Request timeout: {request.method} {request.url.path}")
            return JSONResponse(
                status_code=504,
                content={"detail": "Request timeout - please try again"}
            )

app.add_middleware(TimeoutMiddleware)
# =====================================================================


# ==================== NON-BLOCKING STARTUP EVENT ====================
@app.on_event("startup")
async def startup_event():
    """
    Initialize database tables on app startup (non-blocking).
    Runs in a thread pool to avoid blocking the async event loop
    and preventing Gunicorn worker timeouts.
    """
    import asyncio
    from concurrent.futures import ThreadPoolExecutor

    def sync_create_tables():
        models.Base.metadata.create_all(bind=engine)

    try:
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as pool:
            await asyncio.wait_for(
                loop.run_in_executor(pool, sync_create_tables),
                timeout=60.0  # 60 second timeout for table creation
            )
        logger.info("Database tables verified/created successfully.")
    except asyncio.TimeoutError:
        logger.error("WARNING: Database table creation timed out after 60s")
        logger.error("App will continue, but database features may fail.")
    except Exception as e:
        logger.error(f"WARNING: Database table creation failed on startup: {e}")
        logger.error("App will continue starting, but database features may fail until connection is restored.")


# ==================== SHUTDOWN EVENT ====================
@app.on_event("shutdown")
async def shutdown_event():
    """
    Clean up database connections on app shutdown.
    This prevents connection leaks and ensures graceful shutdown.
    """
    from app.database import dispose_engine
    try:
        dispose_engine()
        logger.info("Database engine disposed successfully.")
    except Exception as e:
        logger.error(f"Error disposing database engine: {e}")
# =====================================================================


# CORS configuration for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== GLOBAL EXCEPTION HANDLER ====================
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    Catch-all exception handler to prevent server crashes 
    and provide consistent error responses.
    """
    # Log the full stack trace for the developer
    error_msg = f"Unhandled error: {str(exc)}\nPath: {request.url.path}"
    logger.error(error_msg)
    traceback.print_exc()
    
    # Return a friendly JSON response to the user
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal Server Error",
            "message": "Something went wrong on our end. Please try again later.",
            # Only include error details in non-production if needed
            # "error": str(exc) 
        }
    )
# ===================================================================

# ⚠️ IMPORTANT: Include all routers
app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(mood_routes.router)
app.include_router(journal_routes.router)
app.include_router(todo_routes.router)
app.include_router(character_routes.router)
app.include_router(interest_routes.router)
app.include_router(achievement_routes.router)
app.include_router(reward_routes.router)
app.include_router(journal_prompt_routes.router)
app.include_router(friend_routes.router)
app.include_router(daily_routes.router)
app.include_router(social.router)
app.include_router(quest_routes.router)
app.include_router(level_routes.router)
app.include_router(pet_routes.router)
app.include_router(mystery_box_routes.router)
app.include_router(comeback_routes.router)
app.include_router(builtin_rewards_routes.router)

@app.get("/")
def read_root():
    return {
        "message": "Mental Health App API v2.0 is running!",
        "version": "2.0.0",
        "status": "healthy",
        "features": {
            "core": ["auth", "users", "moods", "journals", "todos"],
            "gamification": ["characters", "achievements", "rewards", "interests"],
            "content": ["journal_prompts", "mood_suggestions"]
        },
        "endpoints": {
            "auth": "/auth/register, /auth/login, /auth/me",
            "users": "/users/me, /users/me/interests",
            "moods": "/moods/, /moods/statistics",
            "journals": "/journals/, /journals/search",
            "todos": "/todos/, /todos/statistics",
            "characters": "/characters/, /characters/me/mood-state",
            "achievements": "/achievements/, /achievements/me/check",
            "rewards": "/rewards/, /rewards/me/collection-stats",
            "interests": "/interests/, /interests/popular",
            "prompts": "/journal-prompts/daily, /journal-prompts/random"
        }
    }

@app.get("/health")
def health_check():
    """Lightweight health check for load balancers - doesn't hit the database."""
    return {
        "status": "healthy",
        "version": "2.0.0"
    }


@app.get("/health/deep")
def deep_health_check():
    """
    Deep health check that tests actual database connectivity.
    Use sparingly as it consumes a connection from the pool.
    """
    from sqlalchemy import text
    from app.database import engine
    
    db_status = "unknown"
    pool_info = {}
    
    try:
        # Get pool status
        pool = engine.pool
        pool_info = {
            "size": pool.size(),
            "checked_in": pool.checkedin(),
            "checked_out": pool.checkedout(),
            "overflow": pool.overflow(),
            "invalid": pool.invalidatedcount() if hasattr(pool, 'invalidatedcount') else 0
        }
        
        # Test actual connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
            conn.commit()
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)[:100]}"
    
    return {
        "status": "healthy" if db_status == "connected" else "degraded",
        "database": db_status,
        "pool": pool_info,
        "version": "2.0.0"
    }

import os
print(f"✓ JWT_SECRET is set: {bool(os.getenv('JWT_SECRET'))}")
print(f"✓ JWT_SECRET length: {len(os.getenv('JWT_SECRET', ''))}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)