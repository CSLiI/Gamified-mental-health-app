"""
Script to update achievement icon URLs in the database
Run this after generating and placing new icons in assets/achievements/
"""

from app.database import SessionLocal
from app import models

# Map of achievement names to their icon filenames
ICON_MAPPING = {
    # Original Mood Tracking
    "First Steps": "first_mood.png",
    "Self-Aware": "seven_moods.png",
    "Emotion Tracker": "thirty_moods.png",
    "Mood Master": "hundred_moods.png",
    
    # Original Journaling
    "Dear Diary": "first_journal.png",
    "Reflective Writer": "ten_journals.png",
    "Story Teller": "fifty_journals.png",
    
    # Original Consistency
    "Building Habits": "three_streak.png",
    "Week Warrior": "seven_streak.png",
    "Monthly Master": "thirty_streak.png",
    
    # Original Todos
    "Task Tackler": "first_todo.png",
    "Productivity Pro": "twentyfive_todos.png",
    
    # Special
    "Thriving": "thriving.png",
    
    # New Streak
    "Two Week Streak": "fourteen_streak.png",
    "Unstoppable": "sixty_streak.png",
    "Century Club": "hundred_streak.png",
    
    # New Todos
    "Task Master": "fifty_todos.png",
    "Completion King": "hundred_todos.png",
    "Perfect Day": "perfect_day.png",
    "Quest Conqueror": "fivehundred_todos.png",
    
    # Social
    "First Challenge": "first_challenge.png",
    "Team Player": "team_player.png",
    "Challenge Champion": "challenge_champion.png",
    "Social Butterfly": "five_friends.png",
    "Squad Goals": "ten_friends.png",
    "Support Network": "twenty_friends.png",
    "Motivator": "motivator.png",
    "Social Star": "fifty_friends.png",
    
    # New Journaling
    "Chronicler": "hundred_journals.png",
    "Deep Thinker": "long_entry.png",
    
    # New Mood Tracking
    "Positive Vibes": "positive_streak.png",
    "Emotion Expert": "twofifty_moods.png",
    "Mindful Master": "fivehundred_moods.png",
    
    # New Special
    "Early Bird": "early_bird.png",
    "Night Owl": "night_owl.png",
    "Weekend Warrior": "weekend_warrior.png",
    "Consistency Champion": "consistency_champ.png",
    "Wellness Warrior": "wellness_warrior.png",
}

def update_achievement_icons():
    """Update all achievement icon URLs to match the new consistent icons"""
    db = SessionLocal()
    try:
        print("Updating achievement icon URLs...")
        print("=" * 60)
        
        updated_count = 0
        not_found_count = 0
        
        for achievement_name, icon_filename in ICON_MAPPING.items():
            achievement = db.query(models.Achievement).filter(
                models.Achievement.name == achievement_name
            ).first()
            
            if achievement:
                old_url = achievement.icon_url
                new_url = f"/assets/achievements/{icon_filename}"
                
                if old_url != new_url:
                    achievement.icon_url = new_url
                    print(f"✓ Updated '{achievement_name}'")
                    print(f"  Old: {old_url}")
                    print(f"  New: {new_url}")
                    updated_count += 1
                else:
                    print(f"- Skipped '{achievement_name}' (already correct)")
            else:
                print(f"✗ Achievement not found: '{achievement_name}'")
                not_found_count += 1
        
        db.commit()
        
        print("\n" + "=" * 60)
        print(f"✓ Updated: {updated_count} achievements")
        print(f"- Skipped: {len(ICON_MAPPING) - updated_count - not_found_count} (already correct)")
        print(f"✗ Not found: {not_found_count} achievements")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    update_achievement_icons()
