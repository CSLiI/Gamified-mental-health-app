from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import auth_routes, mood_routes, user_routes, journal_routes, todo_routes
from app.database import engine
from app import models
import uvicorn

# Create database tables (will only create if they don't exist)
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Mental Health Gamified App API",
    description="Backend API for a gamified mental health application for students",
    version="1.0.0"
)

# CORS configuration for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Change to specific origins in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all routers
app.include_router(auth_routes.router)
app.include_router(user_routes.router)
app.include_router(mood_routes.router)
app.include_router(journal_routes.router)
app.include_router(todo_routes.router)

@app.get("/")
def read_root():
    return {
        "message": "Mental Health App API is running!",
        "version": "1.0.0",
        "status": "healthy",
        "endpoints": {
            "auth": "/auth/register, /auth/login",
            "users": "/users/me",
            "moods": "/moods/",
            "journals": "/journals/",
            "todos": "/todos/"
        }
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "connected"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)