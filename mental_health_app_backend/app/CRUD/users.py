from sqlalchemy.orm import Session
from app import models, schemas
from typing import Optional
from datetime import date

# ==================== CREATE ====================
def create_user(db: Session, user: schemas.UserCreate):
    """Create a new user"""
    db_user = models.User(
        first_name=user.first_name,
        last_name=user.last_name,
        email=user.email,
        password_hash=user.password_hash,
        date_of_birth=user.date_of_birth,
        gender=user.gender
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# ==================== READ ====================
def get_user(db: Session, user_id: int):
    """Get user by ID"""
    return db.query(models.User).filter(models.User.id == user_id).first()

def get_user_by_email(db: Session, email: str):
    """Get user by email"""
    return db.query(models.User).filter(models.User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100):
    """Get all users with pagination"""
    return db.query(models.User).offset(skip).limit(limit).all()

# ==================== UPDATE ====================
def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    """Update user information"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    update_data = user_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(user, key, value)
    
    db.commit()
    db.refresh(user)
    return user

def update_user_xp(db: Session, user_id: int, xp_gained: int):
    """Add XP to user and handle level ups"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    # Add XP (cumulative system)
    user.xp += xp_gained
    db.commit()
    
    # Check for level up using centralized logic
    # Import inside function to avoid circular imports if any
    from app.CRUD import level_system
    level_system.check_level_up(db, user_id)
    
    db.refresh(user)
    return user

# ==================== DELETE ====================
def delete_user(db: Session, user_id: int):
    """Delete a user (will cascade to related records)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        db.delete(user)
        db.commit()
    return user

# ==================== USER INTERESTS ====================
def add_user_interest(db: Session, user_id: int, interest_id: int):
    """Add an interest to a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    interest = db.query(models.Interest).filter(models.Interest.id == interest_id).first()
    
    if user and interest:
        user.user_interests.append(interest)
        db.commit()
        return True
    return False

def remove_user_interest(db: Session, user_id: int, interest_id: int):
    """Remove an interest from a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    interest = db.query(models.Interest).filter(models.Interest.id == interest_id).first()
    
    if user and interest and interest in user.user_interests:
        user.user_interests.remove(interest)
        db.commit()
        return True
    return False

def get_user_interests(db: Session, user_id: int):
    """Get all interests for a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user:
        return user.user_interests
    return []

def update_user_interests(db: Session, user_id: int, interest_ids: list[int]):
    """Update user's interests (replaces all existing interests)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return False
    
    # Clear existing interests
    user.user_interests.clear()
    
    # Add new interests
    for interest_id in interest_ids:
        interest = db.query(models.Interest).filter(models.Interest.id == interest_id).first()
        if interest:
            user.user_interests.append(interest)
    
    db.commit()
    return True


# ==================== BIRTHDAY FUNCTIONS ====================
def get_users_with_birthday_today(db: Session):
    """Get all users whose birthday is today"""
    today = date.today()
    
    # Query users where month and day match today
    users = db.query(models.User).filter(
        models.User.date_of_birth.isnot(None)
    ).all()
    
    # Filter in Python to check month and day
    birthday_users = [
        user for user in users 
        if user.date_of_birth.month == today.month and 
           user.date_of_birth.day == today.day
    ]
    
    return birthday_users

def check_and_create_birthday_notification(db: Session, user_id: int):
    """Check if user has birthday today and create notification if needed"""
    from app.CRUD import notifications as notif_crud
    from datetime import datetime
    
    user = get_user(db, user_id)
    if not user or not user.is_birthday_today():
        return None
    
    # Check if birthday notification already sent today
    today_start = datetime.combine(date.today(), datetime.min.time())
    existing_notification = db.query(models.Notification).filter(
        models.Notification.user_id == user_id,
        models.Notification.scheduled_time >= today_start,
        models.Notification.message.like('%birthday%')
    ).first()
    
    if existing_notification:
        return existing_notification
    
    # Create birthday notification
    birthday_message = f"🎉 Happy Birthday, {user.first_name}! You're now {user.age} years old. Wishing you a wonderful day filled with joy!"
    
    notification = models.Notification(
        user_id=user_id,
        message=birthday_message,
        scheduled_time=datetime.utcnow(),
        is_sent=False
    )
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    return notification
