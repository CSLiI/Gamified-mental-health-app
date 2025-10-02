from sqlalchemy.orm import Session
from app import models, schemas
from datetime import datetime, timedelta
from typing import Optional

# ==================== CREATE ====================
def create_notification(db: Session, user_id: int, notification: schemas.NotificationCreate):
    """Create a new notification"""
    db_notification = models.Notification(
        user_id=user_id,
        message=notification.message,
        scheduled_time=notification.scheduled_time,
        is_sent=False
    )
    db.add(db_notification)
    db.commit()
    db.refresh(db_notification)
    return db_notification

# ==================== READ ====================
def get_notification(db: Session, notification_id: int):
    """Get a specific notification"""
    return db.query(models.Notification).filter(
        models.Notification.id == notification_id
    ).first()

def get_user_notifications(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    """Get all notifications for a user"""
    return db.query(models.Notification).filter(
        models.Notification.user_id == user_id
    ).order_by(models.Notification.scheduled_time.desc()).offset(skip).limit(limit).all()

def get_pending_notifications(db: Session, user_id: int):
    """Get unsent notifications for a user"""
    return db.query(models.Notification).filter(
        models.Notification.user_id == user_id,
        models.Notification.is_sent == False
    ).order_by(models.Notification.scheduled_time).all()

def get_notifications_to_send(db: Session):
    """Get all unsent notifications that are due to be sent"""
    current_time = datetime.utcnow()
    return db.query(models.Notification).filter(
        models.Notification.is_sent == False,
        models.Notification.scheduled_time <= current_time
    ).all()

# ==================== UPDATE ====================
def mark_notification_sent(db: Session, notification_id: int):
    """Mark a notification as sent"""
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id
    ).first()
    
    if notification:
        notification.is_sent = True
        db.commit()
        db.refresh(notification)
    
    return notification

# ==================== DELETE ====================
def delete_notification(db: Session, notification_id: int):
    """Delete a notification"""
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id
    ).first()
    if notification:
        db.delete(notification)
        db.commit()
    return notification

def delete_old_notifications(db: Session, days: int = 30):
    """Delete sent notifications older than specified days"""
    cutoff_date = datetime.utcnow() - timedelta(days=days)
    old_notifications = db.query(models.Notification).filter(
        models.Notification.is_sent == True,
        models.Notification.scheduled_time < cutoff_date
    ).delete()
    db.commit()
    return old_notifications
