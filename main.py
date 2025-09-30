from fastapi import FastAPI
from app.routers import centralized_route
import uvicorn

app = FastAPI()

app.include_router(centralized_route.rou)

@app.get("/")
def read_root():
    return {"message": "Backend is running!"}

if __name__ == "__main__":
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)
