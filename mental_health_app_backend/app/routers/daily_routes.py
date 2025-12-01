from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models, schemas
from app.database import get_db
from app.CRUD import daily_rewards

router = APIRouter(prefix="/daily", tags=["Daily Rewards"])

@router.get("/status", response_model=schemas.DailyStatusResponse)
def get_daily_status(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's daily check-in status"""
    daily_status = daily_rewards.get_user_daily_status(db, current_user.id)
    if not daily_status:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return daily_status

@router.post("/claim", response_model=schemas.DailyClaimResponse)
def claim_daily(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Claim daily reward"""
    result = daily_rewards.claim_daily_reward(db, current_user.id)
    
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )
    
    return result

@router.get("/calendar", response_model=schemas.DailyCalendarResponse)
def get_calendar(
    days: int = 30,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get daily check-in calendar"""
    calendar = daily_rewards.get_daily_calendar(db, current_user.id, days)
    if not calendar:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return calendar

@router.get("/streak-freeze", response_model=schemas.StreakFreezeResponse)
def get_freeze_status(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Check streak freeze availability"""
    freeze_status = daily_rewards.get_streak_freeze_status(db, current_user.id)
    if not freeze_status:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    return freeze_status

@router.post("/streak-freeze/use", response_model=schemas.StreakFreezeUseResponse)
def use_freeze(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Use streak freeze to protect streak"""
    result = daily_rewards.use_streak_freeze(db, current_user.id)
    
    if not result["success"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=result["message"]
        )
    
    return result
