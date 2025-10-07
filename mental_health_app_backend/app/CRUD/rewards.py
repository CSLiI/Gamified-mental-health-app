from sqlalchemy.orm import Session
from app import models, schemas
from typing import List, Optional

# ==================== REWARD CRUD ====================
def create_reward(db: Session, reward: schemas.RewardCreate):
    """Create a new reward"""
    db_reward = models.Reward(
        name=reward.name,
        description=reward.description,
        category=reward.category,
        image_url=reward.image_url,
        cost_xp=reward.cost_xp,
        rarity=reward.rarity,
        is_limited=reward.is_limited
    )
    db.add(db_reward)
    db.commit()
    db.refresh(db_reward)
    return db_reward

def get_reward(db: Session, reward_id: int):
    """Get reward by ID"""
    return db.query(models.Reward).filter(models.Reward.id == reward_id).first()

def get_all_rewards(db: Session, skip: int = 0, limit: int = 100):
    """Get all rewards"""
    return db.query(models.Reward).offset(skip).limit(limit).all()

def get_rewards_by_category(db: Session, category: str):
    """Get rewards by category"""
    return db.query(models.Reward).filter(models.Reward.category == category).all()

def get_rewards_by_rarity(db: Session, rarity: str):
    """Get rewards by rarity"""
    return db.query(models.Reward).filter(models.Reward.rarity == rarity).all()

def get_available_rewards(db: Session, user_xp: int):
    """Get rewards user can afford with their XP"""
    return db.query(models.Reward).filter(models.Reward.cost_xp <= user_xp).all()

# ==================== USER REWARD OPERATIONS ====================
def unlock_reward_for_user(db: Session, user_id: int, reward_id: int):
    """Unlock a reward for a user (spend XP)"""
    from app.CRUD import users as user_crud
    
    # Check if already unlocked
    existing = db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id,
        models.UserReward.reward_id == reward_id
    ).first()
    
    if existing:
        return {"success": False, "message": "Reward already unlocked"}
    
    # Get reward and user
    reward = get_reward(db, reward_id)
    user = user_crud.get_user(db, user_id)
    
    if not reward:
        return {"success": False, "message": "Reward not found"}
    
    if not user:
        return {"success": False, "message": "User not found"}
    
    # Check if user has enough XP
    if user.xp < reward.cost_xp:
        return {"success": False, "message": "Insufficient XP"}
    
    # Deduct XP
    user.xp -= reward.cost_xp
    
    # Create user reward
    user_reward = models.UserReward(
        user_id=user_id,
        reward_id=reward_id,
        is_equipped=False
    )
    db.add(user_reward)
    db.commit()
    db.refresh(user_reward)
    
    return {"success": True, "user_reward": user_reward, "remaining_xp": user.xp}

def get_user_rewards(db: Session, user_id: int):
    """Get all rewards unlocked by a user"""
    return db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id
    ).all()

def equip_reward(db: Session, user_id: int, reward_id: int):
    """Equip a reward (set as active)"""
    user_reward = db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id,
        models.UserReward.reward_id == reward_id
    ).first()
    
    if not user_reward:
        return None
    
    # Get reward to check category
    reward = get_reward(db, reward_id)
    
    # Unequip other rewards in the same category
    db.query(models.UserReward).join(models.Reward).filter(
        models.UserReward.user_id == user_id,
        models.Reward.category == reward.category,
        models.UserReward.id != user_reward.id
    ).update({"is_equipped": False})
    
    # Equip this reward
    user_reward.is_equipped = True
    db.commit()
    db.refresh(user_reward)
    
    return user_reward

def unequip_reward(db: Session, user_id: int, reward_id: int):
    """Unequip a reward"""
    user_reward = db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id,
        models.UserReward.reward_id == reward_id
    ).first()
    
    if not user_reward:
        return None
    
    user_reward.is_equipped = False
    db.commit()
    db.refresh(user_reward)
    
    return user_reward

def get_equipped_rewards(db: Session, user_id: int):
    """Get all currently equipped rewards for a user"""
    return db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id,
        models.UserReward.is_equipped == True
    ).all()

def get_user_collection_stats(db: Session, user_id: int):
    """Get statistics about user's reward collection"""
    total_rewards = db.query(models.Reward).count()
    user_rewards_count = db.query(models.UserReward).filter(
        models.UserReward.user_id == user_id
    ).count()
    
    # Count by category
    categories = db.query(models.Reward.category).distinct().all()
    category_stats = {}
    
    for (category,) in categories:
        total_in_category = db.query(models.Reward).filter(
            models.Reward.category == category
        ).count()
        
        user_has_in_category = db.query(models.UserReward).join(models.Reward).filter(
            models.UserReward.user_id == user_id,
            models.Reward.category == category
        ).count()
        
        category_stats[category] = {
            "unlocked": user_has_in_category,
            "total": total_in_category,
            "percentage": round((user_has_in_category / total_in_category * 100), 2) if total_in_category > 0 else 0
        }
    
    return {
        "total_unlocked": user_rewards_count,
        "total_available": total_rewards,
        "completion_percentage": round((user_rewards_count / total_rewards * 100), 2) if total_rewards > 0 else 0,
        "by_category": category_stats
    }