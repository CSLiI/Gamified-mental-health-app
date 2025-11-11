# Backend Fixes Required - Friend Profile Issues

## Current Date: November 11, 2025

## Critical Backend Issues

### 1. 403 Forbidden Error - Send Encouragement/Challenge ❌

**Error Log:**

```
INFO: 127.0.0.1:51992 - "POST /friends/25/encouragement HTTP/1.1" 403 Forbidden
INFO: 127.0.0.1:62118 - "POST /friends/25/messages HTTP/1.1" 403 Forbidden
```

**Problem:** The backend is rejecting friend interaction requests due to missing friendship verification.

**Root Cause:** The `/friends/{friend_id}/encouragement` and `/friends/{friend_id}/messages` endpoints are not properly verifying that the two users are actually friends before allowing the action.

**Backend Fix Required:**

Location: `mental_health_app_backend/app/routers/friends.py` (or wherever these endpoints are defined)

```python
# Add friendship verification function
async def verify_friendship(
    current_user_id: int,
    friend_id: int,
    db: Session
) -> bool:
    """Verify that two users are friends"""
    friendship = db.query(Friendship).filter(
        or_(
            and_(
                Friendship.user1_id == current_user_id,
                Friendship.user2_id == friend_id,
                Friendship.status == "accepted"
            ),
            and_(
                Friendship.user1_id == friend_id,
                Friendship.user2_id == current_user_id,
                Friendship.status == "accepted"
            )
        )
    ).first()

    return friendship is not None

# Update encouragement endpoint
@router.post("/friends/{friend_id}/encouragement")
async def send_encouragement(
    friend_id: int,
    message: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Add this verification
    if not await verify_friendship(current_user.id, friend_id, db):
        raise HTTPException(
            status_code=403,
            detail="You must be friends to send encouragement"
        )

    # ... rest of the endpoint code

# Update messages endpoint
@router.post("/friends/{friend_id}/messages")
async def send_message(
    friend_id: int,
    message: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Add this verification
    if not await verify_friendship(current_user.id, friend_id, db):
        raise HTTPException(
            status_code=403,
            detail="You must be friends to send messages"
        )

    # ... rest of the endpoint code
```

**Testing Steps:**

1. Check database: `SELECT * FROM friendships WHERE (user1_id = YOUR_ID AND user2_id = 25) OR (user1_id = 25 AND user2_id = YOUR_ID);`
2. Verify status = 'accepted'
3. Test endpoints via Swagger UI: http://localhost:8000/docs
4. Try sending encouragement from Flutter app

---

### 2. Inaccurate "Today's Goals" Data ❌

**Problem:** The friend's "Today's Goals" section is showing ALL daily todos, including old ones (like "Untitled Task" from previous days), instead of only today's tasks.

**Root Cause:** The backend endpoint `/users/{user_id}/todos?period_type=daily` returns ALL todos with `period_type='daily'`, without filtering by the creation date.

**Current Behavior:**

- Returns: All todos where `period_type = 'daily'` (could be from any date)
- Expected: Only todos where `period_type = 'daily'` AND `created_at = TODAY`

**Backend Fix Required:**

Location: `mental_health_app_backend/app/routers/todos.py` (or similar)

```python
from datetime import date, datetime
from sqlalchemy import func

@router.get("/users/{user_id}/todos")
async def get_friend_todos(
    user_id: int,
    period_type: str = Query(...),  # 'daily', 'weekly', 'monthly'
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Verify friendship first (see issue #1 above)
    if not await verify_friendship(current_user.id, user_id, db):
        raise HTTPException(status_code=403, detail="Not friends")

    # Base query
    query = db.query(Todo).filter(
        Todo.user_id == user_id,
        Todo.period_type == period_type
    )

    # ADD THIS: Filter by today's date for daily todos
    if period_type == 'daily':
        today = date.today()
        query = query.filter(
            func.date(Todo.created_at) == today
        )

    # For weekly/monthly, you might want similar date filtering
    # based on the current week/month

    todos = query.order_by(Todo.created_at.desc()).all()
    return todos
```

**Alternative Fix (if you want to filter by date range):**

```python
if period_type == 'daily':
    # Get todos created today
    today_start = datetime.combine(date.today(), datetime.min.time())
    today_end = datetime.combine(date.today(), datetime.max.time())
    query = query.filter(
        Todo.created_at >= today_start,
        Todo.created_at <= today_end
    )
```

