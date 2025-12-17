from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth import get_current_user
from app.models import User
from app.schemas import (
    BuiltinRewardPurchase,
    BuiltinRewardEquip,
    BuiltinRewardsDataResponse,
    BuiltinUserRewardResponse,
    BuiltinEquippedRewardResponse
)
from app.CRUD import builtin_rewards as crud
from typing import List

router = APIRouter(prefix="/builtin-rewards", tags=["Builtin Rewards"])


@router.get("/me/data", response_model=BuiltinRewardsDataResponse)
def get_my_builtin_rewards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all builtin rewards data for current user"""
    purchased = crud.get_user_purchased_rewards(db, current_user.id)
    equipped = crud.get_user_equipped_rewards(db, current_user.id)
    xp_spent = crud.get_user_xp_spent(db, current_user.id)
    
    return {
        "purchased": purchased,
        "equipped": equipped,
        "xp_spent": xp_spent
    }


@router.get("/me/purchased", response_model=List[BuiltinUserRewardResponse])
def get_my_purchased_rewards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all purchased builtin rewards"""
    return crud.get_user_purchased_rewards(db, current_user.id)


@router.get("/me/equipped", response_model=List[BuiltinEquippedRewardResponse])
def get_my_equipped_rewards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all equipped builtin rewards"""
    return crud.get_user_equipped_rewards(db, current_user.id)


@router.post("/me/purchase", response_model=BuiltinUserRewardResponse)
def purchase_reward(
    purchase_data: BuiltinRewardPurchase,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Purchase a builtin reward with XP"""
    try:
        result = crud.purchase_builtin_reward(
            db,
            current_user.id,
            purchase_data.reward_id,
            purchase_data.category,
            purchase_data.xp_cost
        )
        if not result:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        return result
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/me/equip", response_model=BuiltinEquippedRewardResponse)
def equip_reward(
    equip_data: BuiltinRewardEquip,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Equip a builtin reward"""
    try:
        return crud.equip_builtin_reward(
            db,
            current_user.id,
            equip_data.reward_id,
            equip_data.category
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/me/unequip/{reward_id}")
def unequip_reward(
    reward_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Unequip a builtin reward"""
    success = crud.unequip_builtin_reward(db, current_user.id, reward_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Equipped reward not found"
        )
    return {"success": True, "message": "Reward unequipped"}


@router.post("/me/sync")
def sync_builtin_rewards(
    purchased: List[dict],
    equipped: List[dict],
    xp_spent: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Sync builtin rewards from frontend storage to backend (one-time migration)"""
    try:
        crud.sync_builtin_rewards(
            db,
            current_user.id,
            purchased,
            equipped,
            xp_spent
        )
        return {
            "success": True,
            "message": "Builtin rewards synced successfully"
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sync failed: {str(e)}"
        )
