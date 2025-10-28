from sqlalchemy.orm import Session
from app import models, schemas
from datetime import datetime
from typing import Optional

def create_todo(db: Session, user_id: int, todo: schemas.TodoCreate):
    """Create a new todo for a user"""
    db_todo = models.Todo(
        user_id=user_id,
        task_text=todo.task_text,
        is_completed=todo.is_completed,
        period_type=todo.period_type
    )
    
    # If created_at is provided, use it (for scheduling tasks on specific dates)
    if todo.created_at:
        db_todo.created_at = todo.created_at
    
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    return db_todo

def get_todos(db: Session, user_id: int, skip: int = 0, limit: int = 100, completed: Optional[bool] = None, period_type: Optional[str] = None):
    """Get all todos for a user"""
    query = db.query(models.Todo).filter(models.Todo.user_id == user_id)
    
    if completed is not None:
        query = query.filter(models.Todo.is_completed == completed)
    
    if period_type is not None:
        # Handle both null values (old data) and the specified period_type
        query = query.filter(
            (models.Todo.period_type == period_type) | 
            (models.Todo.period_type == None)
        )
    
    return query.order_by(models.Todo.created_at.desc()).offset(skip).limit(limit).all()

def get_todo(db: Session, todo_id: int):
    """Get a specific todo"""
    return db.query(models.Todo).filter(models.Todo.id == todo_id).first()

def update_todo(db: Session, todo_id: int, todo_update: schemas.TodoUpdate):
    """Update a todo"""
    todo = db.query(models.Todo).filter(models.Todo.id == todo_id).first()
    if not todo:
        return None
    
    update_data = todo_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(todo, key, value)
    
    # If marking as completed, set completion timestamp
    if update_data.get('is_completed') and not todo.completed_at:
        todo.completed_at = datetime.utcnow()
    elif update_data.get('is_completed') == False:
        todo.completed_at = None
    
    db.commit()
    db.refresh(todo)
    return todo

def delete_todo(db: Session, todo_id: int):
    """Delete a todo"""
    todo = db.query(models.Todo).filter(models.Todo.id == todo_id).first()
    if todo:
        db.delete(todo)
        db.commit()
    return todo

def complete_todo(db: Session, todo_id: int):
    """Mark a todo as completed"""
    todo = db.query(models.Todo).filter(models.Todo.id == todo_id).first()
    if not todo:
        return None
    
    todo.is_completed = True
    todo.completed_at = datetime.utcnow()
    
    db.commit()
    db.refresh(todo)
    return todo

def uncomplete_todo(db: Session, todo_id: int):
    """Mark a todo as incomplete"""
    todo = db.query(models.Todo).filter(models.Todo.id == todo_id).first()
    if not todo:
        return None
    
    todo.is_completed = False
    todo.completed_at = None
    
    db.commit()
    db.refresh(todo)
    return todo

def get_completion_stats(db: Session, user_id: int):
    """Get todo completion statistics"""
    total = db.query(models.Todo).filter(models.Todo.user_id == user_id).count()
    completed = db.query(models.Todo).filter(
        models.Todo.user_id == user_id,
        models.Todo.is_completed == True
    ).count()
    
    return {
        "total_tasks": total,
        "completed_tasks": completed,
        "pending_tasks": total - completed,
        "completion_rate": (completed / total * 100) if total > 0 else 0
    }