from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models
from app.database import get_db
from app.CRUD import mystery_boxes

router = APIRouter(prefix="/mystery-boxes", tags=["mystery-boxes"])

@router.get("/unopened")
def get_unopened_boxes(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get user's unopened mystery boxes"""
    boxes = mystery_boxes.get_unopened_boxes(db, current_user.id)
    
    return {
        "count": len(boxes),
        "boxes": [
            {
                "id": box.id,
                "box_type": box.box_type,
                "earned_from": box.earned_from,
                "created_at": box.created_at
            }
            for box in boxes
        ]
    }

@router.post("/open/{box_id}")
def open_box(
    box_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Open a mystery box"""
    result = mystery_boxes.open_mystery_box(db, current_user.id, box_id)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mystery box not found or already opened"
        )
    
    return result
