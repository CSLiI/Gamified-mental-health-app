from sqlalchemy.orm import Session
from app import models
from datetime import datetime, timedelta
from typing import List, Optional
import random

def generate_daily_quests(db: Session, user_id: int, force_refresh: bool = False) -> List[models.Todo]:
    """Generate 3-5 daily quests for a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return []
    
    # Check if user already has quests for today
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Clean up any leftover daily quests from previous days (fixes overlapping issue)
    db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "daily",
        models.Todo.created_at < today_start
    ).delete(synchronize_session=False)

    if force_refresh:
        # Delete only INCOMPLETE daily quests for today (reset/reroll)
        # AND only if reward hasn't been claimed (Locked Slot Rule)
        db.query(models.Todo).filter(
            models.Todo.user_id == user_id,
            models.Todo.is_quest == True,
            models.Todo.quest_type == "daily",
            models.Todo.created_at >= today_start,
            models.Todo.is_completed == False,
            models.Todo.reward_claimed == False  # PROTECT claimed quests
        ).delete(synchronize_session=False)
        db.commit()
    
    existing_quests_objs = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "daily",
        models.Todo.created_at >= today_start
    ).all()
    
    existing_quests_count = len(existing_quests_objs)
    
    # If not forcing refresh and we have quests, return empty (already done)
    if not force_refresh and existing_quests_count > 0:
        return []
    
    # Quest templates
    quest_templates = [
        {
            "task": "Log your mood 3 times today",
            "category": models.QuestCategoryEnum.mood,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 15,
            "progress_total": 3
        },
        {
            "task": "Write a journal entry",
            "category": models.QuestCategoryEnum.journal,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 20,
            "progress_total": 1
        },
        {
            "task": "Complete 5 todos today",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 30,
            "progress_total": 5
        },
        {
            "task": "Maintain your daily streak",
            "category": models.QuestCategoryEnum.streak,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 10,
            "progress_total": 1
        },
        {
            "task": "Send encouragement to a friend",
            "category": models.QuestCategoryEnum.social,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 15,
            "progress_total": 1
        },
        {
            "task": "Log 2 different moods today",
            "category": models.QuestCategoryEnum.mood,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 25,
            "progress_total": 2
        },
        {
            "task": "Complete all your daily todos",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 50,
            "progress_total": 1
        },
        # Exercise Quests (Higher XP)
        {
            "task": "Go for a 20-minute walk",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 75,
            "progress_total": 1
        },
        {
            "task": "Do a quick 10-minute workout",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 80,
            "progress_total": 1
        },
        # Intellectual Quests (Higher XP)
        {
            "task": "Read a book for 15 minutes",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 70,
            "progress_total": 1
        },
        {
            "task": "Learn something new today",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 90,
            "progress_total": 1
        },
        # Mindfulness & Self-Care
        {
            "task": "Practice 5 minutes of deep breathing",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 20,
            "progress_total": 1
        },
        {
            "task": "Meditate for 10 minutes",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 40,
            "progress_total": 1
        },
        {
            "task": "Drink 8 glasses of water",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 35,
            "progress_total": 8
        },
        {
            "task": "Spend 1 hour without social media",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 60,
            "progress_total": 1
        },
        # Social & Gratitude
        {
            "task": "Call a family member",
            "category": models.QuestCategoryEnum.social,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 45,
            "progress_total": 1
        },
        {
            "task": "Write down 3 things you are grateful for",
            "category": models.QuestCategoryEnum.journal,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 25,
            "progress_total": 1
        },
        # Creative
        {
            "task": "Draw or doodle for 10 minutes",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.easy,
            "xp": 30,
            "progress_total": 1
        }
    ]
    
    # Determine how many to generate
    target_num_quests = random.randint(3, 4)
    num_to_generate = max(0, target_num_quests - existing_quests_count)
    
    if num_to_generate == 0 and existing_quests_count < 3:
        # Ensure at least 3 total if we have few completed ones
        num_to_generate = 3 - existing_quests_count

    if num_to_generate <= 0:
        return []

    # Filter out existing tasks to avoid duplicates
    existing_tasks = {q.task_text for q in existing_quests_objs}
    available_templates = [t for t in quest_templates if t["task"] not in existing_tasks]
    
    selected_quests = random.sample(available_templates, min(num_to_generate, len(available_templates)))
    
    # Create quest todos
    created_quests = []
    # Expire at exactly midnight of the next day
    expires_at = (today_start + timedelta(days=1))
    
    for quest in selected_quests:
        new_quest = models.Todo(
            user_id=user_id,
            task_text=quest["task"],
            is_quest=True,
            quest_type="daily",
            difficulty=quest["difficulty"],
            category=quest["category"],
            xp_reward=quest["xp"],
            progress_current=0,
            progress_total=quest["progress_total"],
            expires_at=expires_at
        )
        db.add(new_quest)
        created_quests.append(new_quest)
    
    db.commit()
    return created_quests

def generate_weekly_quests(db: Session, user_id: int) -> List[models.Todo]:
    """Generate 2-3 weekly quests for a user"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return []
    
    # Check if user already has weekly quests
    week_start = datetime.utcnow() - timedelta(days=datetime.utcnow().weekday())
    week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Clean up any leftover weekly quests from previous weeks
    db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "weekly",
        models.Todo.created_at < week_start
    ).delete(synchronize_session=False)
    
    existing_quests = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "weekly",
        models.Todo.created_at >= week_start
    ).count()
    
    if existing_quests > 0:
        return []  # Already generated this week's quests
    
    quest_templates = [
        {
            "task": "Log moods 21 times this week (3/day)",
            "category": models.QuestCategoryEnum.mood,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 100,
            "progress_total": 21
        },
        {
            "task": "Write 5 journal entries this week",
            "category": models.QuestCategoryEnum.journal,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 75,
            "progress_total": 5
        },
        {
            "task": "Maintain a 7-day streak",
            "category": models.QuestCategoryEnum.streak,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 150,
            "progress_total": 7
        },
        {
            "task": "Complete 20 todos this week",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 80,
            "progress_total": 20
        },
        # Exercise Weekly
        {
            "task": "Exercise 3 times this week",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 200,
            "progress_total": 3
        },
        # Intellectual Weekly
        {
            "task": "Read for 1 hour total this week",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 150,
            "progress_total": 1
        },
        # Mindfulness Weekly
        {
            "task": "Meditate 3 times this week",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 120,
            "progress_total": 3
        },
        # Social Weekly
        {
            "task": "Meet a friend in person",
            "category": models.QuestCategoryEnum.social,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 100,
            "progress_total": 1
        },
        # Creative Weekly
        {
            "task": "Create something (art, writing, code)",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 180,
            "progress_total": 1
        },
        # Self-Care Weekly
        {
            "task": "Have a dedicated self-care evening",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.medium,
            "xp": 130,
            "progress_total": 1
        },
        {
            "task": "Sleep 8 hours for 3 nights",
            "category": models.QuestCategoryEnum.general,
            "difficulty": models.QuestDifficultyEnum.hard,
            "xp": 160,
            "progress_total": 3
        }
    ]
    
    num_quests = random.randint(2, 3)
    selected_quests = random.sample(quest_templates, min(num_quests, len(quest_templates)))
    
    created_quests = []
    # Expire at exactly midnight of the next Monday
    expires_at = week_start + timedelta(days=7)
    
    for quest in selected_quests:
        new_quest = models.Todo(
            user_id=user_id,
            task_text=quest["task"],
            is_quest=True,
            quest_type="weekly",
            difficulty=quest["difficulty"],
            category=quest["category"],
            xp_reward=quest["xp"],
            progress_current=0,
            progress_total=quest["progress_total"],
            expires_at=expires_at
        )
        db.add(new_quest)
        created_quests.append(new_quest)
    
    db.commit()
    return created_quests

