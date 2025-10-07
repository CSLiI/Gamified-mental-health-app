"""
Seed script to populate database with initial data
Run this after database migration to add default content
"""

from app.database import SessionLocal
from app import models, schemas
from app.CRUD import (
    characters as char_crud,
    interests as interest_crud,
    achievements as achievement_crud,
    rewards as reward_crud,
    journal_prompts as prompt_crud
)

def seed_characters(db):
    """Seed default characters"""
    print("Seeding characters...")
    characters = [
        {
            "name": "Buddy",
            "description": "A loyal companion who grows with your emotional journey",
            "image_url": "/assets/characters/buddy.png"
        },
        {
            "name": "Luna",
            "description": "A calm and peaceful guide through mindfulness",
            "image_url": "/assets/characters/luna.png"
        },
        {
            "name": "Spark",
            "description": "An energetic friend who celebrates your victories",
            "image_url": "/assets/characters/spark.png"
        },
        {
            "name": "Zen",
            "description": "A wise companion focused on inner peace",
            "image_url": "/assets/characters/zen.png"
        }
    ]
    
    created = 0
    for char_data in characters:
        existing = char_crud.get_character_by_name(db, char_data["name"])
        if not existing:
            char_crud.create_character(db, schemas.CharacterCreate(**char_data))
            created += 1
    
    print(f"✓ Created {created} characters")

def seed_interests(db):
    """Seed default interests"""
    print("Seeding interests...")
    interests = [
        "Gaming", "Reading", "Music", "Sports", "Art", "Coding",
        "Meditation", "Photography", "Cooking", "Travel", "Fitness",
        "Movies", "Writing", "Dancing", "Yoga", "Nature", "Podcasts",
        "Fashion", "Science", "History", "Anime", "Board Games"
    ]
    
    created = interest_crud.create_bulk_interests(db, interests)
    print(f"✓ Created {len(created)} interests")

def seed_achievements(db):
    """Seed default achievements"""
    print("Seeding achievements...")
    achievements = [
        # Mood Tracking Achievements
        {
            "name": "First Steps",
            "description": "Log your first mood",
            "category": "mood_tracking",
            "xp_reward": 10,
            "requirement_count": 1,
            "icon_url": "/assets/achievements/first_mood.png"
        },
        {
            "name": "Self-Aware",
            "description": "Log 7 moods",
            "category": "mood_tracking",
            "xp_reward": 25,
            "requirement_count": 7,
            "icon_url": "/assets/achievements/seven_moods.png"
        },
        {
            "name": "Emotion Tracker",
            "description": "Log 30 moods",
            "category": "mood_tracking",
            "xp_reward": 50,
            "requirement_count": 30,
            "icon_url": "/assets/achievements/thirty_moods.png"
        },
        {
            "name": "Mood Master",
            "description": "Log 100 moods",
            "category": "mood_tracking",
            "xp_reward": 100,
            "requirement_count": 100,
            "icon_url": "/assets/achievements/hundred_moods.png"
        },
        
        # Journaling Achievements
        {
            "name": "Dear Diary",
            "description": "Write your first journal entry",
            "category": "journaling",
            "xp_reward": 15,
            "requirement_count": 1,
            "icon_url": "/assets/achievements/first_journal.png"
        },
        {
            "name": "Reflective Writer",
            "description": "Write 10 journal entries",
            "category": "journaling",
            "xp_reward": 30,
            "requirement_count": 10,
            "icon_url": "/assets/achievements/ten_journals.png"
        },
        {
            "name": "Story Teller",
            "description": "Write 50 journal entries",
            "category": "journaling",
            "xp_reward": 75,
            "requirement_count": 50,
            "icon_url": "/assets/achievements/fifty_journals.png"
        },
        
        # Consistency Achievements
        {
            "name": "Building Habits",
            "description": "Maintain a 3-day streak",
            "category": "consistency",
            "xp_reward": 20,
            "requirement_count": 3,
            "icon_url": "/assets/achievements/three_streak.png"
        },
        {
            "name": "Week Warrior",
            "description": "Maintain a 7-day streak",
            "category": "consistency",
            "xp_reward": 50,
            "requirement_count": 7,
            "icon_url": "/assets/achievements/seven_streak.png"
        },
        {
            "name": "Monthly Master",
            "description": "Maintain a 30-day streak",
            "category": "consistency",
            "xp_reward": 150,
            "requirement_count": 30,
            "icon_url": "/assets/achievements/thirty_streak.png"
        },
        
        # Todo Achievements
        {
            "name": "Task Tackler",
            "description": "Complete your first todo",
            "category": "todos",
            "xp_reward": 10,
            "requirement_count": 1,
            "icon_url": "/assets/achievements/first_todo.png"
        },
        {
            "name": "Productivity Pro",
            "description": "Complete 25 todos",
            "category": "todos",
            "xp_reward": 40,
            "requirement_count": 25,
            "icon_url": "/assets/achievements/twentyfive_todos.png"
        },
        
        # Emotional Growth
        {
            "name": "Growing Strong",
            "description": "Reach character state 'thriving' for 7 days",
            "category": "emotional_growth",
            "xp_reward": 100,
            "requirement_count": 7,
            "icon_url": "/assets/achievements/thriving.png",
            "is_hidden": True
        }
    ]
    
    created = 0
    for achievement_data in achievements:
        try:
            achievement_crud.create_achievement(db, schemas.AchievementCreate(**achievement_data))
            created += 1
        except Exception as e:
            print(f"  Warning: Could not create achievement '{achievement_data['name']}': {e}")
    
    print(f"✓ Created {created} achievements")

