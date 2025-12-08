"""
Add new achievements to the database
Run this script to add additional achievements beyond the initial seed
"""

from app.database import SessionLocal
from app import schemas, models
from app.CRUD import achievements as achievement_crud

new_achievements = [
    # More Streak Achievements
    {
        "name": "Two Week Streak",
        "description": "Maintain a 14-day streak",
        "category": "consistency",
        "xp_reward": 75,
        "requirement_count": 14,
        "icon_url": "/assets/achievements/fourteen_streak.png"
    },
    {
        "name": "Unstoppable",
        "description": "Maintain a 60-day streak",
        "category": "consistency",
        "xp_reward": 250,
        "requirement_count": 60,
        "icon_url": "/assets/achievements/sixty_streak.png"
    },
    {
        "name": "Century Club",
        "description": "Maintain a 100-day streak",
        "category": "consistency",
        "xp_reward": 500,
        "requirement_count": 100,
        "icon_url": "/assets/achievements/hundred_streak.png"
    },
    
    # More Todo Achievements
    {
        "name": "Task Master",
        "description": "Complete 50 todos",
        "category": "todos",
        "xp_reward": 80,
        "requirement_count": 50,
        "icon_url": "/assets/achievements/fifty_todos.png"
    },
    {
        "name": "Completion King",
        "description": "Complete 100 todos",
        "category": "todos",
        "xp_reward": 150,
        "requirement_count": 100,
        "icon_url": "/assets/achievements/hundred_todos.png"
    },
    {
        "name": "Perfect Day",
        "description": "Complete all daily todos in one day",
        "category": "todos",
        "xp_reward": 30,
        "requirement_count": 1,
        "icon_url": "/assets/achievements/perfect_day.png"
    },
    
    # Social Achievements
    {
        "name": "First Challenge",
        "description": "Complete your first friend challenge",
        "category": "social",
        "xp_reward": 15,
        "requirement_count": 1,
        "icon_url": "/assets/achievements/first_challenge.png"
    },
    {
        "name": "Team Player",
        "description": "Complete 10 friend challenges",
        "category": "social",
        "xp_reward": 50,
        "requirement_count": 10,
        "icon_url": "/assets/achievements/team_player.png"
    },
    {
        "name": "Challenge Champion",
        "description": "Complete 50 friend challenges",
        "category": "social",
        "xp_reward": 150,
        "requirement_count": 50,
        "icon_url": "/assets/achievements/challenge_champion.png"
    },
    {
        "name": "Social Butterfly",
        "description": "Add 5 friends",
        "category": "social",
        "xp_reward": 25,
        "requirement_count": 5,
        "icon_url": "/assets/achievements/five_friends.png"
    },
    {
        "name": "Squad Goals",
        "description": "Add 10 friends",
        "category": "social",
        "xp_reward": 50,
        "requirement_count": 10,
        "icon_url": "/assets/achievements/ten_friends.png"
    },
    {
        "name": "Support Network",
        "description": "Add 20 friends",
        "category": "social",
        "xp_reward": 100,
        "requirement_count": 20,
        "icon_url": "/assets/achievements/twenty_friends.png"
    },
    {
        "name": "Motivator",
        "description": "Send 10 challenge invites",
        "category": "social",
        "xp_reward": 30,
        "requirement_count": 10,
        "icon_url": "/assets/achievements/motivator.png"
    },
    
    # More Journaling Achievements
    {
        "name": "Chronicler",
        "description": "Write 100 journal entries",
        "category": "journaling",
        "xp_reward": 150,
        "requirement_count": 100,
        "icon_url": "/assets/achievements/hundred_journals.png"
    },
    {
        "name": "Deep Thinker",
        "description": "Write a journal entry over 500 words",
        "category": "journaling",
        "xp_reward": 25,
        "requirement_count": 1,
        "icon_url": "/assets/achievements/long_entry.png"
    },
    
    # More Mood Tracking Achievements
    {
        "name": "Positive Vibes",
        "description": "Log 7 positive moods in a row",
        "category": "mood_tracking",
        "xp_reward": 40,
        "requirement_count": 7,
        "icon_url": "/assets/achievements/positive_streak.png"
    },
    {
        "name": "Emotion Expert",
        "description": "Log 250 moods",
        "category": "mood_tracking",
        "xp_reward": 200,
        "requirement_count": 250,
        "icon_url": "/assets/achievements/twofifty_moods.png"
    },
    
    # Special Time-Based Achievements
    {
        "name": "Early Bird",
        "description": "Log a mood before 8 AM for 7 days",
        "category": "special",
        "xp_reward": 35,
        "requirement_count": 7,
        "icon_url": "/assets/achievements/early_bird.png"
    },
    {
        "name": "Night Owl",
        "description": "Log a mood after 10 PM for 7 days",
        "category": "special",
        "xp_reward": 35,
        "requirement_count": 7,
        "icon_url": "/assets/achievements/night_owl.png"
    },
    {
        "name": "Weekend Warrior",
        "description": "Complete all weekend todos for 4 weekends",
        "category": "special",
        "xp_reward": 60,
        "requirement_count": 4,
        "icon_url": "/assets/achievements/weekend_warrior.png"
    },
    {
        "name": "Consistency Champion",
        "description": "Log at least one activity every day for 14 days",
        "category": "special",
        "xp_reward": 100,
        "requirement_count": 14,
        "icon_url": "/assets/achievements/consistency_champ.png"
    },
    {
        "name": "Wellness Warrior",
        "description": "Complete at least 3 different activity types in one day",
        "category": "special",
        "xp_reward": 45,
        "requirement_count": 1,
        "icon_url": "/assets/achievements/wellness_warrior.png"
    },
    
    # Ultra Achievements
    {
        "name": "Mindful Master",
        "description": "Log 500 moods",
        "category": "mood_tracking",
        "xp_reward": 500,
        "requirement_count": 500,
        "icon_url": "/assets/achievements/fivehundred_moods.png"
    },
    {
        "name": "Quest Conqueror",
        "description": "Complete 500 todos",
        "category": "todos",
        "xp_reward": 500,
        "requirement_count": 500,
        "icon_url": "/assets/achievements/fivehundred_todos.png"
    },
    {
        "name": "Social Star",
        "description": "Add 50 friends",
        "category": "social",
        "xp_reward": 300,
        "requirement_count": 50,
        "icon_url": "/assets/achievements/fifty_friends.png"
    }
]

