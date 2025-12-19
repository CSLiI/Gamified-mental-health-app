# Friend Profile Fixes - Version 2

## Issues Reported by User

1. ❌ Character mood not showing
2. ❌ Would be nice to see challenges sent to friend
3. ❌ Friend's goals for the day cannot be seen
4. ❌ Streak, level, and points not accurate
5. ❌ 7-Day mood journey not accurate
6. ❌ Real-time sync issue (data saved in Supabase but not refreshing)

---

## Fixes Implemented

### 1. Real Mood Data for 7-Day Chart

**Problem**: The mood chart was using dummy/hardcoded data with no actual mood history.

**Solution**:

- ✅ Created new backend endpoint: `GET /users/{user_id}/mood-logs`
  - Returns mood history for the last N days (default 7)
  - Includes friendship verification
  - Returns: `[{"id": int, "mood": string, "logged_at": datetime}]`
- ✅ Added frontend API method: `getFriendMoodLogs(userId, days)`
  - Located in `api_service.dart` (line ~625)
- ✅ Updated `_buildMoodChart()` widget to display real data
  - Maps actual mood values to colors (happy→yellow, calm→blue, sad→purple, angry→red, etc.)
  - Shows bar heights based on mood scores
  - Handles missing data (shows gray bars)
  - Labels show day of week (Mon, Tue, Wed, etc.)

**Code Changes**:

```dart
// mental_health_app/lib/presentation/screens/social/friend_profile_screen.dart
List<dynamic> _friendMoodLogs = []; // Added state variable

// In _loadFriendData():
final moodLogs = await _apiService.getFriendMoodLogs(widget.friendId);
_friendMoodLogs = moodLogs;

// Updated _buildMoodChart() to process real data
```

---

### 2. Challenges Sent Display

**Problem**: Challenges sent to friend were only visible in notifications screen, not on friend profile.

**Solution**:

- ✅ Added `_buildChallengesSection()` widget showing challenges I sent
  - Displays challenge message text
  - Shows "time ago" format (e.g., "2h ago", "3d ago")
  - Visual indicator for read/unread status
  - Shows count badge
  - Limits display to 3 challenges with "+X more" indicator
- ✅ Loads messages via existing `GET /friends/{friend_id}/messages` endpoint
  - Filters messages where `receiver_id == friend_id` (challenges I sent)
  - Shows icon status: pending (yellow) vs read (green)

**UI Location**: Added between "Today's Goals" section and action buttons

---

### 3. Debug Logging for Data Investigation

**Problem**: Need to verify what data backend is actually returning.

**Solution**:

- ✅ Added comprehensive debug logging in `_loadFriendData()`:
  ```dart
  print('📊 [FRIEND PROFILE DEBUG]');
  print('Profile data: $profile');
  print('Streak data: $streak');
  print('Character state: $characterState');
  print('Todos count: ${todos.length}');
  print('Mood logs count: ${moodLogs.length}');
  print('Messages count: ${messages.length}');
  print('Level: ${profile['level']}, XP: ${profile['xp']}');
  print('Current streak: ${profile['current_streak']}');
  ```

**Usage**: Run app, navigate to friend profile, check Flutter console to see actual data values.

---

## Backend Changes

### New Endpoint: GET /users/{user_id}/mood-logs

**File**: `mental_health_app_backend/app/routers/social.py` (line ~243)

**Parameters**:

- `user_id` (path): Friend's user ID
- `days` (query, optional): Number of days to fetch (default 7)

**Response**:

```json
[
  {
    "id": 123,
    "mood": "happy",
    "logged_at": "2025-01-15T10:30:00"
  },
  {
    "id": 124,
    "mood": "calm",
    "logged_at": "2025-01-16T09:15:00"
  }
]
```

**Security**: Verifies friendship before returning data (403 if not friends)

---

## Testing Instructions

### 1. Restart Backend Server

```powershell
cd mental_health_app_backend
python main.py
```

- Verify new endpoint appears in Swagger UI: http://localhost:8000/docs
- Look for `GET /users/{user_id}/mood-logs`

### 2. Hot Reload Flutter App

- The app should already be running
- Just hot reload (press `r` in terminal or click hot reload button)
- Navigate to friend profile

### 3. Check Debug Output

Open Flutter debug console and look for:

```
📊 [FRIEND PROFILE DEBUG]
Profile data: {user_id: 2, username: john_doe, level: 5, xp: 1250, ...}
Streak data: {current_streak: 7, longest_streak: 10}
Character state: {character_state: thriving, mood_score: 85, ...}
Todos count: 3
Mood logs count: 7
Messages count: 2
Level: 5, XP: 1250
Current streak: 7
```

