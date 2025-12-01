from sqlalchemy.orm import Session
from app import models
from typing import Optional, Dict, List
from datetime import datetime
import random

def create_mystery_box(db: Session, user_id: int, box_type: str, earned_from: str) -> models.MysteryBox:
    """Create a new mystery box for user"""
    box = models.MysteryBox(
        user_id=user_id,
        box_type=box_type,
        earned_from=earned_from,
        is_opened=False
    )
    db.add(box)
    db.commit()
    db.refresh(box)
    return box

def get_unopened_boxes(db: Session, user_id: int) -> List[models.MysteryBox]:
    """Get all unopened boxes for user"""
    return db.query(models.MysteryBox).filter(
        models.MysteryBox.user_id == user_id,
        models.MysteryBox.is_opened == False
    ).all()

def open_mystery_box(db: Session, user_id: int, box_id: int) -> Optional[Dict]:
    """Open a mystery box and generate random reward"""
    box = db.query(models.MysteryBox).filter(
        models.MysteryBox.id == box_id,
        models.MysteryBox.user_id == user_id,
        models.MysteryBox.is_opened == False
    ).first()
    
    if not box:
        return None
    
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    # Define reward pools by box type
    reward_pools = {
        "bronze": {
            "xp": {"min": 10, "max": 30, "weight": 70},
            "pet": {"weight": 10},
            "cosmetic": {"weight": 20}
        },
        "silver": {
            "xp": {"min": 30, "max": 75, "weight": 50},
            "pet": {"weight": 25},
            "cosmetic": {"weight": 25}
        },
        "gold": {
            "xp": {"min": 75, "max": 150, "weight": 30},
            "pet": {"weight": 35},
            "cosmetic": {"weight": 35}
        },
        "legendary": {
            "xp": {"min": 150, "max": 300, "weight": 20},
            "pet": {"weight": 40},
            "cosmetic": {"weight": 40}
        }
    }
    
    pool = reward_pools.get(box.box_type, reward_pools["bronze"])
    
    # Weighted random selection
    reward_types = ["xp", "pet", "cosmetic"]
    weights = [pool["xp"]["weight"], pool["pet"]["weight"], pool["cosmetic"]["weight"]]
    reward_type = random.choices(reward_types, weights=weights)[0]
    
    reward_data = {}
    
    if reward_type == "xp":
        xp_amount = random.randint(pool["xp"]["min"], pool["xp"]["max"])
        user.xp += xp_amount
        box.reward_type = "xp"
        box.reward_amount = xp_amount
        reward_data = {
            "type": "xp",
            "amount": xp_amount,
            "message": f"You received {xp_amount} XP! ⭐"
        }
    
    elif reward_type == "pet":
        # Try to unlock a random pet user doesn't have
        unlocked_pet_ids = [up.pet_id for up in db.query(models.UserPet).filter(
            models.UserPet.user_id == user_id
        ).all()]
        
        available_pets = db.query(models.Pet).filter(
            models.Pet.unlock_level <= user.level + 5,  # Allow pets slightly above level
            ~models.Pet.id.in_(unlocked_pet_ids) if unlocked_pet_ids else True
        ).all()
        
        if available_pets:
            pet = random.choice(available_pets)
            user_pet = models.UserPet(
                user_id=user_id,
                pet_id=pet.id
            )
            db.add(user_pet)
            box.reward_type = "pet"
            box.reward_id = pet.id
            reward_data = {
                "type": "pet",
                "pet": {
                    "id": pet.id,
                    "name": pet.name,
                    "emoji": pet.emoji,
                    "rarity": pet.rarity
                },
                "message": f"You unlocked a new pet: {pet.name} {pet.emoji}!"
            }
        else:
            # Fallback to XP if no pets available
            xp_amount = random.randint(pool["xp"]["min"], pool["xp"]["max"])
            user.xp += xp_amount
            box.reward_type = "xp"
            box.reward_amount = xp_amount
            reward_data = {
                "type": "xp",
                "amount": xp_amount,
                "message": f"You received {xp_amount} XP! ⭐"
            }
    
    elif reward_type == "cosmetic":
        # Try to unlock a random reward user doesn't have
        unlocked_reward_ids = [ur.reward_id for ur in db.query(models.UserReward).filter(
            models.UserReward.user_id == user_id
        ).all()]
        
        available_rewards = db.query(models.Reward).filter(
            models.Reward.required_level <= user.level + 5,
            ~models.Reward.id.in_(unlocked_reward_ids) if unlocked_reward_ids else True
        ).all()
        
        if available_rewards:
            reward = random.choice(available_rewards)
            user_reward = models.UserReward(
                user_id=user_id,
                reward_id=reward.id
            )
            db.add(user_reward)
            box.reward_type = "cosmetic"
            box.reward_id = reward.id
            reward_data = {
                "type": "cosmetic",
                "cosmetic": {
                    "id": reward.id,
                    "name": reward.name,
                    "category": reward.category,
                    "rarity": reward.rarity
                },
                "message": f"You unlocked: {reward.name}!"
            }
        else:
            # Fallback to XP if no cosmetics available
            xp_amount = random.randint(pool["xp"]["min"], pool["xp"]["max"])
            user.xp += xp_amount
            box.reward_type = "xp"
            box.reward_amount = xp_amount
            reward_data = {
                "type": "xp",
                "amount": xp_amount,
                "message": f"You received {xp_amount} XP! ⭐"
            }
    
    # Mark box as opened
    box.is_opened = True
    box.opened_at = datetime.utcnow()
    
    db.commit()
    
    return {
        "success": True,
        "box_type": box.box_type,
        "reward": reward_data
    }

def award_box_for_milestone(db: Session, user_id: int, milestone_type: str) -> Optional[models.MysteryBox]:
    """Award a mystery box for achieving milestones"""
    box_types = {
        "daily_7": "bronze",
        "daily_30": "silver",
        "level_5": "silver",
        "level_10": "gold",
        "level_25": "legendary",
        "achievement": "bronze",
        "quest_weekly": "silver"
    }
    
    box_type = box_types.get(milestone_type, "bronze")
    return create_mystery_box(db, user_id, box_type, milestone_type)
