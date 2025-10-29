# 🤝 Social Features Implementation Guide

## Overview

This guide explains how to implement social accountability features for your mental health app, allowing users to connect with friends and share their journey.

---

## ✅ What's Already Done (Frontend)

### 1. **Social Button on Home Screen**

- Added a beautiful purple gradient button before "Quick Actions"
- Button navigates to the social screen when tapped

### 2. **Social Screen UI**

- Created `lib/presentation/screens/social/social_screen.dart`
- Features 3 tabs: Friends, Requests (received), Sent (sent requests)
- Empty states for each tab
- Friend cards with profile avatars
- Accept/reject buttons for friend requests
- Cancel button for sent requests
- Add friend dialog with search functionality

---

## 🔧 Backend Implementation Steps

### **Step 1: Database Models**

Create a new file `mental_health_app_backend/app/models.py` and add these models (or add to existing):

```python
from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

# Enum for friend request status
class FriendRequestStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

# Friendship table (many-to-many relationship)
class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    friend_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", foreign_keys=[user_id], backref="friendships")
    friend = relationship("User", foreign_keys=[friend_id])

# Friend Request table
class FriendRequest(Base):
    __tablename__ = "friend_requests"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(SQLEnum(FriendRequestStatus), default=FriendRequestStatus.pending, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_requests")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_requests")
```

**Run this SQL to create the tables:**

```sql
-- Create friendships table
CREATE TABLE friendships (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);

-- Create friend_requests table
CREATE TYPE friend_request_status AS ENUM ('pending', 'accepted', 'rejected');

CREATE TABLE friend_requests (
    id SERIAL PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status friend_request_status DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(sender_id, receiver_id)
);

CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id);
CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id);
CREATE INDEX idx_friend_requests_status ON friend_requests(status);
```

---

### **Step 2: Pydantic Schemas**

Add to `mental_health_app_backend/app/schemas.py`:

```python
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

# Friend Request Schemas
class FriendRequestCreate(BaseModel):
    receiver_username: str  # or receiver_email

class FriendRequestResponse(BaseModel):
    id: int
    sender_id: int
    sender_username: str
    sender_first_name: str
    sender_last_name: str
    receiver_id: int
    status: str
    created_at: datetime

    class Config:
        from_attributes = True

# Friend Schemas
class FriendResponse(BaseModel):
    id: int
    user_id: int
    friend_id: int
    friend_username: str
    friend_first_name: str
    friend_last_name: str
    friend_level: int
    friend_total_xp: int
    created_at: datetime

    class Config:
        from_attributes = True

# User Search Response
class UserSearchResponse(BaseModel):
    id: int
    username: str
    first_name: str
    last_name: str
    level: int

    class Config:
        from_attributes = True
```

---

### **Step 3: CRUD Operations**

Create `mental_health_app_backend/app/CRUD/friends.py`:

```python
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from app import models
from typing import List, Optional

# Search users by username or email
def search_users(db: Session, query: str, current_user_id: int, skip: int = 0, limit: int = 10):
    return db.query(models.User).filter(
        models.User.id != current_user_id,
        or_(
            models.User.username.ilike(f"%{query}%"),
            models.User.email.ilike(f"%{query}%")
        )
    ).offset(skip).limit(limit).all()

# Send friend request
def send_friend_request(db: Session, sender_id: int, receiver_username: str):
    # Find receiver
    receiver = db.query(models.User).filter(models.User.username == receiver_username).first()
    if not receiver:
        return None

    # Check if already friends
    existing_friendship = db.query(models.Friendship).filter(
        or_(
            and_(models.Friendship.user_id == sender_id, models.Friendship.friend_id == receiver.id),
            and_(models.Friendship.user_id == receiver.id, models.Friendship.friend_id == sender_id)
        )
    ).first()

    if existing_friendship:
        raise ValueError("Already friends")

    # Check if request already exists
    existing_request = db.query(models.FriendRequest).filter(
        models.FriendRequest.sender_id == sender_id,
        models.FriendRequest.receiver_id == receiver.id,
        models.FriendRequest.status == models.FriendRequestStatus.pending
    ).first()

    if existing_request:
        raise ValueError("Friend request already sent")

    # Create friend request
    friend_request = models.FriendRequest(
        sender_id=sender_id,
        receiver_id=receiver.id,
        status=models.FriendRequestStatus.pending
    )
    db.add(friend_request)
    db.commit()
    db.refresh(friend_request)
    return friend_request

# Get received friend requests
def get_received_requests(db: Session, user_id: int):
    return db.query(models.FriendRequest).filter(
        models.FriendRequest.receiver_id == user_id,
        models.FriendRequest.status == models.FriendRequestStatus.pending
    ).all()

# Get sent friend requests
def get_sent_requests(db: Session, user_id: int):
    return db.query(models.FriendRequest).filter(
        models.FriendRequest.sender_id == user_id,
        models.FriendRequest.status == models.FriendRequestStatus.pending
    ).all()

# Accept friend request
def accept_friend_request(db: Session, request_id: int, user_id: int):
    request = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.receiver_id == user_id
    ).first()

    if not request:
        return None

    # Update request status
    request.status = models.FriendRequestStatus.accepted

    # Create bidirectional friendship
    friendship1 = models.Friendship(user_id=request.sender_id, friend_id=request.receiver_id)
    friendship2 = models.Friendship(user_id=request.receiver_id, friend_id=request.sender_id)

    db.add(friendship1)
    db.add(friendship2)
    db.commit()

    return request

# Reject friend request
def reject_friend_request(db: Session, request_id: int, user_id: int):
    request = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.receiver_id == user_id
    ).first()

    if not request:
        return None

    request.status = models.FriendRequestStatus.rejected
    db.commit()
    return request

# Cancel friend request (sender cancels)
def cancel_friend_request(db: Session, request_id: int, user_id: int):
    request = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.sender_id == user_id
    ).first()

    if not request:
        return None

    db.delete(request)
    db.commit()
    return True

# Get friends list
def get_friends(db: Session, user_id: int):
    return db.query(models.Friendship).filter(
        models.Friendship.user_id == user_id
    ).all()

# Remove friend
def remove_friend(db: Session, user_id: int, friend_id: int):
    # Delete both friendship records (bidirectional)
    db.query(models.Friendship).filter(
        or_(
            and_(models.Friendship.user_id == user_id, models.Friendship.friend_id == friend_id),
            and_(models.Friendship.user_id == friend_id, models.Friendship.friend_id == user_id)
        )
    ).delete()
    db.commit()
    return True
```

