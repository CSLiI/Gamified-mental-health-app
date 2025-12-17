
from app.database import SessionLocal
from app import models

def check_achievement_ids():
    db = SessionLocal()
    try:
        achievements = db.query(models.Achievement).all()
        print(f"Found {len(achievements)} achievements:")
        print(f"{'ID':<5} | {'Name':<20} | {'Category':<15}")
        print("-" * 45)
        target_names = ["First Challenge", "Team Player", "Challenge Champion", "Social Star"]
        for a in achievements:
            if a.name in target_names or a.category == "social":
                print(f"{a.id:<5} | {a.name:<20} | {a.category:<15}")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_achievement_ids()
