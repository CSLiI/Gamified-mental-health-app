from sqlalchemy.orm import Session
from app import models
from typing import Optional, Dict

def calculate_level_from_xp(xp: int) -> int:
    """Calculate level based on XP (100 * level^1.5)"""
    level = 1
    while True:
        xp_needed = int(100 * (level ** 1.5))
        if xp < xp_needed:
            return level
        xp -= xp_needed
        level += 1
        if level > 100:  # Cap at level 100
            return 100

def xp_for_next_level(current_level: int) -> int:
    """Calculate XP needed for next level"""
    return int(100 * (current_level ** 1.5))

def check_level_up(db: Session, user_id: int) -> Optional[Dict]:
    """Check if user leveled up and return celebration data"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    old_level = user.level
    new_level = calculate_level_from_xp(user.xp)
    
    if new_level > old_level:
        user.level = new_level
        db.commit()
        
        # Calculate rewards for level up
        rewards_unlocked = []
        
        # Check for milestone levels (5, 10, 15, 20, 25, etc.)
        milestone_xp = 0
        if new_level % 5 == 0:
            milestone_xp = new_level * 50  # Bonus XP for milestone
            user.xp += milestone_xp
            db.commit()
        
        # Check for newly unlocked rewards
        newly_unlocked_rewards = db.query(models.Reward).filter(
            models.Reward.required_level <= new_level,
            models.Reward.required_level > old_level
        ).all()
        
        # Check for newly unlocked pets
        newly_unlocked_pets = db.query(models.Pet).filter(
            models.Pet.unlock_level <= new_level,
            models.Pet.unlock_level > old_level
        ).all()
        
        return {
            "leveled_up": True,
            "old_level": old_level,
            "new_level": new_level,
            "milestone_xp": milestone_xp,
            "rewards_unlocked": [{"id": r.id, "name": r.name, "tier": r.tier} for r in newly_unlocked_rewards],
            "pets_unlocked": [{"id": p.id, "name": p.name, "emoji": p.emoji} for p in newly_unlocked_pets],
            "message": f"🎉 Congratulations! You reached Level {new_level}!"
        }
    
    return {
        "leveled_up": False,
        "current_level": user.level,
        "current_xp": user.xp,
        "xp_for_next": xp_for_next_level(user.level)
    }

def get_level_progress(db: Session, user_id: int) -> Dict:
    """Get user's current level and progress to next level"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return {}
    
    current_level = user.level
    total_xp = user.xp
    
    # Calculate XP in current level
    xp_spent = 0
    for level in range(1, current_level):
        xp_spent += int(100 * (level ** 1.5))
    
    xp_in_current_level = total_xp - xp_spent
    xp_for_next = xp_for_next_level(current_level)
    
    return {
        "level": current_level,
        "total_xp": total_xp,
        "xp_in_current_level": xp_in_current_level,
        "xp_for_next_level": xp_for_next,
        "progress_percentage": int((xp_in_current_level / xp_for_next) * 100)
    }
