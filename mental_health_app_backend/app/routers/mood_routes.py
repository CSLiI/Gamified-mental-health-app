from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import moods as mood_crud

router = APIRouter(prefix="/moods", tags=["Moods"])

@router.post("/", response_model=schemas.MoodLog, status_code=status.HTTP_201_CREATED)
def create_mood_entry(
    mood: schemas.MoodLogCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new mood log entry"""
    result = mood_crud.create_mood_log(db, current_user.id, mood)
    
    # Check for achievements after logging mood
    from app.CRUD import achievements as achievement_crud
    achievement_crud.check_mood_tracking_achievements(db, current_user.id)
    achievement_crud.check_consistency_achievements(db, current_user.id)
    
    return result

@router.get("/", response_model=List[schemas.MoodLog])
def get_mood_history(
    skip: int = 0,
    limit: int = 100,
    days: Optional[int] = None,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return mood_crud.get_mood_logs(db, current_user.id, skip, limit, days)

@router.get("/statistics")
def get_mood_stats(
    days: int = 7,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    return mood_crud.get_mood_statistics(db, current_user.id, days)

@router.get("/{mood_id}", response_model=schemas.MoodLog)
def get_mood_entry(
    mood_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    mood_log = mood_crud.get_mood_log(db, mood_id)
    if not mood_log or mood_log.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mood log not found"
        )
    return mood_log

@router.put("/{mood_id}", response_model=schemas.MoodLog)
def update_mood_entry(
    mood_id: int,
    mood_update: schemas.MoodLogBase,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    mood_log = mood_crud.get_mood_log(db, mood_id)
    if not mood_log or mood_log.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mood log not found"
        )
    
    updates = mood_update.dict(exclude_unset=True)
    return mood_crud.update_mood_log(db, mood_id, updates)

@router.delete("/{mood_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_mood_entry(
    mood_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    mood_log = mood_crud.get_mood_log(db, mood_id)
    if not mood_log or mood_log.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mood log not found"
        )
    
    mood_crud.delete_mood_log(db, mood_id)
    return None