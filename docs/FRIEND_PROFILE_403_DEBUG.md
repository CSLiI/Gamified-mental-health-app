# Friend Profile 403 Error - Debugging Guide

## Problem Summary

- **Error**: 403 Forbidden when sending messages/encouragement to friend
- **Issue**: "Today's goals" showing inaccurate data (old todos)

## Root Causes

### 1. Backend Permission Check Failure (403 Error)

The backend is likely checking if users are friends, and the check is failing.

**Possible causes:**

- Users aren't actually friends in the database
- Friendship status is not "accepted"
- Backend friend verification logic has a bug

### 2. Todo Date Filtering Issue

The backend endpoint `/users/{user_id}/todos?period_type=daily` is returning ALL daily todos, not just today's.

## Solutions

### Fix 1: Verify Friendship in Database

```sql
-- Check if friendship exists
SELECT * FROM friendships
WHERE (user1_id = YOUR_USER_ID AND user2_id = 25)
   OR (user1_id = 25 AND user2_id = YOUR_USER_ID);

-- Check friendship status
SELECT id, user1_id, user2_id, status, created_at
FROM friendships
WHERE ((user1_id = YOUR_USER_ID AND user2_id = 25)
    OR (user1_id = 25 AND user2_id = YOUR_USER_ID))
  AND status = 'accepted';
```

**If no friendship exists**: They need to send/accept friend request first!

### Fix 2: Check Backend Friend Routes

Check `mental_health_app_backend/app/routers/friends.py`:

```python
# Verify these endpoints have proper friend verification:

@router.post("/friends/{friend_id}/messages")
async def send_message(
    friend_id: int,
    message_data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # MUST verify friendship here!
    # Check if current_user.id is friends with friend_id
    pass

@router.post("/friends/{friend_id}/encouragement")
async def send_encouragement(
    friend_id: int,
    encouragement_data: dict,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    # MUST verify friendship here!
    pass
```

### Fix 3: Backend Todo Filtering

Check `mental_health_app_backend/app/routers/users.py` or wherever the friend todos endpoint is:

```python
@router.get("/users/{user_id}/todos")
async def get_friend_todos(
    user_id: int,
    period_type: str = Query("daily"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Issue: This probably returns ALL todos with period_type='daily'
    # Fix: Should filter by date!

    from datetime import datetime, date

    todos = db.query(Todo).filter(
        Todo.user_id == user_id,
        Todo.period_type == period_type
    )

    # ADD THIS: Filter by today's date
    if period_type == "daily":
        today = date.today()
        todos = todos.filter(
            db.func.date(Todo.created_at) == today
        )

    return todos.all()
```

## Testing Steps

### Step 1: Verify Friendship

1. Open Swagger UI: `http://localhost:8000/docs`
2. Login and get your JWT token
3. Call `GET /friends/` to see your friends list
4. Check if user ID 25 is in the list
5. Check `friend_id` field - it should be 25

### Step 2: Test Backend Directly

Using the token from above:

```bash
# Test get friend todos
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:8000/users/25/todos?period_type=daily

# Test send message
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Test"}' \
  http://localhost:8000/friends/25/messages

# Test send encouragement
curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "You got this!"}' \
  http://localhost:8000/friends/25/encouragement
```

### Step 3: Check Backend Logs

Look at your FastAPI console for error messages:

- "Not friends" errors
- Permission denied messages
- SQL query errors

## Frontend Temporary Workaround

If you want to test the UI while fixing backend:

**Option 1**: Mock the responses in `friend_profile_screen.dart`:

```dart
Future<void> _sendEncouragement() async {
  // ... existing dialog code ...

  try {
    // TEMPORARY: Comment out actual API call for testing
    // await _apiService.sendEncouragement(
    //   widget.friendId,
    //   controller.text.trim(),
    // );

    // MOCK SUCCESS
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('[MOCK] Encouragement sent to ${widget.friendName}! 💚'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    // ... error handling
  }
}
```

## Expected Backend Response Format

### GET /users/{user_id}/todos

```json
[
  {
    "id": 123,
    "task_text": "Morning meditation",
    "is_completed": false,
    "period_type": "daily",
    "created_at": "2025-11-11T08:00:00", // TODAY'S DATE
    "user_id": 25
  }
]
```

### POST /friends/{friend_id}/messages

```json
{
  "success": true,
  "message": "Message sent successfully"
}
```

### POST /friends/{friend_id}/encouragement

```json
{
  "success": true,
  "encouragement_id": 456
}
```

## Checklist

- [ ] Verify friendship exists in database
- [ ] Check friendship status = 'accepted'
- [ ] Backend routes have friend verification
- [ ] Backend todos filtered by today's date
- [ ] Test endpoints via Swagger UI
- [ ] Check backend console logs for errors
- [ ] Frontend displays correct date range

## Quick Fix Commands

```bash
# Check backend
cd mental_health_app_backend
python main.py

# Check database
# Use your database client to run the SQL queries above

# Check frontend
cd mental_health_app
flutter run
```

## Need More Help?

1. Share the backend route code for friends endpoints
2. Share database query results
3. Share full backend error logs
4. Check if seed_data.py created proper friendships
