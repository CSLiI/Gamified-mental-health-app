from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models
from app.database import get_db
from app.CRUD import comeback_rewards

router = APIRouter(prefix="/comeback", tags=["comeback"])

@router.get("/check")
def check_comeback_reward(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Check and claim comeback reward"""
    result = comeback_rewards.check_comeback_reward(db, current_user.id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return result

@router.post("/update-activity")
def update_last_active(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update user's last active timestamp"""
    success = comeback_rewards.update_last_active(db, current_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return {"success": True, "message": "Activity updated"}
