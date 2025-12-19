from sqlalchemy.orm import Session, joinedload
from app import models, schemas
from typing import List, Optional
from datetime import datetime, timedelta
from sqlalchemy import func

# ==================== ACHIEVEMENT CRUD ====================
def create_achievement(db: Session, achievement: schemas.AchievementCreate):
    """Create a new achievement"""
    db_achievement = models.Achievement(
        name=achievement.name,
        description=achievement.description,
        category=achievement.category,
        icon_url=achievement.icon_url,
        xp_reward=achievement.xp_reward,
        requirement_count=achievement.requirement_count,
        is_hidden=achievement.is_hidden
    )
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

def get_achievement(db: Session, achievement_id: int):
    """Get achievement by ID"""
    return db.query(models.Achievement).filter(models.Achievement.id == achievement_id).first()

def get_all_achievements(db: Session, skip: int = 0, limit: int = 100):
    """Get all achievements"""
    return db.query(models.Achievement).offset(skip).limit(limit).all()

def get_achievements_by_category(db: Session, category: str):
    """Get achievements by category"""
    return db.query(models.Achievement).filter(models.Achievement.category == category).all()

# ==================== USER ACHIEVEMENT CRUD ====================
def get_user_achievements(db: Session, user_id: int, claimed_only: bool = False):
    """Get all achievements for a user"""
    query = db.query(models.UserAchievement).options(
        joinedload(models.UserAchievement.achievement)
    ).filter(models.UserAchievement.user_id == user_id)
    
    if claimed_only:
        query = query.filter(models.UserAchievement.is_claimed == True)
    
    return query.all()

def award_achievement(db: Session, user_id: int, achievement_id: int):
    """Award an achievement to a user"""
    from app.CRUD import users as user_crud
    
    # Check if already awarded
    existing = db.query(models.UserAchievement).filter(
        models.UserAchievement.user_id == user_id,
        models.UserAchievement.achievement_id == achievement_id
    ).first()
    
    if existing:
        return existing
    
    # Create user achievement
    user_achievement = models.UserAchievement(
        user_id=user_id,
        achievement_id=achievement_id,
        progress=0,
        is_claimed=False
    )
    db.add(user_achievement)
    
    # Award XP
    achievement = get_achievement(db, achievement_id)
    if achievement and achievement.xp_reward > 0:
        user_crud.update_user_xp(db, user_id, achievement.xp_reward)
    
    db.commit()
    db.refresh(user_achievement)
    return user_achievement

def update_achievement_progress(db: Session, user_id: int, achievement_id: int, progress: int):
    """Update progress towards an achievement"""
    user_achievement = db.query(models.UserAchievement).filter(
        models.UserAchievement.user_id == user_id,
        models.UserAchievement.achievement_id == achievement_id
    ).first()
    
    if not user_achievement:
        # Create if doesn't exist
        user_achievement = models.UserAchievement(
            user_id=user_id,
            achievement_id=achievement_id,
            progress=progress
        )
        db.add(user_achievement)
    else:
        user_achievement.progress = progress
    
    # Check if achievement is completed
    achievement = get_achievement(db, achievement_id)
    if achievement and progress >= achievement.requirement_count and not user_achievement.is_claimed:
        user_achievement.is_claimed = True
        user_achievement.unlocked_at = datetime.utcnow()
    
    db.commit()
    db.refresh(user_achievement)
    return user_achievement

# ==================== ACHIEVEMENT CHECKERS ====================
def check_mood_tracking_achievements(db: Session, user_id: int):
    """Check and award mood tracking achievements"""
    total_moods = db.query(models.MoodLog).filter(models.MoodLog.user_id == user_id).count()
    
    achievements_to_check = [
        (1, 1),    # First mood log
        (2, 7),    # 7 mood logs
        (3, 30),   # 30 mood logs
        (4, 100),  # 100 mood logs
    ]
    
    awarded = []
    for achievement_id, requirement in achievements_to_check:
        if total_moods >= requirement:
            result = award_achievement(db, user_id, achievement_id)
            if result:
                awarded.append(result)
    
    return awarded

def check_journaling_achievements(db: Session, user_id: int):
    """Check and award journaling achievements"""
    total_entries = db.query(models.JournalEntry).filter(models.JournalEntry.user_id == user_id).count()
    
    achievements_to_check = [
        (5, 1),    # First journal entry
        (6, 10),   # 10 journal entries
        (7, 50),   # 50 journal entries
    ]
    
    awarded = []
    for achievement_id, requirement in achievements_to_check:
        if total_entries >= requirement:
            result = award_achievement(db, user_id, achievement_id)
            if result:
                awarded.append(result)
    
    return awarded