---

### **Step 4: API Routes**

Create `mental_health_app_backend/app/routers/friend_routes.py`:

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.auth import get_current_user
from app import models, schemas
from app.CRUD import friends as friends_crud
from typing import List

router = APIRouter(prefix="/friends", tags=["friends"])

# Search users
@router.get("/search", response_model=List[schemas.UserSearchResponse])
def search_users(
    query: str,
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Search for users by username or email"""
    users = friends_crud.search_users(db, query, current_user.id, skip, limit)
    return [
        schemas.UserSearchResponse(
            id=user.id,
            username=user.username,
            first_name=user.first_name,
            last_name=user.last_name,
            level=user.level
        )
        for user in users
    ]

# Send friend request
@router.post("/request", response_model=schemas.FriendRequestResponse)
def send_friend_request(
    request: schemas.FriendRequestCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Send a friend request"""
    try:
        friend_request = friends_crud.send_friend_request(
            db, current_user.id, request.receiver_username
        )
        if not friend_request:
            raise HTTPException(status_code=404, detail="User not found")

        return schemas.FriendRequestResponse(
            id=friend_request.id,
            sender_id=friend_request.sender_id,
            sender_username=current_user.username,
            sender_first_name=current_user.first_name,
            sender_last_name=current_user.last_name,
            receiver_id=friend_request.receiver_id,
            status=friend_request.status.value,
            created_at=friend_request.created_at
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

# Get received requests
@router.get("/requests/received", response_model=List[schemas.FriendRequestResponse])
def get_received_requests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get friend requests received"""
    requests = friends_crud.get_received_requests(db, current_user.id)
    return [
        schemas.FriendRequestResponse(
            id=req.id,
            sender_id=req.sender_id,
            sender_username=req.sender.username,
            sender_first_name=req.sender.first_name,
            sender_last_name=req.sender.last_name,
            receiver_id=req.receiver_id,
            status=req.status.value,
            created_at=req.created_at
        )
        for req in requests
    ]

# Get sent requests
@router.get("/requests/sent", response_model=List[schemas.FriendRequestResponse])
def get_sent_requests(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get friend requests sent"""
    requests = friends_crud.get_sent_requests(db, current_user.id)
    return [
        schemas.FriendRequestResponse(
            id=req.id,
            sender_id=req.sender_id,
            sender_username=req.sender.username,
            sender_first_name=req.sender.first_name,
            sender_last_name=req.sender.last_name,
            receiver_id=req.receiver_id,
            status=req.status.value,
            created_at=req.created_at
        )
        for req in requests
    ]

# Accept friend request
@router.put("/request/{request_id}/accept")
def accept_friend_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Accept a friend request"""
    request = friends_crud.accept_friend_request(db, request_id, current_user.id)
    if not request:
        raise HTTPException(status_code=404, detail="Friend request not found")
    return {"message": "Friend request accepted"}

# Reject friend request
@router.put("/request/{request_id}/reject")
def reject_friend_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Reject a friend request"""
    request = friends_crud.reject_friend_request(db, request_id, current_user.id)
    if not request:
        raise HTTPException(status_code=404, detail="Friend request not found")
    return {"message": "Friend request rejected"}

# Cancel friend request
@router.delete("/request/{request_id}")
def cancel_friend_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Cancel a sent friend request"""
    success = friends_crud.cancel_friend_request(db, request_id, current_user.id)
    if not success:
        raise HTTPException(status_code=404, detail="Friend request not found")
    return {"message": "Friend request cancelled"}

# Get friends
@router.get("/", response_model=List[schemas.FriendResponse])
def get_friends(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Get user's friends list"""
    friendships = friends_crud.get_friends(db, current_user.id)
    return [
        schemas.FriendResponse(
            id=friendship.id,
            user_id=friendship.user_id,
            friend_id=friendship.friend_id,
            friend_username=friendship.friend.username,
            friend_first_name=friendship.friend.first_name,
            friend_last_name=friendship.friend.last_name,
            friend_level=friendship.friend.level,
            friend_total_xp=friendship.friend.total_xp,
            created_at=friendship.created_at
        )
        for friendship in friendships
    ]

# Remove friend
@router.delete("/{friend_id}")
def remove_friend(
    friend_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(get_current_user)
):
    """Remove a friend"""
    friends_crud.remove_friend(db, current_user.id, friend_id)
    return {"message": "Friend removed"}
```

---

### **Step 5: Register Routes**

In `mental_health_app_backend/main.py`, add:

```python
from app.routers import friend_routes

app.include_router(friend_routes.router)
```

---

### **Step 6: Frontend API Service**

Add to `lib/data/services/api_service.dart`:

```dart
// Friend endpoints
Future<List<dynamic>> searchUsers(String query) async {
  final response = await _dio.get('/friends/search', queryParameters: {'query': query});
  return response.data;
}

Future<void> sendFriendRequest(String username) async {
  await _dio.post('/friends/request', data: {'receiver_username': username});
}

Future<List<dynamic>> getFriends() async {
  final response = await _dio.get('/friends/');
  return response.data;
}

Future<List<dynamic>> getReceivedFriendRequests() async {
  final response = await _dio.get('/friends/requests/received');
  return response.data;
}

Future<List<dynamic>> getSentFriendRequests() async {
  final response = await _dio.get('/friends/requests/sent');
  return response.data;
}

Future<void> acceptFriendRequest(int requestId) async {
  await _dio.put('/friends/request/$requestId/accept');
}

Future<void> rejectFriendRequest(int requestId) async {
  await _dio.put('/friends/request/$requestId/reject');
}

Future<void> cancelFriendRequest(int requestId) async {
  await _dio.delete('/friends/request/$requestId');
}

Future<void> removeFriend(int friendId) async {
  await _dio.delete('/friends/$friendId');
}
```

---

### **Step 7: Update Social Screen**

Replace the TODO comments in `social_screen.dart` with actual API calls:

```dart
Future<void> _loadData() async {
  setState(() => _isLoading = true);
  try {
    final friends = await _apiService.getFriends();
    final requests = await _apiService.getReceivedFriendRequests();
    final sent = await _apiService.getSentFriendRequests();

    if (mounted) {
      setState(() {
        _friends = friends;
        _friendRequests = requests;
        _sentRequests = sent;
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error loading social data: $e');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

// Update all the action methods similarly...
```

---

## 🎯 Future Enhancements

1. **Activity Feed**: Share mood logs, achievements with friends
2. **Leaderboards**: Compare XP/levels with friends
3. **Encouragement Messages**: Send supportive messages
4. **Streak Comparisons**: See who has longer streaks
5. **Challenge System**: Create mental health challenges
6. **Real-time Notifications**: Push notifications for requests
7. **Privacy Settings**: Control what friends can see

---

## 📚 Testing Checklist

- [ ] Create database tables
- [ ] Start backend server
- [ ] Test search users endpoint in Swagger
- [ ] Test send friend request
- [ ] Test accept/reject requests
- [ ] Test friends list
- [ ] Test remove friend
- [ ] Update Flutter API service
- [ ] Test social screen navigation
- [ ] Test all friend operations in app

---

## 🔒 Security Considerations

1. **Privacy**: Users should control what friends see
2. **Rate Limiting**: Prevent spam friend requests
3. **Blocking**: Add ability to block users
4. **Report System**: Report inappropriate behavior
5. **Data Encryption**: Sensitive data should be encrypted

---

## 📝 Notes

- The current implementation uses username-based friend search
- You can add email-based search as an alternative
- Consider adding profile pictures in the future
- The UI is ready - just need to connect the backend!

---

**Next Steps**:

1. Create the database tables
2. Add the backend code
3. Test in Swagger
4. Connect frontend API calls
5. Test the full flow!
