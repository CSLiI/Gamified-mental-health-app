
from app.database import SessionLocal
from app import models
from app.CRUD import achievements as achievement_crud

def verify_fix():
    db = SessionLocal()
    try:
        # Create a dummy user for testing if needed, or pick an existing one
        user = db.query(models.User).first()
        if not user:
            print("No users found to test with.")
            # Verify lookup logic alone
            target_achievements = ["First Challenge", "Team Player", "Challenge Champion"]
            print("Verifying achievement lookup:")
            for name in target_achievements:
                a = db.query(models.Achievement).filter(models.Achievement.name == name).first()
                if a:
                    print(f"OK: Found '{name}' with ID {a.id}")
                else:
                    print(f"FAIL: '{name}' not found in DB")
            return

        print(f"Testing with user ID: {user.id}")
        
        # Call the function that was crashing
        # This shouldn't crash now
        results = achievement_crud.check_social_achievements(db, user.id)
        
        print(f"✓ check_social_achievements ran successfully. Awarded: {results}")
        
        # Verify ids used
        target_achievements = ["First Challenge", "Team Player", "Challenge Champion"]
        for name in target_achievements:
            a = db.query(models.Achievement).filter(models.Achievement.name == name).first()
            if a:
                print(f"  Confirmed '{name}' exists with ID {a.id}")
            else:
                print(f"  Warning: '{name}' still missing from DB")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    verify_fix()
