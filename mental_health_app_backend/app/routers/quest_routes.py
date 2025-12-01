from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app import auth, models, schemas
from app.database import get_db
from app.CRUD import quests

router = APIRouter(prefix="/quests", tags=["quests"])

@router.post("/daily/generate")
def generate_daily_quests(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Generate daily quests for user"""
    created_quests = quests.generate_daily_quests(db, current_user.id)
    
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
                "xp_reward": q.xp_reward
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
