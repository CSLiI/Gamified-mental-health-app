from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models
from app.database import get_db
from app.CRUD import pets

router = APIRouter(prefix="/pets", tags=["pets"])

@router.get("/all")
def get_all_pets(
    db: Session = Depends(get_db)
):
    """Get all available pets"""
    all_pets = pets.get_all_pets(db)
    
    return {
        "pets": [
            {
                "id": p.id,
                "name": p.name,
                "emoji": p.emoji,
                "description": p.description,
                "unlock_level": p.unlock_level,
                "rarity": p.rarity
            }
            for p in all_pets
        ]
    }

@router.get("/unlockable")
def get_unlockable_pets(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get pets user can unlock"""
    available = pets.get_unlockable_pets(db, current_user.id)
    
    return {
        "user_level": current_user.level,
        "pets": [
            {
                "id": p.id,
                "name": p.name,
                "emoji": p.emoji,
                "description": p.description,
                "unlock_level": p.unlock_level,
                "rarity": p.rarity
            }
            for p in available
        ]
    }

@router.get("/my")
def get_my_pets(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's unlocked pets"""
    user_pets = pets.get_user_pets(db, current_user.id)
    
    return {
        "pets": user_pets
    }

@router.post("/unlock/{pet_id}")
def unlock_pet(
    pet_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Unlock a pet"""
    result = pets.unlock_pet(db, current_user.id, pet_id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pet not found"
        )
    
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.get("message")
        )
    
    return result

@router.post("/active/{pet_id}")
def set_active_pet(
    pet_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Set active pet"""
    result = pets.set_active_pet(db, current_user.id, pet_id)
    
    if not result.get("success"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result.get("message")
        )
    
    return result

@router.get("/active")
def get_active_pet(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get currently active pet"""
    active_pet = pets.get_active_pet(db, current_user.id)
    
    if not active_pet:
        return {"has_active_pet": False}
    
    return {
        "has_active_pet": True,
        "pet": active_pet
    }

@router.post("/affection")
def increase_affection(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Increase affection for active pet"""
    success = pets.increase_pet_affection(db, current_user.id)
    
    if not success:
        return {"success": False, "message": "No active pet"}
    
    return {"success": True, "message": "Pet affection increased!"}
