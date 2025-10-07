from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import journals as journal_crud

router = APIRouter(prefix="/journals", tags=["Journals"])

@router.post("/", response_model=schemas.JournalEntry, status_code=status.HTTP_201_CREATED)
def create_journal_entry(
    entry: schemas.JournalEntryCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new journal entry"""
    return journal_crud.create_journal_entry(db, current_user.id, entry)

@router.get("/", response_model=List[schemas.JournalEntry])
def get_journal_entries(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all journal entries for current user"""
    return journal_crud.get_journal_entries(db, current_user.id, skip, limit)

@router.get("/search", response_model=List[schemas.JournalEntry])
def search_journal_entries(
    q: str = Query(..., min_length=1, description="Search term"),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Search journal entries by title or content"""
    return journal_crud.search_journal_entries(db, current_user.id, q)

@router.get("/{entry_id}", response_model=schemas.JournalEntry)
def get_journal_entry(
    entry_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific journal entry"""
    entry = journal_crud.get_journal_entry(db, entry_id)
    if not entry or entry.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found"
        )
    return entry

@router.put("/{entry_id}", response_model=schemas.JournalEntry)
def update_journal_entry(
    entry_id: int,
    entry_update: schemas.JournalEntryUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update a journal entry"""
    entry = journal_crud.get_journal_entry(db, entry_id)
    if not entry or entry.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found"
        )
    
    return journal_crud.update_journal_entry(db, entry_id, entry_update)

@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_journal_entry(
    entry_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a journal entry"""
    entry = journal_crud.get_journal_entry(db, entry_id)
    if not entry or entry.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Journal entry not found"
        )
    
    journal_crud.delete_journal_entry(db, entry_id)
    return None