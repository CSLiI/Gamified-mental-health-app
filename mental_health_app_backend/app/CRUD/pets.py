from sqlalchemy.orm import Session
from app import models
from typing import List, Optional, Dict
from datetime import datetime

def get_all_pets(db: Session) -> List[models.Pet]:
    """Get all available pets"""
    return db.query(models.Pet).all()

def get_unlockable_pets(db: Session, user_id: int) -> List[models.Pet]:
    """Get pets that user can unlock based on their level"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return []
    
    # Get pets user doesn't have yet and can unlock
    unlocked_pet_ids = db.query(models.UserPet.pet_id).filter(
        models.UserPet.user_id == user_id
    ).all()
    unlocked_ids = [p[0] for p in unlocked_pet_ids]
    
    available_pets = db.query(models.Pet).filter(
        models.Pet.unlock_level <= user.level,
        ~models.Pet.id.in_(unlocked_ids)
    ).all()
    
    return available_pets

def get_user_pets(db: Session, user_id: int) -> List[Dict]:
    """Get all pets unlocked by user"""
    user_pets = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id
    ).join(models.Pet).all()
    
    result = []
    for up in user_pets:
        result.append({
            "id": up.pet.id,
            "name": up.pet.name,
            "emoji": up.pet.emoji,
            "description": up.pet.description,
            "rarity": up.pet.rarity,
            "is_active": up.is_active,
            "affection_level": up.affection_level,
            "unlocked_at": up.unlocked_at
        })
    
    return result

def unlock_pet(db: Session, user_id: int, pet_id: int) -> Optional[Dict]:
    """Unlock a pet for a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    
    if not user or not pet:
        return None
    
    # Check if user meets level requirement
    if user.level < pet.unlock_level:
        return {"success": False, "message": f"Requires level {pet.unlock_level}"}
    
    # Check if already unlocked
    existing = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.pet_id == pet_id
    ).first()
    
    if existing:
        return {"success": False, "message": "Pet already unlocked"}
    
    # Unlock the pet
    user_pet = models.UserPet(
        user_id=user_id,
        pet_id=pet_id,
        is_active=False,
        affection_level=1
    )
    db.add(user_pet)
    db.commit()
    
    return {
        "success": True,
        "message": f"Unlocked {pet.name}! {pet.emoji}",
        "pet": {
            "id": pet.id,
            "name": pet.name,
            "emoji": pet.emoji,
            "description": pet.description
        }
    }

def set_active_pet(db: Session, user_id: int, pet_id: int) -> Dict:
    """Set a pet as the active companion"""
    # Deactivate all user's pets
    db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id
    ).update({"is_active": False})
    
    # Activate the selected pet
    user_pet = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.pet_id == pet_id
    ).first()
    
    if not user_pet:
        return {"success": False, "message": "Pet not found"}
    
    user_pet.is_active = True
    db.commit()
    
    pet = db.query(models.Pet).filter(models.Pet.id == pet_id).first()
    
    return {
        "success": True,
        "message": f"{pet.name} is now your companion! {pet.emoji}",
        "active_pet": {
            "id": pet.id,
            "name": pet.name,
            "emoji": pet.emoji
        }
    }

def get_active_pet(db: Session, user_id: int) -> Optional[Dict]:
    """Get user's currently active pet"""
    user_pet = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.is_active == True
    ).join(models.Pet).first()
    
    if not user_pet:
        return None
    
    return {
        "id": user_pet.pet.id,
        "name": user_pet.pet.name,
        "emoji": user_pet.pet.emoji,
        "description": user_pet.pet.description,
        "affection_level": user_pet.affection_level
    }

def increase_pet_affection(db: Session, user_id: int, amount: int = 1):
    """Increase affection for active pet"""
    user_pet = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.is_active == True
    ).first()
    
    if user_pet:
        user_pet.affection_level = min(user_pet.affection_level + amount, 100)
        db.commit()
        return True
    
    return False
