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

def rename_pet(db: Session, user_id: int, pet_id: int, name: str) -> Dict:
    """Rename a user's pet"""
    user_pet = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.pet_id == pet_id
    ).first()
    
    if not user_pet:
        return {"success": False, "message": "Pet not found"}
        
    user_pet.nickname = name
    db.commit()
    
    return {"success": True, "message": f"Renamed to {name}!"}

def calculate_pet_decay(db: Session, user_pet: models.UserPet):
    """Calculate and apply hunger/affection decay based on time"""
    if not user_pet.last_fed_at:
        user_pet.last_fed_at = datetime.utcnow()
        db.commit()
        return

    now = datetime.utcnow()
    # Handle timezone if last_fed_at is aware
    if user_pet.last_fed_at.tzinfo:
        from datetime import timezone
        now = datetime.now(timezone.utc)

    elapsed = now - user_pet.last_fed_at
    hours_passed = elapsed.total_seconds() / 3600
    
    if hours_passed < 0.1: # Only update if > 6 mins passed
        return

    # Decay rates
    hunger_loss = int(hours_passed * 5) # 5 per hour
    affection_loss = int(hours_passed * 1) # 1 per hour base
    
    current_hunger = user_pet.hunger or 50
    
    # Calculate new hunger first
    new_hunger = max(0, current_hunger - hunger_loss)
    
    if new_hunger < 30:
        affection_loss += int(hours_passed * 2) # Extra penalty if hungry
        
    current_affection = user_pet.affection_level
    new_affection = max(0, current_affection - affection_loss)
    
    if new_hunger != current_hunger or new_affection != current_affection:
        user_pet.hunger = new_hunger
        user_pet.affection_level = new_affection
        user_pet.last_fed_at = now # Update timestamp to prevent double decay
        db.commit()

def get_user_pets(db: Session, user_id: int) -> List[Dict]:
    """Get all pets unlocked by user"""
    user_pets = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id
    ).join(models.Pet).all()
    
    result = []
    for up in user_pets:
        calculate_pet_decay(db, up) # Apply decay
        result.append({
            "id": up.pet.id,
            "name": up.nickname or up.pet.name,
            "original_name": up.pet.name,
            "emoji": up.pet.emoji,
            "description": up.pet.description,
            "rarity": up.pet.rarity,
            "lottie_file": up.pet.lottie_file,
            "is_active": up.is_active,
            "affection_level": up.affection_level,
            "hunger": up.hunger or 50,
            "last_fed_at": up.last_fed_at,
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
            "description": pet.description,
            "lottie_file": pet.lottie_file
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
            "emoji": pet.emoji,
            "lottie_file": pet.lottie_file
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
    
    calculate_pet_decay(db, user_pet)
    
    return {
        "id": user_pet.pet.id,
        "name": user_pet.nickname or user_pet.pet.name,
        "original_name": user_pet.pet.name,
        "emoji": user_pet.pet.emoji,
        "description": user_pet.pet.description,
        "lottie_file": user_pet.pet.lottie_file,
        "affection_level": user_pet.affection_level,
        "hunger": user_pet.hunger or 50
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

def feed_pet(db: Session, user_id: int) -> Dict:
    """Feed the active pet"""
    user_pet = db.query(models.UserPet).filter(
        models.UserPet.user_id == user_id,
        models.UserPet.is_active == True
    ).first()
    
    if not user_pet:
        return {"success": False, "message": "No active pet"}
        
    # Increase hunger (0-100, where 100 is full)
    hunger_gain = 1  # Slow increase like affection
    current_hunger = user_pet.hunger or 50
    user_pet.hunger = min(current_hunger + hunger_gain, 100)
    user_pet.last_fed_at = datetime.utcnow()
    
    # Also increase affection slightly
    user_pet.affection_level = min(user_pet.affection_level + 1, 100)
    
    db.commit()
    
    return {
        "success": True,
        "message": "Yummy! 🍖",
        "hunger_gained": hunger_gain,
        "new_hunger": user_pet.hunger
    }