def check_consistency_achievements(db: Session, user_id: int):
    """Check streak-based consistency achievements"""
    # Calculate current streak
    streak = calculate_user_streak(db, user_id)
    
    achievements_to_check = [
        (8, 3),    # 3-day streak
        (9, 7),    # 7-day streak
        (10, 30),  # 30-day streak
    ]
    
    awarded = []
    for achievement_id, requirement in achievements_to_check:
        if streak >= requirement:
            result = award_achievement(db, user_id, achievement_id)
            if result:
                awarded.append(result)
    
    return awarded

def calculate_user_streak(db: Session, user_id: int):
    """Calculate consecutive days user has logged mood or journal"""
    from datetime import date, timedelta
    
    today = date.today()
    streak = 0
    current_date = today
    
    # Check up to 365 days back
    for _ in range(365):
        mood_exists = db.query(models.MoodLog).filter(
            models.MoodLog.user_id == user_id,
            func.date(models.MoodLog.logged_at) == current_date
        ).first()
        
        journal_exists = db.query(models.JournalEntry).filter(
            models.JournalEntry.user_id == user_id,
            func.date(models.JournalEntry.created_at) == current_date
        ).first()
        
        if mood_exists or journal_exists:
            streak += 1
            current_date -= timedelta(days=1)
        else:
            break
    
    return streak

def check_social_achievements(db: Session, user_id: int):
    """Check and award social achievements (friends + challenges)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return []
    
    awarded = []
    
    # ===== FRIEND COUNT ACHIEVEMENTS =====
    # Count user's friends from the Friendship table
    friend_count = db.query(models.Friendship).filter(
        models.Friendship.user_id == user_id
    ).count()
    
    friend_achievements = {
        "Social Butterfly": 5,
        "Squad Goals": 10,
        "Support Network": 20,
        "Social Star": 50
    }
    
    for name, requirement in friend_achievements.items():
        achievement = db.query(models.Achievement).filter(
            models.Achievement.name == name
        ).first()
        if achievement and friend_count >= requirement:
            result = award_achievement(db, user_id, achievement.id)
            if result:
                awarded.append(result)
    
    # ===== CHALLENGE COMPLETION ACHIEVEMENTS =====
    total_challenges = user.completed_challenges or 0
    
    challenge_achievements = {
        "First Challenge": 1,
        "Team Player": 10,
        "Challenge Champion": 50
    }
    
    for name, requirement in challenge_achievements.items():
        achievement = db.query(models.Achievement).filter(
            models.Achievement.name == name
        ).first()
        if achievement and total_challenges >= requirement:
            result = award_achievement(db, user_id, achievement.id)
            if result:
                awarded.append(result)
    
    return awarded

def check_todo_achievements(db: Session, user_id: int):
    """Check and award todo completion achievements"""
    # Count completed todos
    total_completed = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_completed == True
    ).count()
    
    todo_achievements = {
        "Task Master": 50,
        "Completion King": 100,
        "Quest Conqueror": 500
    }
    
    awarded = []
    for name, requirement in todo_achievements.items():
        achievement = db.query(models.Achievement).filter(
            models.Achievement.name == name
        ).first()
        if achievement and total_completed >= requirement:
            result = award_achievement(db, user_id, achievement.id)
            if result:
                awarded.append(result)
    
    return awarded

def check_all_achievements(db: Session, user_id: int):
    """Check all achievement criteria for a user"""
    results = {
        "mood_tracking": check_mood_tracking_achievements(db, user_id),
        "journaling": check_journaling_achievements(db, user_id),
        "consistency": check_consistency_achievements(db, user_id),
        "social": check_social_achievements(db, user_id),
        "todos": check_todo_achievements(db, user_id)
    }
    return results

def cleanup_old_completed_challenges(db: Session) -> int:
    """Delete completed challenges older than midnight today. Returns number deleted."""
    # OLD: cutoff_time = datetime.utcnow() - timedelta(hours=24)
    # NEW: Cleanup anything completed before today started (Midnight UTC)
    cutoff_time = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    
    # Find completed messages (challenges) completed before today
    old_challenges = db.query(models.Message).filter(
        models.Message.is_completed == True,
        models.Message.completed_at.isnot(None),
        models.Message.completed_at < cutoff_time
    ).all()
    
    # Also find legacy completed challenges without completed_at timestamp
    # (these are old challenges completed before we added the timestamp)
    legacy_challenges = db.query(models.Message).filter(
        models.Message.is_completed == True,
        models.Message.completed_at.is_(None)
    ).all()
    
    count = len(old_challenges) + len(legacy_challenges)
    
    # Delete them all
    for challenge in old_challenges + legacy_challenges:
        db.delete(challenge)
    
    db.commit()
    return count