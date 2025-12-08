from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models import User, BuiltinUserReward, BuiltinEquippedReward
from datetime import datetime


def get_user_purchased_rewards(db: Session, user_id: int):
    """Get all builtin rewards the user has purchased"""
    return db.query(BuiltinUserReward).filter(
        BuiltinUserReward.user_id == user_id
    ).all()


def get_user_equipped_rewards(db: Session, user_id: int):
    """Get all builtin rewards the user currently has equipped"""
    return db.query(BuiltinEquippedReward).filter(
        BuiltinEquippedReward.user_id == user_id
    ).all()


def get_user_xp_spent(db: Session, user_id: int) -> int:
    """Get total XP spent on builtin rewards"""
    user = db.query(User).filter(User.id == user_id).first()
    return user.builtin_xp_spent if user else 0


def purchase_builtin_reward(db: Session, user_id: int, reward_id: int, category: str, xp_cost: int):
    """Purchase a builtin reward"""
    # Check if user has enough XP
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return None
    
    available_xp = user.xp - user.builtin_xp_spent
    if available_xp < xp_cost:
        raise ValueError("Insufficient XP")
    
    # Check if already purchased
    existing = db.query(BuiltinUserReward).filter(
        and_(
            BuiltinUserReward.user_id == user_id,
            BuiltinUserReward.reward_id == reward_id
        )
    ).first()
    
    if existing:
        raise ValueError("Reward already purchased")
    
    # Create purchase record
    purchase = BuiltinUserReward(
        user_id=user_id,
        reward_id=reward_id,
        category=category,
        purchased_at=datetime.utcnow()
    )
    db.add(purchase)
    
    # Update user's spent XP
    user.builtin_xp_spent += xp_cost
    
    db.commit()
    db.refresh(purchase)
    db.refresh(user)
    
    return purchase


def equip_builtin_reward(db: Session, user_id: int, reward_id: int, category: str):
    """Equip a builtin reward (unequips other items in same category)"""
    # Check if user owns this reward
    owned = db.query(BuiltinUserReward).filter(
        and_(
            BuiltinUserReward.user_id == user_id,
            BuiltinUserReward.reward_id == reward_id
        )
    ).first()
    
    if not owned:
        raise ValueError("Reward not purchased")
    
    # Unequip any existing item in this category
    db.query(BuiltinEquippedReward).filter(
        and_(
            BuiltinEquippedReward.user_id == user_id,
            BuiltinEquippedReward.category == category
        )
    ).delete()
    
    # Equip the new item
    equipped = BuiltinEquippedReward(
        user_id=user_id,
        reward_id=reward_id,
        category=category,
        equipped_at=datetime.utcnow()
    )
    db.add(equipped)
    db.commit()
    db.refresh(equipped)
    
    return equipped


def unequip_builtin_reward(db: Session, user_id: int, reward_id: int):
    """Unequip a specific builtin reward"""
    result = db.query(BuiltinEquippedReward).filter(
        and_(
            BuiltinEquippedReward.user_id == user_id,
            BuiltinEquippedReward.reward_id == reward_id
        )
    ).delete()
    
    db.commit()
    return result > 0


def sync_builtin_rewards(db: Session, user_id: int, purchased_data: list, equipped_data: list, xp_spent: int):
    """Sync builtin rewards from frontend to backend (migration helper)"""
    # Clear existing data for this user
    db.query(BuiltinUserReward).filter(BuiltinUserReward.user_id == user_id).delete()
    db.query(BuiltinEquippedReward).filter(BuiltinEquippedReward.user_id == user_id).delete()
    
    # Add purchased items
    for item in purchased_data:
        purchase = BuiltinUserReward(
            user_id=user_id,
            reward_id=item['reward_id'],
            category=item['category'],
            purchased_at=datetime.utcnow()
        )
        db.add(purchase)
    
    # Add equipped items
    for item in equipped_data:
        equipped = BuiltinEquippedReward(
            user_id=user_id,
            reward_id=item['reward_id'],
            category=item['category'],
            equipped_at=datetime.utcnow()
        )
        db.add(equipped)
    
    # Update XP spent
    user = db.query(User).filter(User.id == user_id).first()
    if user:
        user.builtin_xp_spent = xp_spent
    
    db.commit()
    
    return True
