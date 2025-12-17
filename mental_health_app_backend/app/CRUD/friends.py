from sqlalchemy.orm import Session
from sqlalchemy import or_, and_
from sqlalchemy.orm import joinedload
from app import models
from typing import List, Optional

# Search users by email or name
def search_users(db: Session, query: str, current_user_id: int, skip: int = 0, limit: int = 10):
    return db.query(models.User).filter(
        models.User.id != current_user_id,
        or_(
            models.User.first_name.ilike(f"%{query}%"),
            models.User.last_name.ilike(f"%{query}%"),
            models.User.email.ilike(f"%{query}%")
        )
    ).offset(skip).limit(limit).all()

# Send friend request
def send_friend_request(db: Session, sender_id: int, receiver_email: str):
    # Find receiver by email
    receiver = db.query(models.User).filter(models.User.email == receiver_email).first()
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
    return db.query(models.Friendship).options(
        joinedload(models.Friendship.friend)
    ).filter(
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