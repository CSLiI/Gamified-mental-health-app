# Social Features Backend Implementation Guide

## Overview

This guide provides complete backend implementation for the social accountability features in the Mental Health Gamified App. The frontend is already implemented and waiting for these backend endpoints.

## Required Database Models

### 1. Encouragement Model (New)

Add to `app/models.py`:

```python
class Encouragement(Base):
    __tablename__ = "encouragements"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    message = Column(String, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_encouragements")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_encouragements")
```

### 2. Message Model (New)

Add to `app/models.py`:

```python
class Message(Base):
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    message = Column(Text, nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_messages")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_messages")
```

## Required Schemas

Add to `app/schemas.py`:

```python
# Encouragement Schemas
class EncouragementCreate(BaseModel):
    message: str

class EncouragementResponse(BaseModel):
    id: int
    sender_id: int
    sender_first_name: str
    sender_last_name: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Message Schemas
class MessageCreate(BaseModel):
    message: str

class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    sender_first_name: Optional[str] = None
    sender_last_name: Optional[str] = None
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# Profile Response (for viewing friend profiles)
class UserProfileResponse(BaseModel):
    id: int
    email: str
    first_name: str
    last_name: str
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    character: Optional[dict] = None
    interests: Optional[List[dict]] = None

    class Config:
        from_attributes = True
```

## Required API Endpoints

### 1. Friend Profile Endpoint

Create `app/routers/users.py` or add to existing user router:

```python
@router.get("/users/{user_id}/profile", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a user's public profile (must be friends to view)"""
    # Check if users are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == user_id
            ),
            and_(
                Friendship.user_id == user_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to view this profile")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Get user's character
    character = None
    if user.selected_character_id:
        char = db.query(Character).filter(Character.id == user.selected_character_id).first()
        if char:
            character = {
                "id": char.id,
                "name": char.name,
                "description": char.description,
                "image_path": char.image_path
            }

    # Get user's interests
    interests = []
    user_interests = db.query(UserInterest).filter(UserInterest.user_id == user_id).all()
    for ui in user_interests:
        interest = db.query(Interest).filter(Interest.id == ui.interest_id).first()
        if interest:
            interests.append({"id": interest.id, "name": interest.name})

    return UserProfileResponse(
        id=user.id,
        email=user.email,
        first_name=user.first_name,
        last_name=user.last_name,
        date_of_birth=str(user.date_of_birth) if user.date_of_birth else None,
        gender=user.gender,
        character=character,
        interests=interests
    )
```

### 2. Friend's Todos Endpoint

Add to `app/routers/todos.py` or create new file:

```python
@router.get("/users/{user_id}/todos", response_model=List[TodoResponse])
async def get_friend_todos(
    user_id: int,
    period_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's todos (must be friends to view)"""
    # Check if users are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == user_id
            ),
            and_(
                Friendship.user_id == user_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to view todos")

    # Get friend's todos
    query = db.query(Todo).filter(Todo.user_id == user_id)

    if period_type:
        query = query.filter(Todo.period_type == period_type)

    todos = query.order_by(Todo.created_at.desc()).all()

    return [TodoResponse(
        id=todo.id,
        user_id=todo.user_id,
        task_text=todo.task_text,
        is_completed=todo.is_completed,
        period_type=todo.period_type,
        created_at=todo.created_at,
        completed_at=todo.completed_at
    ) for todo in todos]
```

### 3. Friend's Streak Endpoint

Add to `app/routers/achievements.py`:

```python
@router.get("/users/{user_id}/streak")
async def get_friend_streak(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get a friend's streak data (must be friends to view)"""
    # Check if users are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == user_id
            ),
            and_(
                Friendship.user_id == user_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to view streak")

    # Calculate friend's streak (same logic as /achievements/me/streak)
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)

    # Get all mood logs in the last 30 days
    mood_logs = db.query(MoodLog).filter(
        MoodLog.user_id == user_id,
        MoodLog.created_at >= thirty_days_ago
    ).order_by(MoodLog.created_at.desc()).all()

    if not mood_logs:
        return {
            "current_streak": 0,
            "longest_streak": 0,
            "last_log_date": None
        }

    # Calculate streaks
    dates = []
    for log in mood_logs:
        log_date = log.created_at.date()
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
```

### 4. Encouragement Endpoints

