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
    """Search for users by email or name"""
    users = friends_crud.search_users(db, query, current_user.id, skip, limit)
    return [
        schemas.UserSearchResponse(
            id=user.id,
            email=user.email,
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
            db, current_user.id, request.receiver_email
        )
        if not friend_request:
            raise HTTPException(status_code=404, detail="User not found")

        return schemas.FriendRequestResponse(
            id=friend_request.id,
            sender_id=friend_request.sender_id,
            sender_email=current_user.email,
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
            sender_email=req.sender.email,
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
            sender_email=req.receiver.email,
            sender_first_name=req.receiver.first_name,
            sender_last_name=req.receiver.last_name,
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
            friend_email=friendship.friend.email,
            friend_first_name=friendship.friend.first_name,
            friend_last_name=friendship.friend.last_name,
            friend_level=friendship.friend.level,
            friend_total_xp=friendship.friend.xp,
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