def seed_rewards(db):
    """Seed default rewards"""
    print("Seeding rewards...")
    rewards = [
        # Cosmetic Rewards
        {
            "name": "Rainbow Aura",
            "description": "A colorful aura that surrounds your character",
            "category": "cosmetic",
            "cost_xp": 50,
            "rarity": "common",
            "image_url": "/assets/rewards/rainbow_aura.png"
        },
        {
            "name": "Golden Crown",
            "description": "A shiny crown for the dedicated",
            "category": "cosmetic",
            "cost_xp": 100,
            "rarity": "rare",
            "image_url": "/assets/rewards/golden_crown.png"
        },
        {
            "name": "Sparkle Effect",
            "description": "Your character sparkles with positivity",
            "category": "cosmetic",
            "cost_xp": 150,
            "rarity": "epic",
            "image_url": "/assets/rewards/sparkle.png"
        },
        
        # Pet Rewards
        {
            "name": "Baby Dragon",
            "description": "A tiny dragon companion",
            "category": "pet",
            "cost_xp": 200,
            "rarity": "epic",
            "image_url": "/assets/rewards/baby_dragon.png"
        },
        {
            "name": "Spirit Fox",
            "description": "A mystical fox friend",
            "category": "pet",
            "cost_xp": 180,
            "rarity": "rare",
            "image_url": "/assets/rewards/spirit_fox.png"
        },
        {
            "name": "Butterfly Swarm",
            "description": "Beautiful butterflies follow you",
            "category": "pet",
            "cost_xp": 120,
            "rarity": "rare",
            "image_url": "/assets/rewards/butterflies.png"
        },
        
        # Environment Rewards
        {
            "name": "Cherry Blossom Garden",
            "description": "A peaceful garden environment",
            "category": "environment",
            "cost_xp": 250,
            "rarity": "epic",
            "image_url": "/assets/rewards/cherry_garden.png"
        },
        {
            "name": "Starry Night Sky",
            "description": "A beautiful night sky background",
            "category": "environment",
            "cost_xp": 300,
            "rarity": "legendary",
            "image_url": "/assets/rewards/starry_night.png"
        },
        {
            "name": "Cozy Fireplace",
            "description": "A warm, comforting setting",
            "category": "environment",
            "cost_xp": 150,
            "rarity": "rare",
            "image_url": "/assets/rewards/fireplace.png"
        },
        
        # Accessory Rewards
        {
            "name": "Meditation Beads",
            "description": "Calming beads for mindfulness",
            "category": "accessory",
            "cost_xp": 80,
            "rarity": "common",
            "image_url": "/assets/rewards/beads.png"
        },
        {
            "name": "Wisdom Glasses",
            "description": "Stylish glasses of insight",
            "category": "accessory",
            "cost_xp": 90,
            "rarity": "common",
            "image_url": "/assets/rewards/glasses.png"
        },
        {
            "name": "Hero Cape",
            "description": "You're your own hero",
            "category": "accessory",
            "cost_xp": 200,
            "rarity": "epic",
            "image_url": "/assets/rewards/cape.png"
        }
    ]
    
    created = 0
    for reward_data in rewards:
        try:
            reward_crud.create_reward(db, schemas.RewardCreate(**reward_data))
            created += 1
        except Exception as e:
            print(f"  Warning: Could not create reward '{reward_data['name']}': {e}")
    
    print(f"✓ Created {created} rewards")

def seed_journal_prompts(db):
    """Seed default journal prompts"""
    print("Seeding journal prompts...")
    created = prompt_crud.seed_default_prompts(db)
    print(f"✓ Created {len(created)} journal prompts")

def main():
    """Main seeding function"""
    print("\n" + "="*50)
    print("SEEDING DATABASE WITH INITIAL DATA")
    print("="*50 + "\n")
    
    db = SessionLocal()
    
    try:
        seed_characters(db)
        seed_interests(db)
        seed_achievements(db)
        seed_rewards(db)
        seed_journal_prompts(db)
        
        print("\n" + "="*50)
        print("✓ SEEDING COMPLETED SUCCESSFULLY!")
        print("="*50 + "\n")
        
    except Exception as e:
        print(f"\n❌ Error during seeding: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    main()