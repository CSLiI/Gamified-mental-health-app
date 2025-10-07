from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import interests as interest_crud

router = APIRouter(prefix="/interests", tags=["Interests"])

# ==================== Interest Management ====================
@router.post("/", response_model=schemas.Interest, status_code=status.HTTP_201_CREATED)
def create_interest(
    interest: schemas.InterestCreate,
    db: Session = Depends(get_db)
):
    """Create a new interest"""
    return interest_crud.create_interest(db, interest)

@router.post("/bulk", response_model=List[schemas.Interest], status_code=status.HTTP_201_CREATED)
def create_bulk_interests(
    interest_names: List[str],
    db: Session = Depends(get_db)
):
    """Create multiple interests at once"""
    return interest_crud.create_bulk_interests(db, interest_names)

@router.get("/", response_model=List[schemas.Interest])
def get_all_interests(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all interests"""
    return interest_crud.get_all_interests(db, skip, limit)

@router.get("/search", response_model=List[schemas.Interest])
def search_interests(
    q: str = Query(..., min_length=1, description="Search term"),
    db: Session = Depends(get_db)
):
    """Search interests by name"""
    return interest_crud.search_interests(db, q)

@router.get("/popular")
def get_popular_interests(
    limit: int = 10,
    db: Session = Depends(get_db)
):
    """Get most popular interests by user count"""
    return interest_crud.get_popular_interests(db, limit)

@router.get("/{interest_id}", response_model=schemas.Interest)
def get_interest(
    interest_id: int,
    db: Session = Depends(get_db)
):
    """Get a specific interest"""
    interest = interest_crud.get_interest(db, interest_id)
    if not interest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interest not found"
        )
    return interest

@router.get("/{interest_id}/users-count")
def get_interest_users_count(
    interest_id: int,
    db: Session = Depends(get_db)
):
    """Get count of users with this interest"""
    count = interest_crud.get_interest_user_count(db, interest_id)
    return {"interest_id": interest_id, "user_count": count}

@router.put("/{interest_id}", response_model=schemas.Interest)
def update_interest(
    interest_id: int,
    interest_update: schemas.InterestUpdate,
    db: Session = Depends(get_db)
):
    """Update an interest"""
    interest = interest_crud.update_interest(db, interest_id, interest_update)
    if not interest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interest not found"
        )
    return interest

@router.delete("/{interest_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_interest(
    interest_id: int,
    db: Session = Depends(get_db)
):
    """Delete an interest"""
    interest = interest_crud.delete_interest(db, interest_id)
    if not interest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Interest not found"
        )
    return None