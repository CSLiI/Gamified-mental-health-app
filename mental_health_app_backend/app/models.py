from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey, Enum as SQLEnum, Text, CheckConstraint, Table, Date
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from sqlalchemy.ext.hybrid import hybrid_property
from app.database import Base
from datetime import date
import enum

# Enums matching your PostgreSQL enums
class GenderEnum(str, enum.Enum):
    male = "male"
    female = "female"
    other = "other"

class MoodEnum(str, enum.Enum):
    happy = "happy"
    sad = "sad"
    anxious = "anxious"
    calm = "calm"
    angry = "angry"
    tired = "tired"

class PeriodTypeEnum(str, enum.Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"

# Users table
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100))
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(Text)
    auth_provider = Column(String(50), default='email')
    provider_id = Column(Text)
    date_of_birth = Column(Date) 
    gender = Column(SQLEnum(GenderEnum))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    level = Column(Integer, default=1)
    xp = Column(Integer, default=0)
    
    # Relationships
    user_characters = relationship("UserCharacter", back_populates="user", cascade="all, delete-orphan")
    user_interests = relationship("Interest", secondary="user_interests", back_populates="users")
    journal_entries = relationship("JournalEntry", back_populates="user", cascade="all, delete-orphan")
    mood_logs = relationship("MoodLog", back_populates="user", cascade="all, delete-orphan")
    todos = relationship("Todo", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    
    @hybrid_property
    def age(self):
        """Calculate age from date of birth"""
        if self.date_of_birth is None:
            return None
        
        today = date.today()
        age = today.year - self.date_of_birth.year
        
        if today.month < self.date_of_birth.month or \
           (today.month == self.date_of_birth.month and today.day < self.date_of_birth.day):
            age -= 1
        
        return age
    
    def is_birthday_today(self):
        """Check if today is the user's birthday"""
        if self.date_of_birth is None:
            return False
        
        today = date.today()
        return (today.month == self.date_of_birth.month and 
                today.day == self.date_of_birth.day)
# Characters table
class Character(Base):
    __tablename__ = "characters"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    image_url = Column(Text)
    gender = Column(String(20))  # 'Boy' or 'Girl'
    number = Column(Integer)  # 1, 2, 3, etc.
    
    # Relationships
    user_characters = relationship("UserCharacter", back_populates="character", cascade="all, delete-orphan")

# Interests table
class Interest(Base):
    __tablename__ = "interests"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    
    # Relationships
    users = relationship("User", secondary="user_interests", back_populates="user_interests")

# User Characters table (many-to-many with metadata)
class UserCharacter(Base):
    __tablename__ = "user_characters"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    character_id = Column(Integer, ForeignKey("characters.id", ondelete="CASCADE"), nullable=False)
    chosen_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="user_characters")
    character = relationship("Character", back_populates="user_characters")

# User Interests table (many-to-many association table)
user_interests_table = Table(
    'user_interests',
    Base.metadata,
    Column('user_id', Integer, ForeignKey('users.id', ondelete='CASCADE'), primary_key=True),
    Column('interest_id', Integer, ForeignKey('interests.id', ondelete='CASCADE'), primary_key=True)
)

# Journal Entries table
class JournalEntry(Base):
    __tablename__ = "journal_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    title = Column(String(200))
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="journal_entries")

# Mood Logs table
class MoodLog(Base):
    __tablename__ = "mood_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    mood = Column(SQLEnum(MoodEnum), nullable=False)
    note = Column(Text)
    logged_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User", back_populates="mood_logs")

# Mood Suggestions table
class MoodSuggestion(Base):
    __tablename__ = "mood_suggestions"
    
    id = Column(Integer, primary_key=True, index=True)
    mood = Column(SQLEnum(MoodEnum), nullable=False)
    suggestion = Column(Text, nullable=False)

# Todos table
class Todo(Base):
    __tablename__ = "todos"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    task_text = Column(Text, nullable=False)
    is_completed = Column(Boolean, default=False)
    period_type = Column(SQLEnum(PeriodTypeEnum), default=PeriodTypeEnum.daily, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    completed_at = Column(DateTime(timezone=True))
    
    # Relationships
    user = relationship("User", back_populates="todos")

# Notifications table
class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    message = Column(Text)
    scheduled_time = Column(DateTime(timezone=True))
    is_sent = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", back_populates="notifications")

# Add these classes to your app/models.py file

class AchievementCategory(str, enum.Enum):
    mood_tracking = "mood_tracking"
    journaling = "journaling"
    consistency = "consistency"
    todos = "todos"
    emotional_growth = "emotional_growth"

class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False, unique=True)
    description = Column(Text)
    category = Column(SQLEnum(AchievementCategory), nullable=False)
    icon_url = Column(Text)
    xp_reward = Column(Integer, default=0)
    requirement_count = Column(Integer, default=1)
    is_hidden = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user_achievements = relationship("UserAchievement", back_populates="achievement", cascade="all, delete-orphan")

class UserAchievement(Base):
    __tablename__ = "user_achievements"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(Integer, ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False)
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now())
    progress = Column(Integer, default=0)
    is_claimed = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", backref="achievements")
    achievement = relationship("Achievement", back_populates="user_achievements")

class Reward(Base):
    __tablename__ = "rewards"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text)
    category = Column(String(50))  # cosmetic, pet, accessory, environment
    image_url = Column(Text)
    cost_xp = Column(Integer, default=0)
    rarity = Column(String(20))  # common, rare, epic, legendary
    is_limited = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user_rewards = relationship("UserReward", back_populates="reward", cascade="all, delete-orphan")

class UserReward(Base):
    __tablename__ = "user_rewards"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    reward_id = Column(Integer, ForeignKey("rewards.id", ondelete="CASCADE"), nullable=False)
    unlocked_at = Column(DateTime(timezone=True), server_default=func.now())
    is_equipped = Column(Boolean, default=False)
    
    # Relationships
    user = relationship("User", backref="rewards")
    reward = relationship("Reward", back_populates="user_rewards")

class JournalPrompt(Base):
    __tablename__ = "journal_prompts"
    
    id = Column(Integer, primary_key=True, index=True)
    prompt_text = Column(Text, nullable=False)
    mood = Column(SQLEnum(MoodEnum))
    category = Column(String(50))  # gratitude, reflection, cbt, mindfulness
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class FriendRequestStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

# Friendship table (many-to-many relationship)
class Friendship(Base):
    __tablename__ = "friendships"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    friend_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", foreign_keys=[user_id], backref="friendships")
    friend = relationship("User", foreign_keys=[friend_id])

# Friend Request table
class FriendRequest(Base):
    __tablename__ = "friend_requests"

    id = Column(Integer, primary_key=True, index=True)
    sender_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    receiver_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    status = Column(SQLEnum(FriendRequestStatus), default=FriendRequestStatus.pending, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id], backref="sent_requests")
    receiver = relationship("User", foreign_keys=[receiver_id], backref="received_requests")
    
# Update User model to include relationships (add these lines to User class):
# user_achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")
# user_rewards = relationship("UserReward", back_populates="user", cascade="all, delete-orphan")