def update_quest_progress(db: Session, user_id: int, category: models.QuestCategoryEnum, increment: int = 1):
    """Update progress for all active quests of a specific category"""
    active_quests = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.is_completed == False,
        models.Todo.category == category,
        models.Todo.expires_at > datetime.utcnow()
    ).all()
    
    completed_quests = []
    for quest in active_quests:
        # SKIP manual quests for 'general' category updates
        # This prevents "Go for a walk" (general) from being auto-completed when checking a todo
        if category == models.QuestCategoryEnum.general:
            task_lower = quest.task_text.lower()
            manual_keywords = [
                "walk", "workout", "exercise", "read", "meditate", "breathing",
                "water", "social media", "call", "meet", "draw", "doodle",
                "create", "self-care", "grateful", "sleep"
            ]
            if any(k in task_lower for k in manual_keywords):
                continue

        quest.progress_current = min(quest.progress_current + increment, quest.progress_total)
        
        if quest.progress_current >= quest.progress_total:
            quest.is_completed = True
            quest.completed_at = datetime.utcnow()
            
            # Award XP and Energy
            user = db.query(models.User).filter(models.User.id == user_id).first()
            if user:
                user.xp += quest.xp_reward
                
                # Calculate energy reward based on difficulty
                energy_reward = 10  # default for medium
                if quest.difficulty:
                    if quest.difficulty.value == 'easy':
                        energy_reward = 5
                    elif quest.difficulty.value == 'medium':
                        energy_reward = 10
                    elif quest.difficulty.value == 'hard':
                        energy_reward = 15
                
                # Only award Energy if not already claimed
                if not quest.reward_claimed:
                    user.energy += energy_reward
                    quest.reward_claimed = True
            
            completed_quests.append(quest)
    
    db.commit()
    
    # Check for level up if any quests were completed
    if completed_quests:
        from app.CRUD import level_system
        level_system.check_level_up(db, user_id)
        
    return completed_quests

def get_active_quests(db: Session, user_id: int) -> dict:
    """Get all active quests for a user"""
    # Enforce strict cleanup on view as well (migrates old logic to new logic on the fly)
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "daily",
        models.Todo.created_at < today_start
    ).delete(synchronize_session=False)

    week_start = datetime.utcnow() - timedelta(days=datetime.utcnow().weekday())
    week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
    db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "weekly",
        models.Todo.created_at < week_start
    ).delete(synchronize_session=False)
    
    db.commit()

    daily_quests = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "daily",
        models.Todo.expires_at > datetime.utcnow()
    ).all()
    
    weekly_quests = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.quest_type == "weekly",
        models.Todo.expires_at > datetime.utcnow()
    ).all()
    
    return {
        "daily": daily_quests,
        "weekly": weekly_quests
    }

def clean_expired_quests(db: Session, user_id: int):
    """Remove expired quests"""
    expired = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_quest == True,
        models.Todo.expires_at <= datetime.utcnow()
    ).delete()
    db.commit()
    return expired
