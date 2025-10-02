from sqlalchemy.orm import Session
from app import models, schemas
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

def create_mood_log(db: Session, user_id: int, mood_log: schemas.MoodLogCreate):
    """Create a mood log for a user"""
    db_mood = models.MoodLog(
        user_id=user_id,
        mood=mood_log.mood,
        note=mood_log.note
    )
    db.add(db_mood)
    db.commit()
    db.refresh(db_mood)
    return db_mood

def get_mood_logs(db: Session, user_id: int, skip: int = 0, limit: int = 100, days: Optional[int] = None):
    """Get all mood logs for a user"""
    query = db.query(models.MoodLog).filter(models.MoodLog.user_id == user_id)
    
    if days:
        date_from = datetime.utcnow() - timedelta(days=days)
        query = query.filter(models.MoodLog.logged_at >= date_from)
    
    return query.order_by(models.MoodLog.logged_at.desc()).offset(skip).limit(limit).all()

def get_mood_log(db: Session, mood_log_id: int):
    """Get a specific mood log"""
    return db.query(models.MoodLog).filter(models.MoodLog.id == mood_log_id).first()

def update_mood_log(db: Session, mood_log_id: int, updates: dict):
    """Update a mood log"""
    mood_log = db.query(models.MoodLog).filter(models.MoodLog.id == mood_log_id).first()
    if not mood_log:
        return None
    
    for key, value in updates.items():
        setattr(mood_log, key, value)
    
    db.commit()
    db.refresh(mood_log)
    return mood_log

def delete_mood_log(db: Session, mood_log_id: int):
    """Delete a mood log"""
    mood_log = db.query(models.MoodLog).filter(models.MoodLog.id == mood_log_id).first()
    if mood_log:
        db.delete(mood_log)
        db.commit()
    return mood_log

def get_mood_statistics(db: Session, user_id: int, days: int = 7):
    """Get mood distribution for the past N days"""
    date_from = datetime.utcnow() - timedelta(days=days)
    
    # Get mood counts using SQL aggregation
    mood_counts = db.query(
        models.MoodLog.mood,
        func.count(models.MoodLog.id).label('count')
    ).filter(
        models.MoodLog.user_id == user_id,
        models.MoodLog.logged_at >= date_from
    ).group_by(models.MoodLog.mood).all()
    
    mood_distribution = {mood.value: count for mood, count in mood_counts}
    total_entries = sum(mood_distribution.values())
    
    return {
        "total_entries": total_entries,
        "mood_distribution": mood_distribution,
        "period_days": days
    }