from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from app import auth, models, schemas
from app.database import get_db
from app.CRUD import quests

router = APIRouter(prefix="/quests", tags=["quests"])

@router.get("/debug/check")
def debug_check_quests(
    email: str = "h@example.com",
    db: Session = Depends(get_db)
):
    """Debug endpoint to see all quests and their timestamps"""
    # 1. Try exact match
    current_user = db.query(models.User).filter(models.User.email == email).first()
    
    # 2. If not found, check if the user meant a partial match by iterating (safer than ilike issues)
    if not current_user:
        all_users = db.query(models.User).limit(100).all()
        potential_matches = [u for u in all_users if email.lower() in u.email.lower()]
        if potential_matches:
            current_user = potential_matches[0]
        else:
             return {
                 "error": f"No user found matching '{email}'", 
                 "available_user_emails": [u.email for u in all_users]
             }
    
    quests = db.query(models.Todo).filter(models.Todo.user_id == current_user.id, models.Todo.is_quest == True).all()
    
    # Check total users
    user_count = db.query(models.User).count()
    all_users = [{"id": u.id, "email": u.email} for u in db.query(models.User).all()]

    return {
        "debug_user": {"id": current_user.id, "email": current_user.email},
        "total_users": user_count,
        "all_users_list": all_users,
        "utc_now": datetime.utcnow(),
        "today_start_utc": datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0),
        "quests_count": len(quests),
        "quests": [
            {
                "id": q.id,
                "type": q.quest_type,
                "created_at": q.created_at,
                "expires_at": q.expires_at,
                "is_completed": q.is_completed,
                "should_be_deleted_daily": (q.quest_type == 'daily' and q.created_at < datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0))
            }
            for q in quests
        ]
    }

