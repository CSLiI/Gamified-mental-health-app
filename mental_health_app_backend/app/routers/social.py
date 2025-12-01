from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from typing import List, Optional
from datetime import datetime, timezone, timedelta

from ..database import get_db
from ..models import User, Friendship, Character, Interest, Todo, MoodLog, Encouragement, Message, user_interests_table
from ..schemas import (
    UserProfileResponse, Todo as TodoSchema, 
    EncouragementCreate, EncouragementResponse,
    MessageCreate, MessageResponse
)
from ..auth import get_current_user

router = APIRouter(tags=["Social Features"])

# ==================== Helper Functions ====================

def check_friendship(db: Session, user_id: int, friend_user_id: int) -> bool:
    """Check if two users are friends"""
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == user_id,
                Friendship.friend_id == friend_user_id
            ),
            and_(
                Friendship.user_id == friend_user_id,
                Friendship.friend_id == user_id
            )
        )
    ).first()
    return friendship is not None

def get_friend_user_id(db: Session, user_id: int, friendship_id: int) -> int:
    """Get the actual user_id of a friend from friendship_id"""
    friendship = db.query(Friendship).filter(Friendship.id == friendship_id).first()
    if not friendship:
        raise HTTPException(status_code=404, detail="Friendship not found")
    
    # Return the user_id that is NOT the current user
    if friendship.user_id == user_id:
        return friendship.friend_id
    else:
        return friendship.user_id

# ==================== User Profile ====================

@router.get("/users/{user_id}/profile", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a user's public profile (must be friends to view)"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view this profile"
        )
    
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get user's character
    character = None
    if hasattr(user, 'user_characters') and user.user_characters:
        # Get the most recent character
        user_char = sorted(user.user_characters, key=lambda x: x.chosen_at, reverse=True)[0]
        char = user_char.character
        if char:
            character = {
                "id": char.id,
                "name": char.name,
                "description": char.description,
                "image_url": char.image_url,
                "gender": char.gender,
                "number": char.number
            }
    
    # Get user's interests via the many-to-many relationship
    interests = []
    if hasattr(user, 'user_interests') and user.user_interests:
        for interest in user.user_interests:
            interests.append({"id": interest.id, "name": interest.name})
    
    # Calculate streak (User model doesn't have current_streak/longest_streak fields)
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    mood_logs = db.query(MoodLog).filter(
        MoodLog.user_id == user.id,
        MoodLog.logged_at >= thirty_days_ago
    ).order_by(MoodLog.logged_at.desc()).all()
    
    current_streak = 0
    longest_streak = 0
    
    if mood_logs:
        dates = []
        for log in mood_logs:
            log_date = log.logged_at.date()
            if log_date not in dates:
                dates.append(log_date)
        dates.sort(reverse=True)
        
        today = datetime.now(timezone.utc).date()
        yesterday = today - timedelta(days=1)
        
        if dates[0] == today or dates[0] == yesterday:
            current_date = dates[0]
            current_streak = 1
            for i in range(1, len(dates)):
                expected_date = current_date - timedelta(days=1)
                if dates[i] == expected_date:
                    current_streak += 1
                    current_date = dates[i]
                else:
                    break
        
        # Calculate longest streak
        temp_streak = 1
        longest_streak = 1
        for i in range(1, len(dates)):
            expected_date = dates[i-1] - timedelta(days=1)
            if dates[i] == expected_date:
                temp_streak += 1
                longest_streak = max(longest_streak, temp_streak)
            else:
                temp_streak = 1
    
    return UserProfileResponse(
        id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        date_of_birth=str(user.date_of_birth) if user.date_of_birth else None,
        gender=user.gender.value if user.gender else None,
        level=user.level if user.level else 1,
        xp=user.xp if user.xp else 0,
        current_streak=current_streak,
        longest_streak=longest_streak,
        character=character,
        interests=interests
    )

# ==================== Friend's Todos ====================

@router.get("/users/{user_id}/todos", response_model=List[TodoSchema])
async def get_friend_todos(
    user_id: int,
    period_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's todos (must be friends to view)"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view todos"
        )
    
    # Get friend's todos
    query = db.query(Todo).filter(Todo.user_id == user_id)
    
    if period_type:
        query = query.filter(Todo.period_type == period_type)
        
        # Filter by today's date for daily todos
        if period_type == 'daily':
            from sqlalchemy import func
            from datetime import date
            today = date.today()
            query = query.filter(func.date(Todo.created_at) == today)
    
    todos = query.order_by(Todo.created_at.desc()).all()
    
    return todos

