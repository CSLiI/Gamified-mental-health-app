# Quick Start: Challenge Auto-Cleanup System

## 1. Update Database Schema

The backend will automatically create new columns when you restart it (using SQLAlchemy's create_all).

### New Columns Added:

- `users.completed_challenges` (Integer, default 0)
- `messages.completed_at` (DateTime with timezone)

### If you need to manually add columns (PostgreSQL):

```sql
-- Add to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS completed_challenges INTEGER DEFAULT 0;

-- Add to messages table
ALTER TABLE messages
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;
```

## 2. Seed New Achievements

```powershell
cd mental_health_app_backend
.\venv\Scripts\Activate.ps1
python seed_data.py
```

This will add 3 new achievements:

- **First Challenge** (1 challenge)
- **Team Player** (10 challenges)
- **Challenge Champion** (50 challenges)

## 3. Start Backend

```powershell
python main.py
```

The server will start on http://localhost:8000

## 4. Test the System

### Option A: Run Test Script

```powershell
python test_challenge_system.py
```

Follow the prompts to test with two user accounts.

### Option B: Manual Testing via Swagger UI

1. Go to http://localhost:8000/docs
2. Login as User 1 (click "Authorize", enter credentials)
3. Create a challenge:
   - `POST /social/messages/`
   - Body: `{"receiver_id": 2, "message": "Test challenge"}`
4. Login as User 2
5. Mark challenge complete:
   - `PUT /social/messages/{id}/completion`
   - Body: `{"is_completed": true}`
6. Check achievements:
   - `GET /achievements/user`
   - Look for "First Challenge" unlocked
7. Test cleanup:
   - `POST /social/challenges/cleanup`

## 5. Setup Automatic Cleanup (Optional)

### For Development (Manual Trigger)

Run cleanup endpoint periodically:

```powershell
# Create a PowerShell script: cleanup_challenges.ps1
$token = "YOUR_ACCESS_TOKEN_HERE"
$headers = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri "http://localhost:8000/social/challenges/cleanup" `
  -Method POST -Headers $headers
```

### For Production (Scheduled Task)

1. Install APScheduler:

   ```powershell
   pip install apscheduler
   ```

2. Add to `main.py` (before `if __name__ == "__main__":`):

   ```python
   from apscheduler.schedulers.background import BackgroundScheduler
   from app.CRUD import achievements as achievement_crud
   from app.database import SessionLocal

   def cleanup_job():
       """Background job to cleanup old challenges"""
       db = SessionLocal()
       try:
           count = achievement_crud.cleanup_old_completed_challenges(db)
           print(f"Cleanup: Deleted {count} old challenge(s)")
       except Exception as e:
           print(f"Cleanup error: {e}")
       finally:
           db.close()

   def start_scheduler():
       """Start the background scheduler"""
       scheduler = BackgroundScheduler()
       scheduler.add_job(
           func=cleanup_job,
           trigger="interval",
           hours=1,  # Run every hour
           id="cleanup_challenges",
           replace_existing=True
       )
       scheduler.start()
       print("✓ Cleanup scheduler started (runs every hour)")

   # Call this in the startup event
   @app.on_event("startup")
   async def startup_event():
       start_scheduler()
   ```

3. Restart backend - cleanup will run automatically every hour

## 6. Verify Everything Works

### Check Database

```sql
-- Verify new columns exist
SELECT completed_challenges FROM users LIMIT 1;
SELECT completed_at FROM messages WHERE is_completed = true LIMIT 1;

-- Check achievement IDs
SELECT id, name, requirement_count FROM achievements
WHERE name LIKE '%Challenge%' OR name LIKE '%Team Player%';
```

### Check API Response

```bash
# Complete a challenge and check response
curl -X PUT "http://localhost:8000/social/messages/1/completion" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"is_completed": true}'

# Should return:
# {
#   "success": true,
#   "message_id": 1,
#   "is_completed": true,
#   "total_challenges_completed": 1  <-- New field
# }
```

## 7. Test 24-Hour Cleanup

Since we can't wait 24 hours, manually backdate a challenge:

```sql
-- Backdate a completed challenge
UPDATE messages
SET completed_at = NOW() - INTERVAL '25 hours'
WHERE is_completed = true
AND id = 1;

-- Now run cleanup (via API or Swagger)
-- POST /social/challenges/cleanup

-- Verify it's deleted
SELECT * FROM messages WHERE id = 1;
-- Should return no rows

-- But counter persists
SELECT completed_challenges FROM users WHERE id = 2;
-- Should still show count
```

## Troubleshooting

### "Column does not exist" Error

- Restart backend to auto-create columns
- Or manually add columns (see step 1)

### Achievements Not Appearing

- Run `python seed_data.py` again
- Check database: `SELECT * FROM achievements WHERE id >= 14;`

### Counter Not Incrementing

- Check user has `completed_challenges` column
- Verify challenge was not already marked complete
- Check backend logs for errors

### Cleanup Deletes Nothing

- Verify challenges have `completed_at` timestamp
- Check if any challenges are actually >24 hours old
- Manually backdate one for testing (see step 7)

## Frontend Updates Needed

No immediate frontend changes required! But you can enhance the UI:

1. **Show total challenges completed** in profile:

   ```dart
   // user.completedChallenges now available
   Text('Challenges Completed: ${user.completedChallenges}')
   ```

2. **Achievement notifications** when milestones hit:

   ```dart
   if (completionResult['total_challenges_completed'] == 1) {
     showAchievementDialog('First Challenge Unlocked!');
   }
   ```

3. **Challenges auto-disappear** after 24h (no code needed - just won't be returned by API)

---

**Ready to test?** Start the backend and run the test script! 🚀
