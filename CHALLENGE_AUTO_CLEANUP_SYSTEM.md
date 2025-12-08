# Challenge Auto-Cleanup System

## Overview

Completed friend challenges now automatically disappear after 24 hours while maintaining a permanent count for achievement tracking.

## Features

### 1. Persistent Challenge Counter

- **User Model Enhancement**: Added `completed_challenges` field to track lifetime total
- **Purpose**: Enables achievement tracking even after challenges are deleted
- **Incremented**: Automatically when a challenge is marked as completed for the first time

### 2. Challenge Completion Tracking

- **Message Model Enhancement**: Added `completed_at` timestamp
- **Behavior**:
  - Set to current UTC time when challenge marked as completed
  - Cleared if challenge marked as incomplete
  - Used for 24-hour cleanup calculation

### 3. New Social Achievements

Three new achievements added to celebrate friend challenges:

| Achievement            | Description                          | XP Reward | Requirement   |
| ---------------------- | ------------------------------------ | --------- | ------------- |
| **First Challenge**    | Complete your first friend challenge | 15 XP     | 1 challenge   |
| **Team Player**        | Complete 10 friend challenges        | 50 XP     | 10 challenges |
| **Challenge Champion** | Complete 50 friend challenges        | 150 XP    | 50 challenges |

### 4. Auto-Cleanup System

- **Function**: `cleanup_old_completed_challenges()` in `app/CRUD/achievements.py`
- **Criteria**: Deletes challenges where:
  - `is_completed = true`
  - `completed_at` is more than 24 hours ago
- **Trigger Options**:
  - **Manual**: POST `/social/challenges/cleanup` (requires authentication)
  - **Automatic**: Can be scheduled via cron job or background task

## Backend Implementation

### Database Schema Changes

#### User Model

```python
# Added field
completed_challenges = Column(Integer, default=0)
```

#### Message Model

```python
# Added field
completed_at = Column(DateTime(timezone=True))
```

### API Endpoints

#### Update Challenge Completion

```http
PUT /social/messages/{message_id}/completion
Content-Type: application/json
Authorization: Bearer {token}

{
  "is_completed": true
}
```

**Response**:

```json
{
  "success": true,
  "message_id": 123,
  "is_completed": true,
  "total_challenges_completed": 5
}
```

**Behavior**:

- Sets `completed_at` timestamp when marking complete
- Increments user's `completed_challenges` counter (first-time completion only)
- Automatically checks and awards social achievements
- Returns total challenges completed by user

#### Manual Cleanup

```http
POST /social/challenges/cleanup
Authorization: Bearer {token}
```

**Response**:

```json
{
  "success": true,
  "deleted_count": 3,
  "message": "Cleaned up 3 completed challenge(s) older than 24 hours"
}
```

### Achievement Checking

**Function**: `check_social_achievements()` in `app/CRUD/achievements.py`

- Called automatically when challenge completed
- Checks user's total `completed_challenges` count
- Awards achievements based on milestones (1, 10, 50)

## How It Works

### User Flow

1. **Friend sends challenge** → Message created
2. **User completes challenge** →
   - `is_completed = true`
   - `completed_at = now()`
   - `user.completed_challenges += 1`
   - Achievement check triggered
3. **After 24 hours** → Challenge deleted via cleanup
4. **Counter persists** → Achievement progress saved permanently

### Example Timeline

```
Day 1, 10:00 AM: Challenge received
Day 1, 2:00 PM: Challenge completed (completed_at = 2:00 PM)
                Counter: completed_challenges = 1
                Achievement unlocked: "First Challenge" 🎉

Day 2, 2:01 PM: Cleanup runs (24+ hours elapsed)
                Challenge deleted from database
                Counter still shows: completed_challenges = 1 ✓
```

## Setup Instructions

### 1. Database Migration

Run the migration to add new columns:

```bash
# If using Alembic
alembic revision --autogenerate -m "Add challenge tracking fields"
alembic upgrade head

# Or drop and recreate (development only)
# The app will auto-create tables with new fields
```

### 2. Seed New Achievements

```bash
cd mental_health_app_backend
python seed_data.py
```

This will add the 3 new social challenge achievements (IDs 14, 15, 16).

### 3. Setup Automatic Cleanup (Optional)

#### Option A: Cron Job (Linux/Mac)

