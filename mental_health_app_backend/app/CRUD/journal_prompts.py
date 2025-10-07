from sqlalchemy.orm import Session
from app import models, schemas
from typing import List, Optional
import random

# ==================== CREATE ====================
def create_journal_prompt(db: Session, prompt: schemas.JournalPromptCreate):
    """Create a new journal prompt"""
    db_prompt = models.JournalPrompt(
        prompt_text=prompt.prompt_text,
        mood=prompt.mood,
        category=prompt.category,
        is_active=prompt.is_active
    )
    db.add(db_prompt)
    db.commit()
    db.refresh(db_prompt)
    return db_prompt

def create_bulk_prompts(db: Session, prompts: List[schemas.JournalPromptCreate]):
    """Create multiple prompts at once"""
    created_prompts = []
    for prompt in prompts:
        db_prompt = create_journal_prompt(db, prompt)
        created_prompts.append(db_prompt)
    return created_prompts

# ==================== READ ====================
def get_journal_prompt(db: Session, prompt_id: int):
    """Get a specific journal prompt"""
    return db.query(models.JournalPrompt).filter(models.JournalPrompt.id == prompt_id).first()

def get_all_prompts(db: Session, active_only: bool = True, skip: int = 0, limit: int = 100):
    """Get all journal prompts"""
    query = db.query(models.JournalPrompt)
    
    if active_only:
        query = query.filter(models.JournalPrompt.is_active == True)
    
    return query.offset(skip).limit(limit).all()

def get_prompts_by_mood(db: Session, mood: str):
    """Get prompts for a specific mood"""
    return db.query(models.JournalPrompt).filter(
        models.JournalPrompt.mood == mood,
        models.JournalPrompt.is_active == True
    ).all()

def get_prompts_by_category(db: Session, category: str):
    """Get prompts by category"""
    return db.query(models.JournalPrompt).filter(
        models.JournalPrompt.category == category,
        models.JournalPrompt.is_active == True
    ).all()

def get_random_prompt(db: Session, mood: Optional[str] = None, category: Optional[str] = None):
    """Get a random journal prompt, optionally filtered by mood or category"""
    query = db.query(models.JournalPrompt).filter(models.JournalPrompt.is_active == True)
    
    if mood:
        query = query.filter(models.JournalPrompt.mood == mood)
    
    if category:
        query = query.filter(models.JournalPrompt.category == category)
    
    prompts = query.all()
    
    if not prompts:
        return None
    
    return random.choice(prompts)

def get_daily_prompt(db: Session, user_id: int):
    """Get a personalized daily prompt based on user's recent mood"""
    from app.CRUD import moods as mood_crud
    from datetime import datetime, timedelta
    
    # Get user's most recent mood
    recent_moods = mood_crud.get_mood_logs(db, user_id, skip=0, limit=1)
    
    if recent_moods:
        latest_mood = recent_moods[0].mood.value
        return get_random_prompt(db, mood=latest_mood)
    
    # If no recent mood, return a general prompt
    return get_random_prompt(db)

# ==================== UPDATE ====================
def update_journal_prompt(db: Session, prompt_id: int, prompt_update: schemas.JournalPromptUpdate):
    """Update a journal prompt"""
    prompt = get_journal_prompt(db, prompt_id)
    if not prompt:
        return None
    
    update_data = prompt_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(prompt, key, value)
    
    db.commit()
    db.refresh(prompt)
    return prompt

def deactivate_prompt(db: Session, prompt_id: int):
    """Deactivate a prompt (soft delete)"""
    prompt = get_journal_prompt(db, prompt_id)
    if prompt:
        prompt.is_active = False
        db.commit()
        db.refresh(prompt)
    return prompt

def activate_prompt(db: Session, prompt_id: int):
    """Activate a prompt"""
    prompt = get_journal_prompt(db, prompt_id)
    if prompt:
        prompt.is_active = True
        db.commit()
        db.refresh(prompt)
    return prompt

# ==================== DELETE ====================
def delete_journal_prompt(db: Session, prompt_id: int):
    """Delete a journal prompt permanently"""
    prompt = get_journal_prompt(db, prompt_id)
    if prompt:
        db.delete(prompt)
        db.commit()
    return prompt

# ==================== SEED DATA ====================
def seed_default_prompts(db: Session):
    """Seed database with default journal prompts"""
    default_prompts = [
        # Happy prompts
        {"prompt_text": "What made you smile today?", "mood": "happy", "category": "gratitude"},
        {"prompt_text": "Describe a moment of joy you experienced recently.", "mood": "happy", "category": "reflection"},
        {"prompt_text": "What are three things you're grateful for right now?", "mood": "happy", "category": "gratitude"},
        
        # Sad prompts
        {"prompt_text": "What's weighing on your heart today?", "mood": "sad", "category": "reflection"},
        {"prompt_text": "Write a letter to yourself offering comfort.", "mood": "sad", "category": "cbt"},
        {"prompt_text": "What would you tell a friend feeling the way you do?", "mood": "sad", "category": "cbt"},
        
        # Anxious prompts
        {"prompt_text": "What worries are on your mind right now?", "mood": "anxious", "category": "reflection"},
        {"prompt_text": "List three things you can control in this situation.", "mood": "anxious", "category": "cbt"},
        {"prompt_text": "What evidence do you have that challenges your worry?", "mood": "anxious", "category": "cbt"},
        
        # Calm prompts
        {"prompt_text": "Describe the peaceful moment you're experiencing.", "mood": "calm", "category": "mindfulness"},
        {"prompt_text": "What brought you this sense of calm?", "mood": "calm", "category": "reflection"},
        {"prompt_text": "How can you maintain this peaceful feeling?", "mood": "calm", "category": "mindfulness"},
        
        # Angry prompts
        {"prompt_text": "What triggered this feeling of anger?", "mood": "angry", "category": "reflection"},
        {"prompt_text": "What do you need right now to feel better?", "mood": "angry", "category": "cbt"},
        {"prompt_text": "Write down your frustration without judgment.", "mood": "angry", "category": "reflection"},
        
        # Tired prompts
        {"prompt_text": "What has been draining your energy lately?", "mood": "tired", "category": "reflection"},
        {"prompt_text": "What would help you feel more rested?", "mood": "tired", "category": "cbt"},
        {"prompt_text": "List three ways you can prioritize rest today.", "mood": "tired", "category": "cbt"},
        
        # General prompts
        {"prompt_text": "What's one small step you can take towards your goals today?", "mood": None, "category": "reflection"},
        {"prompt_text": "Describe a challenge you overcame recently.", "mood": None, "category": "reflection"},
        {"prompt_text": "What lesson did you learn this week?", "mood": None, "category": "reflection"},
    ]
    
    created = []
    for prompt_data in default_prompts:
        prompt = schemas.JournalPromptCreate(**prompt_data, is_active=True)
        created.append(create_journal_prompt(db, prompt))
    
    return created