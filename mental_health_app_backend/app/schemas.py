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

class QuestDifficultyEnum(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"

class QuestCategoryEnum(str, Enum):
    mood = "mood"
    journal = "journal"
    social = "social"
    streak = "streak"
    general = "general"

from app.utils.profanity import contains_profanity

# ==================== Users ====================
class UserBase(BaseModel):
    first_name: str
    last_name: Optional[str] = None
    email: EmailStr
    
    @validator('first_name', 'last_name')
    def validate_no_profanity_name(cls, v):
        if v and contains_profanity(v):
            raise ValueError('Name contains inappropriate language.')
        return v

class UserCreate(UserBase):
    password_hash: str
    date_of_birth: Optional[date] = None
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
    date_of_birth: Optional[date] = None
    gender: Optional[GenderEnum] = None
    
    @validator('first_name', 'last_name')
    def validate_no_profanity_update(cls, v):
        if v and contains_profanity(v):
            raise ValueError('Name contains inappropriate language.')
        return v
    
    @validator('date_of_birth')
    def validate_date_of_birth(cls, v):
        if v is None:
            return v
        if v > date.today():
             raise ValueError('Date of birth cannot be in the future')
        if v.year < 1900:
             raise ValueError('Date of birth must be after 1900')
        return v

# ... [User Class remains same] ...

# ==================== Encouragements ====================
class EncouragementCreate(BaseModel):
    message: str
    
    @validator('message')
    def validate_clean_message(cls, v):
        if contains_profanity(v):
            raise ValueError('Message contains inappropriate language.')
        return v

# ...

# ==================== Messages ====================
class MessageCreate(BaseModel):
    message: str

    @validator('message')
    def validate_clean_message(cls, v):
        if contains_profanity(v):
            raise ValueError('Message contains inappropriate language.')
        return v

# ...

# ==================== Pet Schemas ====================
class PetBase(BaseModel):
    name: str
    emoji: str
    description: Optional[str] = None
    unlock_level: int = 1
    rarity: str = "common"
    lottie_file: Optional[str] = None
    
    @validator('name', 'description')
    def validate_clean_pet(cls, v):
        if v and contains_profanity(v):
            raise ValueError('Contains inappropriate language.')
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
    energy: int = 50
    
    # Daily check-in and streak tracking
    last_daily_claim: Optional[datetime] = None
    current_streak: int = 0
    longest_streak: int = 0
    total_daily_claims: int = 0
    streak_freeze_available: bool = False
    streak_freeze_used_this_week: bool = False
    
    class Config:
        from_attributes = True

# ==================== Characters ====================
class CharacterBase(BaseModel):
    name: str
    description: Optional[str] = None
    image_url: Optional[str] = None
    gender: Optional[str] = None
    number: Optional[int] = None

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
    reward_claimed: bool = False
    
    # Quest fields to allow filtering on frontend
    is_quest: bool = False
    category: Optional[QuestCategoryEnum] = None
    difficulty: Optional[QuestDifficultyEnum] = None
    
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
    social = "social"
    special = "special"

class AchievementBase(BaseModel):
    name: str
    description: Optional[str] = None
    category: str
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

# ==================== Friend Request Schemas ======================
class FriendRequestCreate(BaseModel):
    receiver_email: str  # Email of the user to send request to

class FriendRequestResponse(BaseModel):
    id: int
    sender_id: int
    sender_email: str
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
    friend_email: str
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
    email: str
    first_name: str
    last_name: str
    level: int

    class Config:
        from_attributes = True

# ==================== Encouragements ====================
class EncouragementCreate(BaseModel):
    message: str

class EncouragementResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    sender_first_name: str
    sender_last_name: str
    message: str
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True

# ==================== Messages ====================
class MessageCreate(BaseModel):
    message: str

class MessageResponse(BaseModel):
    id: int
    sender_id: int
    receiver_id: int
    sender_first_name: Optional[str] = None
    sender_last_name: Optional[str] = None
    message: str
    is_read: bool
    is_completed: bool = False  # For marking challenges as completed
    created_at: datetime

    class Config:
        from_attributes = True

# ==================== User Profile ====================
class UserProfileResponse(BaseModel):
    id: int
    email: str
    first_name: str
    last_name: str
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    level: int = 1
    xp: int = 0
    energy: int = 50
    current_streak: int = 0
    longest_streak: int = 0
    character: Optional[dict] = None
    interests: Optional[List[dict]] = None

    class Config:
        from_attributes = True

# ==================== Daily Rewards ====================
class DailyStatusResponse(BaseModel):
    can_claim: bool
    current_streak: int
    last_claim_date: Optional[str] = None
    total_claims: int
    longest_streak: int

class DailyClaimResponse(BaseModel):
    success: bool
    xp_earned: Optional[int] = None
    base_xp: Optional[int] = None
    streak_bonus: Optional[int] = None
    milestone_bonus: Optional[int] = None
    milestone_message: Optional[str] = None
    new_streak: Optional[int] = None
    total_xp: Optional[int] = None
    total_claims: Optional[int] = None
    message: Optional[str] = None
    streak: Optional[int] = None

class CalendarDay(BaseModel):
    date: str
    claimed: bool
    is_today: bool

class DailyCalendarResponse(BaseModel):
    days: List[CalendarDay]
    current_streak: int
    longest_streak: int

class StreakFreezeResponse(BaseModel):
    freeze_available: bool
    freeze_used_this_week: bool

class StreakFreezeUseResponse(BaseModel):
    success: bool
    message: str
    streak_protected: Optional[int] = None


# ==================== Builtin Rewards ====================

class BuiltinRewardPurchase(BaseModel):
    reward_id: int
    category: str  # themes, banners, frames, profile_items
    xp_cost: int

class BuiltinRewardEquip(BaseModel):
    reward_id: int
    category: str

class BuiltinUserRewardResponse(BaseModel):
    id: int
    user_id: int
    reward_id: int
    category: str
    purchased_at: datetime
    
    class Config:
        from_attributes = True

class BuiltinEquippedRewardResponse(BaseModel):
    id: int
    user_id: int
    reward_id: int
    category: str
    equipped_at: datetime
    
    class Config:
        from_attributes = True

class BuiltinRewardsDataResponse(BaseModel):
    purchased: List[BuiltinUserRewardResponse]
    equipped: List[BuiltinEquippedRewardResponse]
    xp_spent: int

# ==================== Pet Schemas ====================
class PetBase(BaseModel):
    name: str
    emoji: str
    description: Optional[str] = None
    unlock_level: int = 1
    rarity: str = "common"
    lottie_file: Optional[str] = None

class PetResponse(PetBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserPetResponse(BaseModel):
    id: int
    name: str
    emoji: str
    description: Optional[str] = None
    rarity: str
    lottie_file: Optional[str] = None
    is_active: bool
    affection_level: int
    hunger: int
    last_fed_at: Optional[datetime]
    unlocked_at: datetime

class PetUnlockResponse(BaseModel):
    success: bool
    message: str
    pet: Optional[dict] = None

class PetEquipResponse(BaseModel):
    success: bool
    message: str
    active_pet: Optional[dict] = None

class PetInteractResponse(BaseModel):
    success: bool
    message: str
    affection_gained: int = 1

class PetFeedResponse(BaseModel):
    success: bool
    message: str
    hunger_gained: int = 10
    new_hunger: int

