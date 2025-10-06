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