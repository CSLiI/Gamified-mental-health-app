from sqlalchemy.orm import Session
from app import models, schemas
from typing import Optional

# ==================== CREATE ====================
def create_journal_entry(db: Session, user_id: int, entry: schemas.JournalEntryCreate):
    """Create a new journal entry"""
    db_entry = models.JournalEntry(
        user_id=user_id,
        title=entry.title,
        content=entry.content
    )
    db.add(db_entry)
    db.commit()
    db.refresh(db_entry)
    return db_entry

# ==================== READ ====================
def get_journal_entry(db: Session, entry_id: int):
    """Get a specific journal entry"""
    return db.query(models.JournalEntry).filter(models.JournalEntry.id == entry_id).first()

def get_journal_entries(db: Session, user_id: int, skip: int = 0, limit: int = 100):
    """Get all journal entries for a user"""
    return db.query(models.JournalEntry).filter(
        models.JournalEntry.user_id == user_id
    ).order_by(models.JournalEntry.created_at.desc()).offset(skip).limit(limit).all()

def search_journal_entries(db: Session, user_id: int, search_term: str):
    """Search journal entries by title or content"""
    return db.query(models.JournalEntry).filter(
        models.JournalEntry.user_id == user_id,
        (models.JournalEntry.title.ilike(f'%{search_term}%')) |
        (models.JournalEntry.content.ilike(f'%{search_term}%'))
    ).order_by(models.JournalEntry.created_at.desc()).all()

# ==================== UPDATE ====================
def update_journal_entry(db: Session, entry_id: int, entry_update: schemas.JournalEntryUpdate):
    """Update a journal entry"""
    entry = db.query(models.JournalEntry).filter(models.JournalEntry.id == entry_id).first()
    if not entry:
        return None
    
    update_data = entry_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(entry, key, value)
    
    db.commit()
    db.refresh(entry)
    return entry

# ==================== DELETE ====================
def delete_journal_entry(db: Session, entry_id: int):
    """Delete a journal entry"""
    entry = db.query(models.JournalEntry).filter(models.JournalEntry.id == entry_id).first()