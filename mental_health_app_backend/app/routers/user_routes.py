from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import users as user_crud

router = APIRouter(prefix="/users", tags=["Users"])

@router.get("/me", response_model=schemas.User)
def get_current_user(current_user: models.User = Depends(auth.get_current_user)):
    """Get current user profile"""
    return current_user

@router.put("/me", response_model=schemas.User)
def update_current_user(
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user profile"""
    return user_crud.update_user(db, current_user.id, user_update)

@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_current_user(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Delete current user account"""
    user_crud.delete_user(db, current_user.id)
    return None

# ==================== User Interests ====================
@router.get("/me/interests", response_model=List[schemas.Interest])
def get_my_interests(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's interests"""
    return user_crud.get_user_interests(db, current_user.id)

@router.post("/me/interests/{interest_id}", status_code=status.HTTP_201_CREATED)
def add_interest_to_user(
    interest_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Add an interest to current user"""
    success = user_crud.add_user_interest(db, current_user.id, interest_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interest not found"
        )
    return {"message": "Interest added successfully"}

@router.delete("/me/interests/{interest_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_interest_from_user(
    interest_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Remove an interest from current user"""
    success = user_crud.remove_user_interest(db, current_user.id, interest_id)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interest not found or not associated with user"
        )
    return None

@router.put("/me/interests", status_code=status.HTTP_200_OK)
def update_my_interests(
    interest_ids: List[int],
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's interests (replaces all existing interests)"""
    success = user_crud.update_user_interests(db, current_user.id, interest_ids)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update interests"
        )
    return {"message": "Interests updated successfully"}

@router.get("/{user_id}/interests", response_model=List[schemas.Interest])
def get_user_interests(
    user_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get interests for a specific user (for viewing friend profiles)"""
    return user_crud.get_user_interests(db, user_id)