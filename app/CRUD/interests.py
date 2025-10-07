from sqlalchemy.orm import Session
from app import models, schemas
from typing import List, Optional

# ==================== CREATE ====================
def create_interest(db: Session, interest: schemas.InterestCreate):
    """Create a new interest"""
    existing = get_interest_by_name(db, interest.name)
    if existing:
        return existing
    
    db_interest = models.Interest(name=interest.name)
    db.add(db_interest)
    db.commit()
    db.refresh(db_interest)
    return db_interest

def create_bulk_interests(db: Session, interest_names: List[str]):
    """Create multiple interests at once"""
    created_interests = []
    for name in interest_names:
        interest = create_interest(db, schemas.InterestCreate(name=name))
        created_interests.append(interest)
    return created_interests

# ==================== READ ====================
def get_interest(db: Session, interest_id: int):
    """Get interest by ID"""
    return db.query(models.Interest).filter(models.Interest.id == interest_id).first()

def get_interest_by_name(db: Session, name: str):
    """Get interest by name"""
    return db.query(models.Interest).filter(models.Interest.name == name).first()

def get_all_interests(db: Session, skip: int = 0, limit: int = 100):
    """Get all interests"""
    return db.query(models.Interest).offset(skip).limit(limit).all()

def search_interests(db: Session, search_term: str):
    """Search interests by name"""
    return db.query(models.Interest).filter(
        models.Interest.name.ilike(f'%{search_term}%')
    ).all()

# ==================== UPDATE ====================
def update_interest(db: Session, interest_id: int, interest_update: schemas.InterestUpdate):
    """Update an interest"""
    interest = get_interest(db, interest_id)
    if not interest:
        return None
    
    update_data = interest_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(interest, key, value)
    
    db.commit()
    db.refresh(interest)
    return interest

# ==================== DELETE ====================
def delete_interest(db: Session, interest_id: int):
    """Delete an interest"""
    interest = get_interest(db, interest_id)
    if interest:
        db.delete(interest)
        db.commit()
    return interest

# ==================== STATISTICS ====================
def get_interest_user_count(db: Session, interest_id: int):
    """Get count of users who have a specific interest"""
    interest = get_interest(db, interest_id)
    if not interest:
        return 0
    return len(interest.users)

def get_popular_interests(db: Session, limit: int = 10):
    """Get most popular interests by user count"""
    interests = get_all_interests(db)
    interest_data = [
        {
            "interest": interest,
            "user_count": len(interest.users)
        }
        for interest in interests
    ]
    
    sorted_interests = sorted(interest_data, key=lambda x: x['user_count'], reverse=True)
    return sorted_interests[:limit]