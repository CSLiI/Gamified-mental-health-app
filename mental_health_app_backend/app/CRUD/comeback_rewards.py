from sqlalchemy.orm import Session
from app import models
from datetime import datetime, timedelta
from typing import Optional, Dict

def check_comeback_reward(db: Session, user_id: int) -> Optional[Dict]:
    """Check if user qualifies for comeback reward"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    # Update last_active timestamp
    now = datetime.utcnow()
    last_active = user.last_active
    user.last_active = now
    db.commit()
    
    # If first time or last_active not set
    if not last_active:
        return {"has_reward": False, "message": "Welcome!"}
    
    # Calculate days away
    days_away = (now - last_active).days
    
    # No comeback reward if active recently (< 2 days)
    if days_away < 2:
        return {"has_reward": False, "days_away": days_away}
    
    # Calculate reward based on days away
    reward_tiers = [
        {"min_days": 2, "max_days": 3, "xp": 50, "box": "bronze", "message": "Welcome back! We missed you!"},
        {"min_days": 4, "max_days": 7, "xp": 100, "box": "silver", "message": "Great to see you again!"},
        {"min_days": 8, "max_days": 14, "xp": 200, "box": "gold", "message": "We're so glad you're back!"},
        {"min_days": 15, "max_days": 30, "xp": 350, "box": "gold", "message": "Amazing! You came back!"},
        {"min_days": 31, "max_days": 999, "xp": 500, "box": "legendary", "message": "Incredible! Welcome back, champion!"}
    ]
    
    selected_tier = None
    for tier in reward_tiers:
        if tier["min_days"] <= days_away <= tier["max_days"]:
            selected_tier = tier
            break
    
    if not selected_tier:
        selected_tier = reward_tiers[-1]  # Max tier for very long absences
    
    # Award XP
    user.xp += selected_tier["xp"]
    
    # Create mystery box (import from mystery_boxes module)
    from app.CRUD import mystery_boxes
    box = mystery_boxes.create_mystery_box(
        db, 
        user_id, 
        selected_tier["box"], 
        f"comeback_{days_away}days"
    )
    
    # Restore streak freeze if away for long time
    if days_away >= 7 and not user.streak_freeze_available:
        user.streak_freeze_available = True
    
    db.commit()
    
    # Check for level up
    from app.CRUD import level_system
    level_system.check_level_up(db, user_id)
    
    return {
        "has_reward": True,
        "days_away": days_away,
        "xp_earned": selected_tier["xp"],
        "mystery_box": {
            "id": box.id,
            "type": selected_tier["box"]
        },
        "streak_freeze_restored": days_away >= 7,
        "message": selected_tier["message"],
        "total_xp": user.xp
    }

def update_last_active(db: Session, user_id: int):
    """Update user's last active timestamp"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        user.last_active = datetime.utcnow()
        db.commit()
        return True
    return False

def get_inactive_users(db: Session, days_threshold: int = 3) -> list:
    """Get list of users who haven't been active for X days (for notifications)"""
    threshold_date = datetime.utcnow() - timedelta(days=days_threshold)
    
    inactive_users = db.query(models.User).filter(
        models.User.last_active < threshold_date
    ).all()
    
    return [
        {
            "id": user.id,
            "email": user.email,
            "first_name": user.first_name,
            "days_inactive": (datetime.utcnow() - user.last_active).days
        }
        for user in inactive_users
    ]