# ==================== Friend's Streak ====================

@router.get("/users/{user_id}/streak")
async def get_friend_streak(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's streak data (must be friends to view)"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view streak"
        )
    
    # Calculate friend's streak (same logic as /achievements/me/streak)
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    
    # Get all mood logs in the last 30 days
    mood_logs = db.query(MoodLog).filter(
        MoodLog.user_id == user_id,
        MoodLog.logged_at >= thirty_days_ago
    ).order_by(MoodLog.logged_at.desc()).all()
    
    if not mood_logs:
        return {
            "current_streak": 0,
            "longest_streak": 0,
            "last_log_date": None
        }
    
    # Calculate streaks
    dates = []
    for log in mood_logs:
        log_date = log.logged_at.date()
        if log_date not in dates:
            dates.append(log_date)
    
    dates.sort(reverse=True)
    
    # Calculate current streak
    current_streak = 0
    today = datetime.now(timezone.utc).date()
    yesterday = today - timedelta(days=1)
    
    if dates[0] == today or dates[0] == yesterday:
        current_date = dates[0]
        current_streak = 1
        
        for i in range(1, len(dates)):
            expected_date = current_date - timedelta(days=1)
            if dates[i] == expected_date:
                current_streak += 1
                current_date = dates[i]
            else:
                break
    
    # Calculate longest streak
    longest_streak = 0
    temp_streak = 1
    
    for i in range(1, len(dates)):
        expected_date = dates[i-1] - timedelta(days=1)
        if dates[i] == expected_date:
            temp_streak += 1
            longest_streak = max(longest_streak, temp_streak)
        else:
            temp_streak = 1
    
    longest_streak = max(longest_streak, temp_streak)
    
    return {
        "current_streak": current_streak,
        "longest_streak": longest_streak,
        "last_log_date": dates[0].isoformat() if dates else None
    }

# ==================== Friend's Character Mood State ====================

@router.get("/users/{user_id}/character/mood-state")
async def get_friend_character_mood_state(
    user_id: int,
    days: int = 7,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's character mood state based on recent mood logs (must be friends to view)"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view character mood state"
        )
    
    # Import the character CRUD function
    from ..CRUD.characters import get_character_mood_state
    
    # Get the friend's character mood state
    result = get_character_mood_state(db, user_id, days)
    return result

@router.get("/users/{user_id}/mood-logs")
async def get_friend_mood_logs(
    user_id: int,
    days: int = 7,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's mood logs for the last N days (must be friends to view)"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, user_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view mood logs"
        )
    
    from datetime import datetime, timedelta
    date_from = datetime.utcnow() - timedelta(days=days)
    
    mood_logs = db.query(MoodLog).filter(
        MoodLog.user_id == user_id,
        MoodLog.logged_at >= date_from
    ).order_by(MoodLog.logged_at.asc()).all()
    
    return [{
        "id": log.id,
        "mood": log.mood.value,
        "logged_at": log.logged_at.isoformat()
    } for log in mood_logs]

# ==================== Encouragement ====================

@router.post("/friends/{friend_id}/encouragement", status_code=status.HTTP_201_CREATED)
async def send_encouragement(
    friend_id: int,
    encouragement: EncouragementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send encouragement to a friend"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, friend_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to send encouragement"
        )
    
    # Create encouragement
    new_encouragement = Encouragement(
        sender_id=current_user.id,
        receiver_id=friend_id,
        message=encouragement.message,
        is_read=False
    )
    
    db.add(new_encouragement)
    db.commit()
    
    return {"message": "Encouragement sent successfully"}

