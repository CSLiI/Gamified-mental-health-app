from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import rewards as reward_crud

router = APIRouter(prefix="/rewards", tags=["Rewards"])

# ==================== Reward Management ====================
@router.post("/", response_model=schemas.Reward, status_code=status.HTTP_201_CREATED)
def create_reward(
    reward: schemas.RewardCreate,
    db: Session = Depends(get_db)
):
    """Create a new reward (admin only)"""
    return reward_crud.create_reward(db, reward)

@router.get("/", response_model=List[schemas.Reward])
def get_all_rewards(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all available rewards"""
    return reward_crud.get_all_rewards(db, skip, limit)

@router.get("/category/{category}", response_model=List[schemas.Reward])
def get_rewards_by_category(
    category: str,
    db: Session = Depends(get_db)
):
    """Get rewards by category"""
    return reward_crud.get_rewards_by_category(db, category)

@router.get("/rarity/{rarity}", response_model=List[schemas.Reward])
def get_rewards_by_rarity(
    rarity: str,
    db: Session = Depends(get_db)
):
    """Get rewards by rarity"""
    return reward_crud.get_rewards_by_rarity(db, rarity)

@router.get("/{reward_id}", response_model=schemas.Reward)
def get_reward(
    reward_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific reward"""
    reward = reward_crud.get_reward(db, reward_id)
    if not reward:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reward not found"
        )
    return reward

# ==================== User Reward Routes ====================
@router.get("/me/rewards", response_model=List[schemas.UserReward])
def get_my_rewards(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all rewards unlocked by current user"""
    return reward_crud.get_user_rewards(db, current_user.id)

@router.get("/me/available", response_model=List[schemas.Reward])
def get_available_rewards(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get rewards current user can afford"""
    return reward_crud.get_available_rewards(db, current_user.xp)

@router.post("/me/unlock/{reward_id}")
def unlock_reward(
    reward_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Unlock a reward by spending XP"""
    result = reward_crud.unlock_reward_for_user(db, current_user.id, reward_id)
    
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )
    
    return result

@router.post("/me/equip/{reward_id}", response_model=schemas.UserReward)
def equip_my_reward(
    reward_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Equip a reward"""
    user_reward = reward_crud.equip_reward(db, current_user.id, reward_id)
    if not user_reward:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reward not found or not unlocked"
        )
    return user_reward

@router.post("/me/unequip/{reward_id}", response_model=schemas.UserReward)
def unequip_my_reward(
    reward_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Unequip a reward"""
    user_reward = reward_crud.unequip_reward(db, current_user.id, reward_id)
    if not user_reward:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reward not found"
        )
    return user_reward

@router.get("/me/equipped", response_model=List[schemas.UserReward])
def get_equipped_rewards(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all currently equipped rewards"""
    return reward_crud.get_equipped_rewards(db, current_user.id)

@router.get("/me/collection-stats", response_model=schemas.CollectionStats)
def get_my_collection_stats(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get collection statistics for current user"""
    return reward_crud.get_user_collection_stats(db, current_user.id)