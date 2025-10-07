from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import journal_prompts as prompt_crud

router = APIRouter(prefix="/journal-prompts", tags=["Journal Prompts"])

# ==================== Prompt Management ====================
@router.post("/", response_model=schemas.JournalPrompt, status_code=status.HTTP_201_CREATED)
def create_prompt(
    prompt: schemas.JournalPromptCreate,
    db: Session = Depends(get_db)
):
    """Create a new journal prompt"""
    return prompt_crud.create_journal_prompt(db, prompt)

@router.post("/bulk", response_model=List[schemas.JournalPrompt], status_code=status.HTTP_201_CREATED)
def create_bulk_prompts(
    prompts: List[schemas.JournalPromptCreate],
    db: Session = Depends(get_db)
):
    """Create multiple prompts at once"""
    return prompt_crud.create_bulk_prompts(db, prompts)

@router.post("/seed")
def seed_prompts(db: Session = Depends(get_db)):
    """Seed database with default prompts"""
    prompts = prompt_crud.seed_default_prompts(db)
    return {
        "message": f"Successfully seeded {len(prompts)} default prompts",
        "count": len(prompts)
    }

@router.get("/", response_model=List[schemas.JournalPrompt])
def get_all_prompts(
    active_only: bool = True,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all journal prompts"""
    return prompt_crud.get_all_prompts(db, active_only, skip, limit)

@router.get("/random", response_model=schemas.JournalPrompt)
def get_random_prompt(
    mood: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """Get a random journal prompt"""
    prompt = prompt_crud.get_random_prompt(db, mood, category)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No prompts found matching criteria"
        )
    return prompt

@router.get("/daily", response_model=schemas.JournalPrompt)
def get_daily_prompt(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get personalized daily prompt based on user's recent mood"""
    prompt = prompt_crud.get_daily_prompt(db, current_user.id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No prompts available"
        )
    return prompt

@router.get("/mood/{mood}", response_model=List[schemas.JournalPrompt])
def get_prompts_by_mood(
    mood: str,
    db: Session = Depends(get_db)
):
    """Get prompts for a specific mood"""
    return prompt_crud.get_prompts_by_mood(db, mood)

@router.get("/category/{category}", response_model=List[schemas.JournalPrompt])
def get_prompts_by_category(
    category: str,
    db: Session = Depends(get_db)
):
    """Get prompts by category"""
    return prompt_crud.get_prompts_by_category(db, category)

@router.get("/{prompt_id}", response_model=schemas.JournalPrompt)
def get_prompt(
    prompt_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific journal prompt"""
    prompt = prompt_crud.get_journal_prompt(db, prompt_id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prompt not found"
        )
    return prompt

@router.put("/{prompt_id}", response_model=schemas.JournalPrompt)
def update_prompt(
    prompt_id: int,
    prompt_update: schemas.JournalPromptUpdate,
    db: Session = Depends(get_db)
):
    """Update a journal prompt"""
    prompt = prompt_crud.update_journal_prompt(db, prompt_id, prompt_update)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prompt not found"
        )
    return prompt

@router.post("/{prompt_id}/deactivate", response_model=schemas.JournalPrompt)
def deactivate_prompt(
    prompt_id: int,
    db: Session = Depends(get_db)
):
    """Deactivate a prompt"""
    prompt = prompt_crud.deactivate_prompt(db, prompt_id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prompt not found"
        )
    return prompt

@router.post("/{prompt_id}/activate", response_model=schemas.JournalPrompt)
def activate_prompt(
    prompt_id: int,
    db: Session = Depends(get_db)
):
    """Activate a prompt"""
    prompt = prompt_crud.activate_prompt(db, prompt_id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prompt not found"
        )
    return prompt

@router.delete("/{prompt_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_prompt(
    prompt_id: int,
    db: Session = Depends(get_db)
):
    """Delete a journal prompt permanently"""
    prompt = prompt_crud.delete_journal_prompt(db, prompt_id)
    if not prompt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Prompt not found"
        )
    return None