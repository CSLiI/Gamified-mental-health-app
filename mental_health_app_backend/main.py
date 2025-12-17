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


# Create database tables (will only create if they don't exist)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Mental Health Gamified App API",
    description="Backend API for a gamified mental health application for students",
    version="2.0.0"
)

# CORS configuration for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== GLOBAL EXCEPTION HANDLER ====================
from fastapi import Request
from fastapi.responses import JSONResponse
import traceback
import logging

# Configure logger
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("api")

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
    return {
        "status": "healthy",
        "database": "connected",
        "version": "2.0.0"
    }

import os
print(f"✓ JWT_SECRET is set: {bool(os.getenv('JWT_SECRET'))}")
print(f"✓ JWT_SECRET length: {len(os.getenv('JWT_SECRET', ''))}")

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)