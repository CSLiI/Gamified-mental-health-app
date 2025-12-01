from sqlalchemy.orm import Session
from app import models
from datetime import datetime, timedelta
from typing import Dict, Any

def get_user_daily_status(db: Session, user_id: int) -> Dict[str, Any]:
    """Get user's daily check-in status"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    today = datetime.now().date()
    last_login = user.last_daily_claim.date() if user.last_daily_claim else None
    
    # Calculate streak
    current_streak = 0
    if last_login:
        days_diff = (today - last_login).days
        if days_diff == 0:
            # Already claimed today
            current_streak = user.current_streak or 1
            can_claim = False
        elif days_diff == 1:
            # Consecutive day
            current_streak = (user.current_streak or 0) + 1
            can_claim = True
        else:
            # Streak broken
            current_streak = 1
            can_claim = True
    else:
        # First time
        current_streak = 1
        can_claim = True
    
    return {
        "can_claim": can_claim,
        "current_streak": current_streak,
        "last_claim_date": last_login.isoformat() if last_login else None,
        "total_claims": user.total_daily_claims or 0,
        "longest_streak": user.longest_streak or 0
    }

def claim_daily_reward(db: Session, user_id: int) -> Dict[str, Any]:
    """Claim daily reward and update streak"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return {"success": False, "message": "User not found"}
    
    status = get_user_daily_status(db, user_id)
    
    if not status["can_claim"]:
        return {
            "success": False,
            "message": "Already claimed today",
            "streak": status["current_streak"]
        }
    
    # Calculate reward based on streak
    base_xp = 10
    streak_bonus = min((status["current_streak"] - 1) * 5, 50)  # Max 50 bonus
    total_xp = base_xp + streak_bonus
    
    # Milestone bonuses
    milestone_bonus = 0
    milestone_message = None
    if status["current_streak"] == 7:
        milestone_bonus = 100
        milestone_message = "🎉 7-Day Streak Bonus!"
    elif status["current_streak"] == 30:
        milestone_bonus = 500
        milestone_message = "🏆 30-Day Streak Master!"
    elif status["current_streak"] % 7 == 0:
        milestone_bonus = 50
        milestone_message = f"⭐ {status['current_streak']}-Day Milestone!"
    
    total_xp += milestone_bonus
    
    # Update user
    user.xp += total_xp
    user.last_daily_claim = datetime.now()
    user.current_streak = status["current_streak"]
    user.total_daily_claims = (user.total_daily_claims or 0) + 1
    
    if status["current_streak"] > (user.longest_streak or 0):
        user.longest_streak = status["current_streak"]
    
    db.commit()
    db.refresh(user)
    
    return {
        "success": True,
        "xp_earned": total_xp,
        "base_xp": base_xp,
        "streak_bonus": streak_bonus,
        "milestone_bonus": milestone_bonus,
        "milestone_message": milestone_message,
        "new_streak": status["current_streak"],
        "total_xp": user.xp,
        "total_claims": user.total_daily_claims
    }

def get_daily_calendar(db: Session, user_id: int, days: int = 30) -> Dict[str, Any]:
    """Get calendar showing past claim days"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    today = datetime.now().date()
    calendar_days = []
    
    # For simplicity, mark days based on streak
    # In production, you'd want a separate table to track each claim
    for i in range(days):
        day_date = today - timedelta(days=days - i - 1)
        
        # Rough estimation: if within current streak range, mark as claimed
        last_claim = user.last_daily_claim.date() if user.last_daily_claim else None
        is_claimed = False
        
        if last_claim and user.current_streak:
            streak_start = last_claim - timedelta(days=user.current_streak - 1)
            if streak_start <= day_date <= last_claim:
                is_claimed = True
        
        calendar_days.append({
            "date": day_date.isoformat(),
            "claimed": is_claimed,
            "is_today": day_date == today
        })
    
    return {
        "days": calendar_days,
        "current_streak": user.current_streak or 0,
        "longest_streak": user.longest_streak or 0
    }

def get_streak_freeze_status(db: Session, user_id: int) -> Dict[str, Any]:
    """Check if user has streak freeze available"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    return {
        "freeze_available": user.streak_freeze_available or False,
        "freeze_used_this_week": user.streak_freeze_used_this_week or False
    }

def use_streak_freeze(db: Session, user_id: int) -> Dict[str, Any]:
    """Use streak freeze to protect streak"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return {"success": False, "message": "User not found"}
    
    if not (user.streak_freeze_available or False):
        return {"success": False, "message": "No streak freeze available"}
    
    if user.streak_freeze_used_this_week or False:
        return {"success": False, "message": "Already used freeze this week"}
    
    user.streak_freeze_used_this_week = True
    user.last_daily_claim = datetime.now()  # Extend last claim
    
    db.commit()
    
    return {
        "success": True,
        "message": "Streak freeze activated! Your streak is protected.",
        "streak_protected": user.current_streak
    }
