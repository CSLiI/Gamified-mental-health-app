from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List
from datetime import datetime, date
from enum import Enum

# Enums
class GenderEnum(str, Enum):
    male = "male"
    female = "female"
    other = "other"

class MoodEnum(str, Enum):
    happy = "happy"
    sad = "sad"
    anxious = "anxious"
    calm = "calm"
    angry = "angry"
    tired = "tired"

class PeriodTypeEnum(str, Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"

# ==================== Users ====================
class UserBase(BaseModel):
    first_name: str
    last_name: Optional[str] = None
    email: EmailStr

class UserCreate(UserBase):
    password_hash: str
    date_of_birth: Optional[date] = None  # Changed from age
    gender: Optional[GenderEnum] = None
    
    @validator('date_of_birth')
    def validate_date_of_birth(cls, v):
        if v is None:
            return v
        if v > date.today():
            raise ValueError('Date of birth cannot be in the future')
        if v.year < 1900:
            raise ValueError('Date of birth must be after 1900')
        # Check if user is at least 13 years old
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        if age < 13:
            raise ValueError('User must be at least 13 years old')
        return v

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    date_of_birth: Optional[date] = None  # Changed from age
    gender: Optional[GenderEnum] = None
    
    @validator('date_of_birth')
    def validate_date_of_birth(cls, v):
        if v is None:
            return v
        if v > date.today():
            raise ValueError('Date of birth cannot be in the future')
        if v.year < 1900:
            raise ValueError('Date of birth must be after 1900')
        return v

class User(UserBase):
    id: int
    auth_provider: str
    provider_id: Optional[str]
    date_of_birth: Optional[date] 
    age: Optional[int] 
    gender: Optional[GenderEnum]
    created_at: datetime
    level: int
    xp: int
    
    class Config:
        from_attributes = True

# ==================== Characters ====================
class CharacterBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None

class CharacterCreate(CharacterBase):
    pass

class Character(CharacterBase):
    id: int
    
    class Config:
        from_attributes = True

# ==================== Interests ====================
class InterestBase(BaseModel):
    name: str

class InterestCreate(InterestBase):
    pass

class Interest(InterestBase):
    id: int
    
    class Config:
        from_attributes = True

# ==================== User Characters ====================
class UserCharacterBase(BaseModel):
    character_id: int

class UserCharacterCreate(UserCharacterBase):
    user_id: int

class UserCharacter(UserCharacterBase):
    id: int
    user_id: int
    chosen_at: datetime
    character: Optional[Character] = None
    
    class Config:
        from_attributes = True

# ==================== Journal Entries ====================
class JournalEntryBase(BaseModel):
    title: Optional[str] = None
    content: str

class JournalEntryCreate(JournalEntryBase):
    pass

class JournalEntryUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None

class JournalEntry(JournalEntryBase):
    id: int
    user_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# ==================== Mood Logs ====================
class MoodLogBase(BaseModel):
    mood: MoodEnum
    note: Optional[str] = None

class MoodLogCreate(MoodLogBase):
    pass

class MoodLog(MoodLogBase):
    id: int
    user_id: int
    logged_at: datetime
    
    class Config:
        from_attributes = True

# ==================== Mood Suggestions ====================
class MoodSuggestionBase(BaseModel):
    mood: MoodEnum
    suggestion: str

class MoodSuggestionCreate(MoodSuggestionBase):
    pass

class MoodSuggestion(MoodSuggestionBase):
    id: int
    
    class Config:
        from_attributes = True

# ==================== Todos ====================
class TodoBase(BaseModel):
    task_text: str
    is_completed: Optional[bool] = False
    period_type: Optional[PeriodTypeEnum] = PeriodTypeEnum.daily

class TodoCreate(TodoBase):
    created_at: Optional[datetime] = None  # Allow specifying creation date

class TodoUpdate(BaseModel):
    task_text: Optional[str] = None
    is_completed: Optional[bool] = None
    period_type: Optional[PeriodTypeEnum] = None

class Todo(TodoBase):
    id: int
    user_id: int
    created_at: datetime
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# ==================== Notifications ====================
class NotificationBase(BaseModel):
    message: str
    scheduled_time: datetime

class NotificationCreate(NotificationBase):
    pass

class Notification(NotificationBase):
    id: int
    user_id: int
    is_sent: bool
    
    class Config:
        from_attributes = True

# ==================== Response Models ====================
class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    email: str

class MoodStatistics(BaseModel):
    total_entries: int
    mood_distribution: dict
    period_days: int

class TodoStatistics(BaseModel):
    total_tasks: int
    completed_tasks: int
    pending_tasks: int
    completion_rate: float

# Add these to your app/schemas.py file

# ==================== Character Schemas ====================
class CharacterUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    image_url: Optional[str] = None

# ==================== Interest Schemas ====================
class InterestUpdate(BaseModel):
    name: Optional[str] = None

# ==================== Achievement Schemas ====================
class AchievementCategoryEnum(str, Enum):
    mood_tracking = "mood_tracking"
    journaling = "journaling"
    consistency = "consistency"
    todos = "todos"
    emotional_growth = "emotional_growth"

class AchievementBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: AchievementCategoryEnum
    icon_url: Optional[str] = None
    xp_reward: int = 0
    requirement_count: int = 1
    is_hidden: bool = False

class AchievementCreate(AchievementBase):
    pass

class Achievement(AchievementBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserAchievementBase(BaseModel):
    achievement_id: int
    progress: int = 0

class UserAchievementCreate(UserAchievementBase):
    user_id: int

class UserAchievement(UserAchievementBase):
    id: int
    user_id: int
    unlocked_at: datetime
    is_claimed: bool
    achievement: Optional[Achievement] = None
    
    class Config:
        from_attributes = True

# ==================== Reward Schemas ====================
class RewardBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str  # cosmetic, pet, accessory, environment
    image_url: Optional[str] = None
    cost_xp: int = 0
    rarity: str = "common"  # common, rare, epic, legendary
    is_limited: bool = False

class RewardCreate(RewardBase):
    pass

class Reward(RewardBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserRewardBase(BaseModel):
    reward_id: int

class UserRewardCreate(UserRewardBase):
    user_id: int

class UserReward(UserRewardBase):
    id: int
    user_id: int
    unlocked_at: datetime
    is_equipped: bool
    reward: Optional[Reward] = None
    
    class Config:
        from_attributes = True

# ==================== Journal Prompt Schemas ====================
class JournalPromptBase(BaseModel):
    prompt_text: str
    mood: Optional[MoodEnum] = None
    category: Optional[str] = None  # gratitude, reflection, cbt, mindfulness
    is_active: bool = True

class JournalPromptCreate(JournalPromptBase):
    pass

class JournalPromptUpdate(BaseModel):
    prompt_text: Optional[str] = None
    mood: Optional[MoodEnum] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None

class JournalPrompt(JournalPromptBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

# ==================== Character Mood State Schema ====================
class CharacterMoodState(BaseModel):
    mood_score: float
    dominant_mood: str
    character_state: str
    environment: str
    total_mood_logs: int
    analysis_period_days: int

# ==================== Collection Stats Schema ====================
class CollectionStats(BaseModel):
    total_unlocked: int
    total_available: int
    completion_percentage: float
    by_category: dict