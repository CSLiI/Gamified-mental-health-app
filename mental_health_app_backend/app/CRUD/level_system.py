from sqlalchemy.orm import Session
from app import models
from typing import Optional, Dict

# Progressive XP system: Each level requires more XP than the previous
# Formula: base_xp * (1 + (level - 1) * growth_factor)
BASE_XP = 100  # XP required for level 1 -> 2
GROWTH_FACTOR = 0.15  # 15% increase per level

def xp_for_level(level: int) -> int:
    """Calculate total XP required to reach a specific level from level 1"""
    if level <= 1:
        return 0
    
    # Sum of progressive XP requirements from level 1 to target level
    total = 0
    for lvl in range(1, level):
        total += xp_for_next_level(lvl)
    return total

def xp_for_next_level(current_level: int) -> int:
    """XP needed within current level to reach next level (progressive)"""
    if current_level < 1:
        current_level = 1
    # Progressive formula: 100 * (1 + (level - 1) * 0.15)
    # Level 1->2: 100 XP
    # Level 2->3: 115 XP
    # Level 3->4: 130 XP
    # Level 10->11: 235 XP
    # Level 20->21: 385 XP
    return int(BASE_XP * (1 + (current_level - 1) * GROWTH_FACTOR))

def calculate_level_from_xp(xp: int) -> int:
    """Calculate level based on total XP (progressive system)"""
    if xp < 0:
        return 1
    
    level = 1
    accumulated_xp = 0
    
    # Find the highest level where total XP requirement is met
    while level < 100:  # Cap at level 100
        xp_needed = xp_for_next_level(level)
        if accumulated_xp + xp_needed > xp:
            break
        accumulated_xp += xp_needed
        level += 1
    
    return level

def get_xp_in_current_level(total_xp: int) -> int:
    """Get XP progress within current level (progressive system)"""
    if total_xp < 0:
        return 0
    
    level = calculate_level_from_xp(total_xp)
    xp_at_level_start = xp_for_level(level)
    
    return total_xp - xp_at_level_start

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
        print(f"❌ User not found: {user_id}")
        return {}
    
    total_xp = max(0, user.xp)  # Ensure XP is never negative
    
    # Recalculate level from XP to ensure consistency
    correct_level = calculate_level_from_xp(total_xp)
    
    # Update level in DB if out of sync
    if user.level != correct_level:
        print(f"🔄 Syncing level: {user.level} -> {correct_level} (XP: {total_xp})")
        user.level = correct_level
        db.commit()
    
    # Progressive calculation
    xp_in_current_level = get_xp_in_current_level(total_xp)
    xp_for_next = xp_for_next_level(correct_level)
    
    # Avoid division by zero
    progress_pct = int((xp_in_current_level / xp_for_next) * 100) if xp_for_next > 0 else 0
    
    result = {
        "level": correct_level,
        "total_xp": total_xp,
        "xp_in_current_level": xp_in_current_level,
        "xp_for_next_level": xp_for_next,
        "progress_percentage": progress_pct
    }
    
    print(f"📊 Level progress for user {user_id}: {result}")
    return result
