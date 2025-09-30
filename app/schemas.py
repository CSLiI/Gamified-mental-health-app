# schemas.py
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from enum import Enum

class GenderEnum(str, Enum):
    male = "male"
    female = "female"
    other = "other"

class MoodEnum(str, Enum):
    happy = "happy"
    sad = "sad"
    stressed = "stressed"
    angry = "angry"
    calm = "calm"
    anxious = "anxious"
    tired = "tired"
    excited = "excited"

# ----- Users -----
class UserBase(BaseModel):
    first_name: str
    last_name: Optional[str]
    email: str

class UserCreate(UserBase):
    password_hash: str

class User(UserBase):
    id: int
    gender: Optional[GenderEnum]
    age: Optional[int]
    level: int
    xp: int
    class Config:
        orm_mode = True

# ----- Mood Logs -----
class MoodLogBase(BaseModel):
    mood: MoodEnum
    note: Optional[str] = None

class MoodLogCreate(MoodLogBase):
    user_id: int

class MoodLog(MoodLogBase):
    id: int
    user_id: int
    logged_at: datetime
    class Config:
        orm_mode = True

# ----- Todos -----
class TodoBase(BaseModel):
    task_text: str
    is_completed: Optional[bool] = False

class TodoCreate(TodoBase):
    user_id: int

class Todo(TodoBase):
    id: int
    user_id: int
    created_at: datetime
    completed_at: Optional[datetime]
    class Config:
        orm_mode = True