Create `app/routers/encouragements.py`:

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ..database import get_db
from ..models import User, Encouragement, Friendship
from ..schemas import EncouragementCreate, EncouragementResponse
from ..dependencies import get_current_user

router = APIRouter()

@router.post("/friends/{friend_id}/encouragement")
async def send_encouragement(
    friend_id: int,
    encouragement: EncouragementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send encouragement to a friend"""
    # Check if users are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == friend_id
            ),
            and_(
                Friendship.user_id == friend_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to send encouragement")

    # Get actual user_id from friend_id (which is the friendship id)
    if friendship.user_id == current_user.id:
        receiver_id = friendship.friend_id
    else:
        receiver_id = friendship.user_id

    # Create encouragement
    new_encouragement = Encouragement(
        sender_id=current_user.id,
        receiver_id=receiver_id,
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
```

### 5. Messaging Endpoints

Create `app/routers/messages.py`:

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from sqlalchemy import or_, and_

from ..database import get_db
from ..models import User, Message, Friendship
from ..schemas import MessageCreate, MessageResponse
from ..dependencies import get_current_user

router = APIRouter()

@router.post("/friends/{friend_id}/messages")
async def send_message(
    friend_id: int,
    message: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Send a message to a friend"""
    # Check if users are friends
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == friend_id
            ),
            and_(
                Friendship.user_id == friend_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to send messages")

    # Get actual user_id
    if friendship.user_id == current_user.id:
        receiver_id = friendship.friend_id
    else:
        receiver_id = friendship.user_id

    # Create message
    new_message = Message(
        sender_id=current_user.id,
        receiver_id=receiver_id,
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
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user_id == current_user.id,
                Friendship.friend_id == friend_id
            ),
            and_(
                Friendship.user_id == friend_id,
                Friendship.friend_id == current_user.id
            )
        )
    ).first()

    if not friendship:
        raise HTTPException(status_code=403, detail="You must be friends to view messages")

    # Get actual user_id
    if friendship.user_id == current_user.id:
        other_user_id = friendship.friend_id
    else:
        other_user_id = friendship.user_id

    # Get all messages between users
    messages = db.query(Message).filter(
        or_(
            and_(
                Message.sender_id == current_user.id,
                Message.receiver_id == other_user_id
            ),
            and_(
                Message.sender_id == other_user_id,
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
            created_at=msg.created_at
        ))

    return result
```

## Register Routers in main.py

Add to `main.py`:

```python
from app.routers import encouragements, messages

# Register routers
app.include_router(encouragements.router, tags=["Encouragements"])
app.include_router(messages.router, tags=["Messages"])
```

## Database Migration

Run these commands to create the tables:

```bash
# Start Python shell
python

# Create tables
from app.database import engine
from app.models import Base
Base.metadata.create_all(bind=engine)
```

Or if you're using Alembic:

```bash
alembic revision --autogenerate -m "Add encouragements and messages tables"
alembic upgrade head
```

## Testing the Endpoints

Use the Swagger UI at `http://localhost:8000/docs` to test:

1. **View Friend Profile**: `GET /users/{user_id}/profile`
2. **Get Friend Todos**: `GET /users/{user_id}/todos`
3. **Get Friend Streak**: `GET /users/{user_id}/streak`
4. **Send Encouragement**: `POST /friends/{friend_id}/encouragement`
5. **Get Encouragements**: `GET /encouragements/`
6. **Send Message**: `POST /friends/{friend_id}/messages`
7. **Get Messages**: `GET /friends/{friend_id}/messages`

## Frontend Integration

The frontend is already configured to call these endpoints. Once you implement the backend:

1. Tasks will automatically show friend's real todos
2. Streaks will display actual streak data
3. Encouragement button will send real notifications
4. Profile view will show character/mood gif
5. Messaging dialog will send and receive real messages

## Notes

- All endpoints check friendship status before allowing access
- Messages are automatically marked as read when retrieved
- Encouragements support unread filtering
- Profile includes character and interests data
- Streak calculation matches the existing user streak logic

## Empty States

If backend endpoints don't exist yet, the frontend will gracefully handle it by:

- Showing "No data available" for friend tasks
- Showing "No streak data" for friend streaks
- Displaying empty state icons and messages
- Catching API errors and displaying user-friendly messages
