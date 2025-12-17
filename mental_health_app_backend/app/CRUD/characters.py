from sqlalchemy.orm import Session
from app import models, schemas
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

# ==================== CREATE ====================
def create_character(db: Session, character: schemas.CharacterCreate):
    """Create a new character"""
    db_character = models.Character(
        name=character.name,
        description=character.description,
        image_url=character.image_url
    )
    db.add(db_character)
    db.commit()
    db.refresh(db_character)
    return db_character

# ==================== READ ====================
def get_character(db: Session, character_id: int):
    """Get a specific character by ID"""
    return db.query(models.Character).filter(models.Character.id == character_id).first()

def get_all_characters(db: Session, skip: int = 0, limit: int = 100):
    """Get all available characters"""
    return db.query(models.Character).offset(skip).limit(limit).all()

def get_character_by_name(db: Session, name: str):
    """Get character by name"""
    return db.query(models.Character).filter(models.Character.name == name).first()

# ==================== UPDATE ====================
def update_character(db: Session, character_id: int, character_update: schemas.CharacterUpdate):
    """Update character information"""
    character = db.query(models.Character).filter(models.Character.id == character_id).first()
    if not character:
        return None
    
    update_data = character_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(character, key, value)
    
    db.commit()
    db.refresh(character)
    return character

# ==================== DELETE ====================
def delete_character(db: Session, character_id: int):
    """Delete a character"""
    character = db.query(models.Character).filter(models.Character.id == character_id).first()
    if character:
        db.delete(character)
        db.commit()
    return character

# ==================== USER CHARACTER OPERATIONS ====================
def assign_character_to_user(db: Session, user_id: int, character_id: int):
    """Assign a character to a user"""
    character = get_character(db, character_id)
    if not character:
        return None
    
    existing = db.query(models.UserCharacter).filter(
        models.UserCharacter.user_id == user_id,
        models.UserCharacter.character_id == character_id
    ).first()
    
    if existing:
        existing.chosen_at = datetime.utcnow()
        db.commit()
        db.refresh(existing)
        return existing
    
    user_character = models.UserCharacter(
        user_id=user_id,
        character_id=character_id,
        chosen_at=datetime.utcnow() 
    )
    db.add(user_character)
    db.commit()
    db.refresh(user_character)
    return user_character

def get_user_characters(db: Session, user_id: int):
    """Get all characters chosen by a user"""
    return db.query(models.UserCharacter).filter(
        models.UserCharacter.user_id == user_id
    ).order_by(models.UserCharacter.chosen_at.desc()).all()

def get_current_user_character(db: Session, user_id: int):
    """Get user's most recently chosen character"""
    return db.query(models.UserCharacter).filter(
        models.UserCharacter.user_id == user_id
    ).order_by(models.UserCharacter.chosen_at.desc()).first()

def remove_user_character(db: Session, user_id: int, character_id: int):
    """Remove a character from user's collection"""
    user_character = db.query(models.UserCharacter).filter(
        models.UserCharacter.user_id == user_id,
        models.UserCharacter.character_id == character_id
    ).first()
    
    if user_character:
        db.delete(user_character)
        db.commit()
        return True
    return False

# ==================== CHARACTER MOOD SYNC ====================
def get_character_mood_state(db: Session, user_id: int, days: int = 7):
    """Calculate character state based on user's recent moods"""
    date_from = datetime.utcnow() - timedelta(days=days)
    
    mood_counts = db.query(
        models.MoodLog.mood,
        func.count(models.MoodLog.id).label('count')
    ).filter(
        models.MoodLog.user_id == user_id,
        models.MoodLog.logged_at >= date_from
    ).group_by(models.MoodLog.mood).all()
    
    if not mood_counts:
        return {
            "mood_score": 50,
            "dominant_mood": "calm",
            "character_state": "neutral",
            "environment": "peaceful",
            "total_mood_logs": 0,
            "analysis_period_days": days
        }
    
    mood_scores = {
        "happy": 100,
        "calm": 80,
        "tired": 50,
        "anxious": 30,
        "sad": 20,
        "angry": 10
    }
    
    total_logs = sum(count for _, count in mood_counts)
    weighted_score = sum(mood_scores.get(mood.value, 50) * count for mood, count in mood_counts) / total_logs
    
    dominant_mood = max(mood_counts, key=lambda x: x[1])[0].value
    
    if weighted_score >= 80:
        character_state = "thriving"
        environment = "vibrant"
    elif weighted_score >= 60:
        character_state = "content"
        environment = "peaceful"
    elif weighted_score >= 40:
        character_state = "struggling"
        environment = "cloudy"
    else:
        character_state = "needs_support"
        environment = "stormy"
    
    return {
        "mood_score": round(weighted_score, 2),
        "dominant_mood": dominant_mood,
        "character_state": character_state,
        "environment": environment,
        "total_mood_logs": total_logs,
        "analysis_period_days": days
    }