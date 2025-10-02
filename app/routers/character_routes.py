from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import characters as character_crud

router = APIRouter(prefix="/characters", tags=["Characters"])

# ==================== Characters ====================
@router.post("/", response_model=schemas.Character, status_code=status.HTTP_201_CREATED)
def create_character(
    character: schemas.CharacterCreate,
    db: Session = Depends(get_db)
):
    """Create a new character (admin only)"""
    return character_crud.create_character(db, character)

@router.get("/", response_model=List[schemas.Character])
def get_all_characters(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all available characters"""
    return character_crud.get_all_characters(db, skip, limit)

@router.get("/{character_id}", response_model=schemas.Character)
def get_character(
    character_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific character"""
    character = character_crud.get_character(db, character_id)
    if not character:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Character not found"
        )
    return character

# ==================== User Characters ====================
@router.post("/me/choose/{character_id}", response_model=schemas.UserCharacter, status_code=status.HTTP_201_CREATED)
def choose_character(
    character_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Choose a character for current user"""
    user_character = character_crud.assign_character_to_user(db, current_user.id, character_id)
    if not user_character:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Character not found"
        )
    return user_character

@router.get("/me/characters", response_model=List[schemas.UserCharacter])
def get_my_characters(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all characters chosen by current user"""
    return character_crud.get_user_characters(db, current_user.id)

@router.get("/me/current", response_model=schemas.UserCharacter)
def get_my_current_character(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's active character"""
    character = character_crud.get_current_user_character(db, current_user.id)
    if not character:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No character chosen yet"
        )
    return character

# ==================== Interests ====================