@router.get("/encouragements/", response_model=List[EncouragementResponse])
async def get_encouragements(
    unread_only: Optional[bool] = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get encouragements received"""
    query = db.query(Encouragement).filter(
        Encouragement.receiver_id == current_user.id
    )
    
    if unread_only:
        query = query.filter(Encouragement.is_read == False)
    
    encouragements = query.order_by(Encouragement.created_at.desc()).all()
    
    result = []
    for enc in encouragements:
        sender = db.query(User).filter(User.id == enc.sender_id).first()
        result.append(EncouragementResponse(
            id=enc.id,
            sender_id=enc.sender_id,
            receiver_id=enc.receiver_id,
            sender_first_name=sender.first_name if sender else "",
            sender_last_name=sender.last_name if sender else "",
            message=enc.message,
            is_read=enc.is_read,
            created_at=enc.created_at
        ))
    
    return result

@router.put("/encouragements/{encouragement_id}/read")
async def mark_encouragement_read(
    encouragement_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark encouragement as read"""
    encouragement = db.query(Encouragement).filter(
        Encouragement.id == encouragement_id,
        Encouragement.receiver_id == current_user.id
    ).first()
    
    if not encouragement:
        raise HTTPException(status_code=404, detail="Encouragement not found")
    
    encouragement.is_read = True
    db.commit()
    
    return {"message": "Marked as read"}

# ==================== Messaging ====================

@router.post("/friends/{friend_id}/messages", status_code=status.HTTP_201_CREATED)
async def send_message(
    friend_id: int,
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send a message to a friend"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, friend_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to send messages"
        )
    
    # Create message
    new_message = Message(
        sender_id=current_user.id,
        receiver_id=friend_id,
        message=message.message,
        is_read=False
    )
    
    db.add(new_message)
    db.commit()
    
    return {"message": "Message sent successfully"}

@router.get("/friends/{friend_id}/messages", response_model=List[MessageResponse])
async def get_messages(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get message conversation with a friend"""
    # Check if users are friends
    if not check_friendship(db, current_user.id, friend_id):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You must be friends to view messages"
        )
    
    # Get all messages between users
    messages = db.query(Message).filter(
        or_(
            and_(
                Message.sender_id == current_user.id,
                Message.receiver_id == friend_id
            ),
            and_(
                Message.sender_id == friend_id,
                Message.receiver_id == current_user.id
            )
        )
    ).order_by(Message.created_at.asc()).all()
    
    # Mark messages as read
    for msg in messages:
        if msg.receiver_id == current_user.id and not msg.is_read:
            msg.is_read = True
    db.commit()
    
    result = []
    for msg in messages:
        sender = db.query(User).filter(User.id == msg.sender_id).first()
        result.append(MessageResponse(
            id=msg.id,
            sender_id=msg.sender_id,
            receiver_id=msg.receiver_id,
            sender_first_name=sender.first_name if sender else "",
            sender_last_name=sender.last_name if sender else "",
            message=msg.message,
            is_read=msg.is_read,
            is_completed=msg.is_completed if hasattr(msg, 'is_completed') else False,
            created_at=msg.created_at
        ))
    
    return result

@router.get("/messages/", response_model=List[MessageResponse])
async def get_all_messages(
    unread_only: Optional[bool] = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get all messages (challenges) received"""
    query = db.query(Message).filter(
        Message.receiver_id == current_user.id
    )
    
    if unread_only:
        query = query.filter(Message.is_read == False)
    
    messages = query.order_by(Message.created_at.desc()).all()
    
    result = []
    for msg in messages:
        sender = db.query(User).filter(User.id == msg.sender_id).first()
        result.append(MessageResponse(
            id=msg.id,
            sender_id=msg.sender_id,
            receiver_id=msg.receiver_id,
            sender_first_name=sender.first_name if sender else "",
            sender_last_name=sender.last_name if sender else "",
            message=msg.message,
            is_read=msg.is_read,
            is_completed=msg.is_completed if hasattr(msg, 'is_completed') else False,
            created_at=msg.created_at
        ))
    
    return result

@router.put("/messages/{message_id}/completion")
async def update_message_completion(
    message_id: int,
    completion_data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark a challenge (message) as completed or incomplete"""
    is_completed = completion_data.get('is_completed', False)
    # Get the message
    message = db.query(Message).filter(Message.id == message_id).first()
    if not message:
        raise HTTPException(status_code=404, detail="Message not found")
    
    # Only the receiver can mark the challenge as completed
    if message.receiver_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only mark your own received challenges as completed"
        )
    
    # Update completion status
    message.is_completed = is_completed
    db.commit()
    
    return {
        "success": True,
        "message_id": message_id,
        "is_completed": is_completed
    }
