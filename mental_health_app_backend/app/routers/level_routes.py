from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models
from app.database import get_db
from app.CRUD import level_system

router = APIRouter(prefix="/level", tags=["level"])

@router.get("/check")
def check_level_up(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Check if user leveled up"""
    result = level_system.check_level_up(db, current_user.id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return result

@router.get("/progress")
def get_level_progress(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's level progress"""
    progress = level_system.get_level_progress(db, current_user.id)
    
    if not progress:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return progress