### 4. Verify Visual Changes

**7-Day Mood Chart**:

- Should show actual colored bars (not uniform dummy data)
- Colors match mood: Yellow (happy), Blue (calm), Purple (sad), Red (angry)
- Days with no data show gray bars
- Labels show Mon-Sun

**Challenges Section** (new):

- Located below "Today's Goals"
- Shows challenges you sent to this friend
- Challenge count badge
- Time ago format for each challenge
- Icon indicates read/unread status

**Today's Goals**:

- Should display friend's todos with correct titles (not "Untitled")
- Shows completion count (e.g., "2/5")

**Stats Cards**:

- Level, XP, Streak should show actual values from backend
- Debug logs will reveal if values are missing

---

## Remaining Issues to Investigate

Based on debug logs, you may still need to verify:

### ✅ Character Mood State

- Check if `characterState` in debug logs contains valid data
- Verify character GIF path is correct
- Character should change appearance based on mood state

### ✅ Today's Goals Visibility

- If todos count is 0, check backend filtering (should be daily period)
- Verify `GET /users/{user_id}/todos?period_type=daily` returns data

### ✅ Stats Accuracy (Level, XP, Streak)

- Debug logs show actual values returned from backend
- If values are wrong, verify database values in Supabase
- Check if backend calculations are correct

### ✅ Real-time Sync

The user mentioned expecting real-time updates since data is in Supabase. **Current behavior**:

- Data is stored in Supabase (PostgreSQL)
- Frontend caches data and only refreshes on navigation
- **Recommendation**: Add pull-to-refresh gesture

**To add pull-to-refresh**:

```dart
// Wrap ListView in RefreshIndicator
RefreshIndicator(
  onRefresh: _loadFriendData,
  child: ListView(...),
)
```

---

## Files Modified

1. **Backend**:

   - `mental_health_app_backend/app/routers/social.py` - Added mood-logs endpoint

2. **Frontend**:
   - `lib/data/services/api_service.dart` - Added `getFriendMoodLogs()` method
   - `lib/presentation/screens/social/friend_profile_screen.dart`:
     - Added `_friendMoodLogs` state variable
     - Added `_friendMessages` state variable
     - Enhanced `_loadFriendData()` with debug logging and mood logs/messages loading
     - Completely rewrote `_buildMoodChart()` to use real data
     - Added `_buildChallengesSection()` to display challenges sent
     - Added `_buildChallengeItem()` helper widget

---

## Next Steps

1. **Restart backend** (if not done yet)
2. **Test with debug logs** to identify remaining issues
3. **Add pull-to-refresh** if real-time sync is desired
4. **Verify backend data** if stats show incorrect values
5. **Check character state logic** if character mood not displaying

---

## API Endpoints Used

| Endpoint                           | Method | Purpose                | Response                                 |
| ---------------------------------- | ------ | ---------------------- | ---------------------------------------- |
| `/users/{id}/profile`              | GET    | Friend's profile data  | level, xp, streaks, username             |
| `/users/{id}/streak`               | GET    | Friend's streak data   | current_streak, longest_streak           |
| `/users/{id}/character/mood-state` | GET    | Character state        | mood_score, character_state, environment |
| `/users/{id}/todos`                | GET    | Friend's todos         | List of todos (daily filtered)           |
| `/users/{id}/mood-logs`            | GET    | **NEW** - Mood history | List of mood logs for last N days        |
| `/friends/{id}/messages`           | GET    | Message conversation   | All messages between users               |

---

## Expected Behavior After Fixes

✅ **7-Day mood chart** displays actual mood data with appropriate colors  
✅ **Challenges section** shows challenges sent to friend with read status  
✅ **Debug logs** reveal actual data values for investigation  
✅ **Mood logs** loaded from backend (7 days history)  
✅ **Messages** loaded and filtered to show sent challenges

🔍 **Still investigating** (use debug logs):

- Character mood display accuracy
- Goals visibility (todos count)
- Stats accuracy (level, XP, streak values)
- Real-time sync (consider pull-to-refresh)

---

## Debug Checklist

When testing, verify in console:

- [ ] Profile data contains level, xp, current_streak
- [ ] Streak data is not empty
- [ ] Character state contains mood_score, character_state
- [ ] Todos count > 0 (if friend has daily goals)
- [ ] Mood logs count matches expected (up to 7)
- [ ] Messages count matches challenges sent
- [ ] All numeric values are correct (compare with Supabase)

If any values are missing or incorrect, that's the root cause to fix next!
