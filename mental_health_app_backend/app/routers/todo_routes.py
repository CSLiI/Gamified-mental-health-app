from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import todos as todo_crud
from app.CRUD import users as user_crud

router = APIRouter(prefix="/todos", tags=["Todos"])

@router.post("/", response_model=schemas.Todo, status_code=status.HTTP_201_CREATED)
def create_todo(
    todo: schemas.TodoCreate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new todo"""
    return todo_crud.create_todo(db, current_user.id, todo)

@router.get("/", response_model=List[schemas.Todo])
def get_todos(
    skip: int = 0,
    limit: int = 100,
    completed: Optional[bool] = None,
    period_type: Optional[str] = None,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all todos for current user"""
    return todo_crud.get_todos(db, current_user.id, skip, limit, completed, period_type)

@router.get("/statistics", response_model=schemas.TodoStatistics)
def get_todo_statistics(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get todo completion statistics"""
    return todo_crud.get_completion_stats(db, current_user.id)

@router.get("/{todo_id}", response_model=schemas.Todo)
def get_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific todo"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    return todo

@router.put("/{todo_id}", response_model=schemas.Todo)
def update_todo(
    todo_id: int,
    todo_update: schemas.TodoUpdate,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Update a todo"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    
    return todo_crud.update_todo(db, todo_id, todo_update)

@router.post("/{todo_id}/complete")
def complete_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a todo as completed and award XP and Energy"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    
    # Always award XP (since it's deducted on uncomplete)
    xp_earned = 10
    energy_earned = 0
    
    # Get user attached to current session
    user = user_crud.get_user(db, current_user.id)
    if user:
        # Always award XP
        user.xp += xp_earned
        
        # Only award Energy if not already claimed
        if not todo.reward_claimed:
            energy_earned = 5
            user.energy += energy_earned
            todo.reward_claimed = True
            
    # Update todo completion status
    todo.is_completed = True
    todo.completed_at = datetime.utcnow()
    
    # Single commit for XP, energy, and todo updates
    db.commit()
    
    if user:
        db.refresh(user)
    db.refresh(todo)
    
    # Check for level up AFTER committing
    from app.CRUD import level_system
    level_system.check_level_up(db, current_user.id)
    
    # Check for todo achievements
    from app.CRUD import achievements as achievement_crud
    achievement_crud.check_todo_achievements(db, current_user.id)
    
    # Convert to dict for JSON serialization
    todo_dict = schemas.Todo.from_orm(todo).dict()
    
    return {
        "success": True,
        "message": "Todo completed!",
        "todo": todo_dict,
        "xp": xp_earned,
        "energy": energy_earned,
        "new_xp_total": user.xp if user else 0,
        "new_energy_total": user.energy if user else 0
    }

@router.post("/{todo_id}/uncomplete")
def uncomplete_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a todo as not completed (deducts XP, keeps Energy)"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
        
    if todo.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    if not todo.is_completed:
        return {"success": False, "message": "Todo is not completed"}
    
    # Deduct XP (to allow re-earning) but KEEP Energy (one-time reward)
    xp_deducted = 10
    energy_deducted = 0
    
    user = user_crud.get_user(db, current_user.id)
    if user:
        user.xp = max(0, user.xp - xp_deducted)
        # Do NOT deduct energy
    
    todo.is_completed = False
    todo.completed_at = None
    
    db.commit()
    
    if user:
        db.refresh(user)
    db.refresh(todo)
    
    return {
        "success": True, 
        "message": "Todo marked as incomplete",
        "xp": -xp_deducted,
        "energy": 0
    }

@router.delete("/{todo_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a todo"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    
    todo_crud.delete_todo(db, todo_id)
    return None
