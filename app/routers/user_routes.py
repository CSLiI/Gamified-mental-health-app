from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from .. import crud, schemas, database

router = APIRouter(prefix="/users", tags=["users"])

def create_user_endpoint(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    return crud.create_user(db, user)

def get_user_endpoint(user_id: int, db: Session = Depends(database.get_db)):
    user = crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