def log(msg):
    print(msg)
    with open("seed_log.txt", "a", encoding="utf-8") as f:
        f.write(msg + "\n")

def add_new_achievements():
    # Clear log file
    with open("seed_log.txt", "w", encoding="utf-8") as f:
        f.write("Starting log...\n")

    db = SessionLocal()
    try:
        log("Starting achievement update...")
        initial_count = db.query(models.Achievement).count()
        log(f"Initial achievement count: {initial_count}")
        
        added_count = 0
        skipped_count = 0
        
        for achievement_data in new_achievements:
            try:
                # Check if achievement already exists
                existing = db.query(models.Achievement).filter(models.Achievement.name == achievement_data["name"]).first()
                if existing:
                    log(f"[SKIPPED] {achievement_data['name']}")
                    skipped_count += 1
                    continue

                log(f"[ADDING] {achievement_data['name']}...")
                achievement_crud.create_achievement(db, schemas.AchievementCreate(**achievement_data))
                added_count += 1
            except Exception as e:
                log(f"[ERROR] Failed to add {achievement_data['name']}: {e}")

        final_count = db.query(models.Achievement).count()
        log(f"Finished. Added: {added_count}, Skipped: {skipped_count}")
        log(f"Final achievement count: {final_count}")

    except Exception as e:
        log(f"CRITICAL ERROR: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    add_new_achievements()