```bash
# Add to crontab (runs every hour)
0 * * * * curl -X POST http://localhost:8000/social/challenges/cleanup \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

#### Option B: Windows Task Scheduler

Create a scheduled task to run hourly:

```powershell
$headers = @{ Authorization = "Bearer YOUR_ADMIN_TOKEN" }
Invoke-RestMethod -Uri "http://localhost:8000/social/challenges/cleanup" `
  -Method POST -Headers $headers
```

#### Option C: Background Task (Recommended for Production)

Add to `main.py`:

```python
from apscheduler.schedulers.background import BackgroundScheduler
from app.CRUD import achievements

def schedule_cleanup():
    scheduler = BackgroundScheduler()
    scheduler.add_job(
        func=lambda: achievements.cleanup_old_completed_challenges(SessionLocal()),
        trigger="interval",
        hours=1,
        id="cleanup_challenges"
    )
    scheduler.start()

# In startup event
@app.on_event("startup")
async def startup_event():
    schedule_cleanup()
```

**Requirements**: `pip install apscheduler`

## Testing

### Test Challenge Completion

```python
# Using Swagger UI or Postman

1. Create challenge:
   POST /social/messages/
   {
     "receiver_id": 2,
     "message": "Complete 5 push-ups!"
   }

2. Mark as completed:
   PUT /social/messages/{id}/completion
   {
     "is_completed": true
   }

3. Verify counter increased:
   GET /users/me/
   # Check completed_challenges field

4. Check achievements:
   GET /achievements/user
   # Should show "First Challenge" unlocked
```

### Test Cleanup

```python
# Manually trigger cleanup
POST /social/challenges/cleanup

# Check response
{
  "deleted_count": 0  # No challenges >24h old yet
}

# To test with old challenge, manually update database:
UPDATE messages
SET completed_at = NOW() - INTERVAL '25 hours'
WHERE is_completed = true
LIMIT 1;

# Run cleanup again - should delete that challenge
```

## Frontend Integration

### Display Total Challenges

Update profile screen to show achievement:

```dart
final user = await apiService.getCurrentUser();
print('Challenges completed: ${user.completedChallenges}');
```

### Handle Disappearing Challenges

Friend profile screen already refreshes on pull-to-refresh:

```dart
// Challenges >24h automatically won't appear in API response
final messages = await apiService.getFriendMessages(friendUserId);
// Old completed challenges won't be in list
```

### Show Achievement Notifications

When challenge completed:

```dart
final result = await apiService.updateMessageCompletion(
  messageId,
  isCompleted: true
);

if (result['total_challenges_completed'] == 1) {
  // Show "First Challenge" achievement notification
}
```

## Benefits

### For Users

- **Clean UI**: Completed challenges don't clutter the interface
- **Progress Tracking**: Permanent record of accomplishments
- **Motivation**: Achievement milestones encourage participation
- **Fresh Experience**: Regular cleanup keeps social feed relevant

### For System

- **Database Efficiency**: Reduces table size over time
- **Performance**: Fewer records to query in messages table
- **Scalability**: Prevents unbounded growth of completed items
- **Data Integrity**: Counter preserved even after cleanup

## Troubleshooting

### Counter Not Incrementing

- Check if challenge was already marked as complete before
- Counter only increments on first-time completion
- Verify database has `completed_challenges` column

### Achievements Not Unlocking

- Ensure seed_data.py created achievements with correct IDs (14, 15, 16)
- Check `check_social_achievements()` is called in completion endpoint
- Verify user's total count meets achievement requirement

### Cleanup Not Working

- Confirm `completed_at` timestamp is set when challenge completed
- Check timezone handling (UTC everywhere)
- Verify cleanup function is being called (manual or scheduled)

## Migration Notes

### Existing Data

- Existing users will have `completed_challenges = 0` initially
- Old completed challenges don't have `completed_at` timestamp
- Run one-time migration to backfill:

```sql
UPDATE messages
SET completed_at = created_at
WHERE is_completed = true
AND completed_at IS NULL;
```

### Gradual Rollout

1. Deploy backend with new fields (defaults won't break existing code)
2. Run seed script to add achievements
3. Enable cleanup manually first to test
4. Schedule automatic cleanup after validation
5. Update frontend to display new counter/achievements

## Future Enhancements

- **Configurable Duration**: Allow admin to change 24-hour threshold
- **Archive System**: Move to archive table instead of deleting
- **Statistics Dashboard**: Show challenge completion trends
- **Leaderboards**: Rank users by total challenges completed
- **Challenge Categories**: Track different types separately

---

**Status**: ✅ Implementation Complete  
**Version**: 1.0  
**Last Updated**: December 1, 2025