@router.post("/daily/generate")
def generate_daily_quests(
    force_refresh: bool = False,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate daily quests for user"""
    created_quests = quests.generate_daily_quests(db, current_user.id, force_refresh=force_refresh)
    
    if not created_quests:
        return {"message": "Daily quests already generated for today"}
    
    return {
        "success": True,
        "quests_generated": len(created_quests),
        "quests": [
            {
                "id": q.id,
                "task": q.task_text,
                "category": q.category.value if q.category else None,
                "difficulty": q.difficulty.value if q.difficulty else None,
                "xp_reward": q.xp_reward,
                "reward_claimed": q.reward_claimed,
                "progress": f"{q.progress_current}/{q.progress_total}",
                "expires_at": q.expires_at
            }
            for q in created_quests
        ]
    }

@router.post("/weekly/generate")
def generate_weekly_quests(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate weekly quests for user"""
    created_quests = quests.generate_weekly_quests(db, current_user.id)
    
    if not created_quests:
        return {"message": "Weekly quests already generated for this week"}
    
    return {
        "success": True,
        "quests_generated": len(created_quests),
        "quests": [
            {
                "id": q.id,
                "task": q.task_text,
                "category": q.category.value if q.category else None,
                "difficulty": q.difficulty.value if q.difficulty else None,
                "xp_reward": q.xp_reward,
                "reward_claimed": q.reward_claimed,
                "progress": f"{q.progress_current}/{q.progress_total}",
                "expires_at": q.expires_at
            }
            for q in created_quests
        ]
    }

@router.get("/active")
def get_active_quests(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all active quests for user"""
    active_quests = quests.get_active_quests(db, current_user.id)
    
    def format_quest(q):
        return {
            "id": q.id,
            "task": q.task_text,
            "category": q.category.value if q.category else None,
            "difficulty": q.difficulty.value if q.difficulty else None,
            "xp_reward": q.xp_reward,
            "progress_current": q.progress_current,
            "progress_total": q.progress_total,
            "progress_percentage": int((q.progress_current / q.progress_total) * 100) if q.progress_total > 0 else 0,
            "is_completed": q.is_completed,
            "reward_claimed": q.reward_claimed,
            "expires_at": q.expires_at
        }
    
    return {
        "daily": [format_quest(q) for q in active_quests["daily"]],
        "weekly": [format_quest(q) for q in active_quests["weekly"]]
    }

@router.post("/progress/{category}")
def update_quest_progress(
    category: str,
    increment: int = 1,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update quest progress for a specific category"""
    try:
        category_enum = models.QuestCategoryEnum(category)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid category. Must be one of: {[c.value for c in models.QuestCategoryEnum]}"
        )
    
    completed_quests = quests.update_quest_progress(db, current_user.id, category_enum, increment)
    
    return {
        "success": True,
        "quests_completed": len(completed_quests),
        "total_xp_earned": sum(q.xp_reward for q in completed_quests),
        "completed_quests": [
            {
                "id": q.id,
                "task": q.task_text,
                "xp_reward": q.xp_reward,
                "reward_claimed": q.reward_claimed
            }
            for q in completed_quests
        ]
    }

@router.delete("/cleanup")
def cleanup_expired_quests(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Remove expired quests"""
    deleted = quests.clean_expired_quests(db, current_user.id)
    
    return {
        "success": True,
        "deleted_count": deleted
    }

@router.post("/{quest_id}/complete")
def manually_complete_quest(
    quest_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """
    Manually mark a quest as complete.
    Used for activities that happen outside the app (exercise, meditation, reading, etc.)
    """
    # Find the quest
    quest = db.query(models.Todo).filter(
        models.Todo.id == quest_id,
        models.Todo.user_id == current_user.id,
        models.Todo.is_quest == True
    ).first()
    
    if not quest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Quest not found"
        )
    
    if quest.is_completed:
        # Toggle: Un-complete the quest
        quest.is_completed = False
        quest.completed_at = None
        # User requested to empty the progress bar when unchecking
        quest.progress_current = 0
        
        # Deduct XP (dynamic) but KEEP Energy (one-time)
        xp_deducted = quest.xp_reward
        energy_deducted = 0
        
        user = db.query(models.User).filter(models.User.id == current_user.id).first()
        if user:
            user.xp = max(0, user.xp - xp_deducted)
            # Do NOT deduct energy
        
        db.commit()
        db.refresh(quest)
        if user:
            db.refresh(user)
        
        return {
            "success": True,
            "message": f"Quest '{quest.task_text}' un-completed.",
            "xp_earned": -xp_deducted,
            "energy_earned": 0,  # No energy change
            "new_xp_total": user.xp if user else 0,
            "new_energy_total": user.energy if user else 0,
            "is_completed": False
        }
    
    # Mark as complete
    quest.progress_current = quest.progress_total
    quest.is_completed = True
    quest.completed_at = datetime.utcnow()
    
    # Calculate energy reward based on difficulty
    energy_reward = 10  # default for medium
    if quest.difficulty:
        if quest.difficulty.value == 'easy':
            energy_reward = 5
        elif quest.difficulty.value == 'medium':
            energy_reward = 10
        elif quest.difficulty.value == 'hard':
            energy_reward = 15
    
    # Always award XP (since it's deducted on uncomplete)
    xp_earned = quest.xp_reward
    energy_earned = 0
    
    user = db.query(models.User).filter(models.User.id == current_user.id).first()
    if user:
        # Always award XP
        user.xp += xp_earned
        
        # Only award Energy if not already claimed
        if not quest.reward_claimed:
            energy_earned = energy_reward
            user.energy += energy_earned
            quest.reward_claimed = True
            
    # Mark as complete
    quest.progress_current = quest.progress_total
    quest.is_completed = True
    quest.completed_at = datetime.utcnow()
    
    db.commit()
    
    if user:
        db.refresh(user)
    db.refresh(quest)
    
    # Check for level up
    from app.CRUD import level_system
    level_system.check_level_up(db, current_user.id)
    
    return {
        "success": True,
        "message": f"Quest '{quest.task_text}' completed!",
        "xp_earned": xp_earned,
        "energy_earned": energy_earned,
        "new_xp_total": user.xp if user else 0,
        "new_energy_total": user.energy if user else 0,
        "is_completed": True
    }

@router.post("/{quest_id}/increment")
def increment_quest_progress(
    quest_id: int,
    amount: int = 1,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """
    Increment progress on a specific quest by ID.
    Used for multi-step activities (e.g., 'Drink 8 glasses of water')
    """
    # Find the quest
    quest = db.query(models.Todo).filter(
        models.Todo.id == quest_id,
        models.Todo.user_id == current_user.id,
        models.Todo.is_quest == True
    ).first()
    
    if not quest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Quest not found"
        )
    
    if quest.is_completed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quest is already completed"
        )
    
    # Increment progress
    quest.progress_current = min(quest.progress_current + amount, quest.progress_total)
    
    xp_earned = 0
    energy_earned = 0
    # Check if completed
    if quest.progress_current >= quest.progress_total:
        quest.is_completed = True
        quest.completed_at = datetime.utcnow()
        
        # Calculate energy reward based on difficulty
        energy_reward = 10  # default for medium
        if quest.difficulty:
            if quest.difficulty.value == 'easy':
                energy_reward = 5
            elif quest.difficulty.value == 'medium':
                energy_reward = 10
            elif quest.difficulty.value == 'hard':
                energy_reward = 15
        
        # Always award XP
        xp_earned = quest.xp_reward
        
        user = db.query(models.User).filter(models.User.id == current_user.id).first()
        if user:
            user.xp += xp_earned
            
            # Only award Energy if not already claimed
            if not quest.reward_claimed:
                energy_earned = energy_reward
                user.energy += energy_earned
                quest.reward_claimed = True
    
    db.commit()
    
    # Check for level up if XP was earned
    if xp_earned > 0:
        from app.CRUD import level_system
        level_system.check_level_up(db, current_user.id)
    
    return {
        "success": True,
        "progress_current": quest.progress_current,
        "progress_total": quest.progress_total,
        "is_completed": quest.is_completed,
        "xp_earned": xp_earned,
        "energy_earned": energy_earned
    }
