# Test script to check friend permissions
# Run this with: python test_friend_permissions.py

import requests
import json

BASE_URL = "http://localhost:8000"

def test_friend_interactions():
    """Test friend interaction endpoints"""
    
    # You'll need to replace these with actual tokens from your login
    print("=" * 60)
    print("FRIEND PERMISSION TEST")
    print("=" * 60)
    
    print("\n1. First, login as User 1:")
    print("   POST /auth/login")
    print("   Get the token from response")
    
    print("\n2. Check if you're friends with user 25:")
    print("   GET /friends/")
    print("   Look for user 25 in the friends list")
    
    print("\n3. Check friend todos endpoint:")
    print("   GET /users/25/todos?period_type=daily")
    print("   Should return only TODAY's todos")
    
    print("\n4. Test send message:")
    print("   POST /friends/25/messages")
    print("   Body: {'message': 'Test message'}")
    
    print("\n5. Test send encouragement:")
    print("   POST /friends/25/encouragement")
    print("   Body: {'message': 'You got this!'}")
    
    print("\n" + "=" * 60)
    print("EXPECTED BEHAVIOR:")
    print("=" * 60)
    print("- If you ARE friends: All should return 200")
    print("- If you're NOT friends: Should return 403 Forbidden")
    print("- Check the friendship table in your database!")
    print("\nSQL to check:")
    print("  SELECT * FROM friendships WHERE ")
    print("    (user1_id = YOUR_ID AND user2_id = 25) OR")
    print("    (user1_id = 25 AND user2_id = YOUR_ID);")

if __name__ == "__main__":
    test_friend_interactions()