**Testing:**

1. Create a todo for today
2. Create a todo for yesterday (manually update DB if needed)
3. Call endpoint: `GET /users/{friend_id}/todos?period_type=daily`
4. Should ONLY return today's todos
5. Test from Flutter app - "Today's Goals" should show only current day

---

### 3. Frontend Workaround (Temporary) ✅

**Status:** Already implemented in Flutter

The Flutter app is currently filtering todos by date on the client side as a workaround:

```dart
// In friend_profile_screen.dart and social_screen.dart
final today = DateTime.now();
final todayTodos = allTodos.where((task) {
  final createdAt = DateTime.parse(task['created_at']).toLocal();
  return createdAt.year == today.year &&
      createdAt.month == today.month &&
      createdAt.day == today.day;
}).toList();
```

**However:** This is inefficient because:

- Backend sends ALL daily todos (could be hundreds)
- Frontend filters them (wasted bandwidth)
- Better to fix on backend for performance

---

## Priority Order

1. **HIGH**: Fix 403 Forbidden errors (blocks friend interactions)
2. **HIGH**: Fix "Today's Goals" date filtering (shows wrong data)
3. **LOW**: Frontend spacing issues (already fixed in Flutter code)

---

## Backend Files to Check/Modify

1. `mental_health_app_backend/app/routers/friends.py` - Add friendship verification
2. `mental_health_app_backend/app/routers/todos.py` - Add date filtering
3. `mental_health_app_backend/app/CRUD/friends.py` - Helper functions
4. `mental_health_app_backend/app/CRUD/todos.py` - Query logic

---

## SQL Queries for Debugging

### Check if friendship exists:

```sql
SELECT * FROM friendships
WHERE (user1_id = YOUR_USER_ID AND user2_id = 25)
   OR (user1_id = 25 AND user2_id = YOUR_USER_ID);
```

### Check todos by date:

```sql
-- All daily todos for user 25
SELECT id, user_id, task_text, created_at, period_type, is_completed
FROM todos
WHERE user_id = 25 AND period_type = 'daily';

-- Only today's daily todos for user 25
SELECT id, user_id, task_text, created_at, period_type, is_completed
FROM todos
WHERE user_id = 25
  AND period_type = 'daily'
  AND DATE(created_at) = CURRENT_DATE;
```

---

## Testing Checklist

After backend fixes:

- [ ] Verify friendship exists in database (status = 'accepted')
- [ ] Test GET /friends/ endpoint - should list user 25
- [ ] Test POST /friends/25/encouragement - should return 200 OK
- [ ] Test POST /friends/25/messages - should return 200 OK
- [ ] Test GET /users/25/todos?period_type=daily - should only return TODAY's todos
- [ ] Test from Flutter app - send encouragement (should work)
- [ ] Test from Flutter app - send challenge (should work)
- [ ] Test from Flutter app - "Today's Goals" shows only current day

---

## Expected Response Formats

### Successful Encouragement:

```json
{
  "message": "Encouragement sent successfully",
  "friend_id": 25,
  "sent_at": "2025-11-11T10:30:00"
}
```

### Successful Message:

```json
{
  "message": "Message sent successfully",
  "friend_id": 25,
  "content": "🏆 Challenge: Meditate for 10 minutes today",
  "sent_at": "2025-11-11T10:30:00"
}
```

### Today's Todos (filtered):

```json
[
  {
    "id": 145,
    "user_id": 25,
    "task_text": "Morning meditation",
    "period_type": "daily",
    "is_completed": false,
    "created_at": "2025-11-11T08:00:00"
  },
  {
    "id": 146,
    "user_id": 25,
    "task_text": "Write journal entry",
    "period_type": "daily",
    "is_completed": true,
    "created_at": "2025-11-11T09:00:00"
  }
]
```

---

## Frontend Status ✅

**All Flutter code is complete and working correctly:**

- ✅ Navigation fixed (`context.go('/social')` instead of `context.pop()`)
- ✅ RenderFlex overflow fixed (added `mainAxisSize: MainAxisSize.min` to mood chart columns)
- ✅ Proper spacing implemented
- ✅ API calls properly implemented
- ✅ Client-side date filtering as temporary workaround

**Waiting on backend fixes to enable full functionality.**
