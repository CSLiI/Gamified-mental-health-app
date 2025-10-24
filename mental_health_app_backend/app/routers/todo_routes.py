from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
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
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Get all todos for current user"""
    return todo_crud.get_todos(db, current_user.id, skip, limit, completed)

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

@router.post("/{todo_id}/complete", response_model=schemas.Todo)
def complete_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a todo as completed and award XP"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    
    # Mark todo as complete
    completed_todo = todo_crud.complete_todo(db, todo_id)
    
    # Award XP (10 XP per completed todo)
    user_crud.update_user_xp(db, current_user.id, 10)
    
    return completed_todo

@router.post("/{todo_id}/uncomplete", response_model=schemas.Todo)
def uncomplete_todo(
    todo_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(get_db)
):
    """Mark a todo as incomplete and deduct XP"""
    todo = todo_crud.get_todo(db, todo_id)
    if not todo or todo.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Todo not found"
        )
    
    # Only deduct XP if the todo was actually completed before
    if todo.is_completed:
        # Deduct XP (10 XP per uncompleted todo)
        user_crud.update_user_xp(db, current_user.id, -10)
    
    # Mark todo as incomplete
    uncompleted_todo = todo_crud.uncomplete_todo(db, todo_id)
    
    return uncompleted_todo

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