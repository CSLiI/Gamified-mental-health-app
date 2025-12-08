from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth import get_current_user
from app.models import User
from app.schemas import (
    PetResponse,
    UserPetResponse,
    PetUnlockResponse,
    PetEquipResponse,
    PetEquipResponse,
    PetInteractResponse,
    PetFeedResponse
)
from app.CRUD import pets as crud
from typing import List

router = APIRouter(prefix="/pets", tags=["Pets"])


@router.get("/catalog", response_model=List[PetResponse])
async def get_pet_catalog(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all available pets"""
    return crud.get_all_pets(db)


@router.get("/my-pets", response_model=List[UserPetResponse])
async def get_my_pets(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all pets owned by the current user"""
    return crud.get_user_pets(db, current_user.id)


@router.post("/unlock/{pet_id}", response_model=PetUnlockResponse)
async def unlock_pet(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Unlock a pet (check level requirements)"""
    result = crud.unlock_pet(db, current_user.id, pet_id)
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found"
        )
    
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )
        
    return result


@router.post("/equip/{pet_id}", response_model=PetEquipResponse)
async def equip_pet(
    pet_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Set a pet as active companion"""
    result = crud.set_active_pet(db, current_user.id, pet_id)
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result["message"]
        )
    return result


@router.post("/interact", response_model=PetInteractResponse)
async def interact_with_pet(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Interact with active pet (increase affection)"""
    # Fetch user from database to ensure we have the latest state
    from app.CRUD import users as user_crud
    user = user_crud.get_user(db, current_user.id)
    
    if not user or user.energy < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not enough energy (need 10)"
        )
    
    user.energy -= 10
    db.commit()
    db.refresh(user)

    success = crud.increase_pet_affection(db, current_user.id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active pet found"
        )
    
    return {
        "success": True,
        "message": "Pet feels loved! ❤️",
        "affection_gained": 1
    }


@router.post("/feed", response_model=PetFeedResponse)
async def feed_pet(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Feed the active pet"""
    # Fetch user from database to ensure we have the latest state
    from app.CRUD import users as user_crud
    user = user_crud.get_user(db, current_user.id)
    
    if not user or user.energy < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not enough energy (need 10)"
        )
    
    user.energy -= 10
    db.commit()
    db.refresh(user)

    result = crud.feed_pet(db, current_user.id)
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=result["message"]
        )
    return result


@router.put("/{pet_id}/rename")
async def rename_pet(
    pet_id: int,
    name: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Rename a user's pet"""
    result = crud.rename_pet(db, current_user.id, pet_id, name)
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )
    return result
