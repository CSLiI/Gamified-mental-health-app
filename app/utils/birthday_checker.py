"""
Background task to check for user birthdays and send notifications
This should be run daily (e.g., via a cron job or scheduler)
"""

from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.CRUD import users as user_crud
from datetime import datetime
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def check_all_birthdays():
    """
    Check all users for birthdays today and create notifications
    This function should be called once per day (e.g., at midnight)
    """
    db = SessionLocal()
    try:
        # Get all users with birthday today
        birthday_users = user_crud.get_users_with_birthday_today(db)
        
        logger.info(f"Found {len(birthday_users)} users with birthdays today")
        
        created_notifications = 0
        for user in birthday_users:
            try:
                notification = user_crud.check_and_create_birthday_notification(db, user.id)
                if notification:
                    created_notifications += 1
                    logger.info(f"Created birthday notification for user {user.id}: {user.first_name}")
            except Exception as e:
                logger.error(f"Error creating birthday notification for user {user.id}: {e}")
                continue
        
        logger.info(f"Successfully created {created_notifications} birthday notifications")
        return created_notifications
        
    except Exception as e:
        logger.error(f"Error in birthday check: {e}")
        return 0
    finally:
        db.close()

if __name__ == "__main__":
    # Can be run directly for testing
    check_all_birthdays()