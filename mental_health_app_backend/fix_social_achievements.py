
from app.database import SessionLocal
from app import models, schemas
from app.CRUD import achievements as achievement_crud

def fix_social_achievements():
    db = SessionLocal()
    try:
        print("Checking for missing social achievements...")
        
        social_achievements = [
            {
                "name": "First Challenge",
                "description": "Complete your first social challenge",
                "category": "social",
                "xp_reward": 50,
                "requirement_count": 1,
                "icon_url": "/assets/achievements/social_first.png"
            },
            {
                "name": "Team Player",
                "description": "Complete 10 social challenges",
                "category": "social",
                "xp_reward": 100,
                "requirement_count": 10,
                "icon_url": "/assets/achievements/social_team.png"
            },
            {
                "name": "Challenge Champion",
                "description": "Complete 50 social challenges",
                "category": "social",
                "xp_reward": 250,
                "requirement_count": 50,
                "icon_url": "/assets/achievements/social_champion.png"
            }
        ]
        
        created = 0
        for achievement_data in social_achievements:
            # Check if it already exists by name
            existing = db.query(models.Achievement).filter(models.Achievement.name == achievement_data["name"]).first()
            if not existing:
                print(f"Creating achievement: {achievement_data['name']}")
                achievement_crud.create_achievement(db, schemas.AchievementCreate(**achievement_data))
                created += 1
            else:
                print(f"Achievement '{achievement_data['name']}' already exists (ID: {existing.id})")
        
        print(f"✓ Created {created} missing social achievements")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    fix_social_achievements()
