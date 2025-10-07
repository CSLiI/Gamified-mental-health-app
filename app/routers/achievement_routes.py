from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import achievements as achievement_crud

router = APIRouter(prefix="/achievements", tags=["Achievements"])

# ==================== Achievement Management ====================
@router.post("/", response_model=schemas.Achievement, status_code=status.HTTP_201_CREATED)
def create_achievement(
    achievement: schemas.AchievementCreate,
    db: Session = Depends(get_db)
):
    """Create a new achievement (admin only)"""
    return achievement_crud.create_achievement(db, achievement)

@router.get("/", response_model=List[schemas.Achievement])
def get_all_achievements(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all available achievements"""
    return achievement_crud.get_all_achievements(db, skip, limit)

@router.get("/category/{category}", response_model=List[schemas.Achievement])
def get_achievements_by_category(
    category: str,
    db: Session = Depends(get_db)
):
    """Get achievements by category"""
    return achievement_crud.get_achievements_by_category(db, category)

@router.get("/{achievement_id}", response_model=schemas.Achievement)
def get_achievement(
    achievement_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific achievement"""
    achievement = achievement_crud.get_achievement(db, achievement_id)
    if not achievement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Achievement not found"
        )
    return achievement

# ==================== User Achievement Routes ====================
@router.get("/me/achievements", response_model=List[schemas.UserAchievement])
def get_my_achievements(
    claimed_only: bool = False,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all achievements for current user"""
    return achievement_crud.get_user_achievements(db, current_user.id, claimed_only)

@router.post("/me/check")
def check_my_achievements(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Check and award all eligible achievements for current user"""
    results = achievement_crud.check_all_achievements(db, current_user.id)
    return {
        "message": "Achievement check completed",
        "results": results
    }

@router.get("/me/streak")
def get_my_streak(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's streak"""
    streak = achievement_crud.calculate_user_streak(db, current_user.id)
    return {
        "user_id": current_user.id,
        "current_streak": streak,
        "message": f"You're on a {streak}-day streak!" if streak > 0 else "Start your streak today!"
    }