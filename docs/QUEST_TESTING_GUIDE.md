# Quest System - Quick Testing Guide 🧪

## Prerequisites

Before testing the Quest UI, make sure the backend is running:

```powershell
cd mental_health_app_backend
.\venv\Scripts\Activate.ps1
python main.py
```

Backend should be running at: `http://localhost:8000`

---

## Test Scenario 1: Basic Quest Display ⚡

**Steps:**

1. Launch Flutter app: `flutter run`
2. Navigate to **Todo List** screen (bottom nav bar)
3. You should see **3 tabs**: "Daily Quests", "Weekly Quests", "My Todos"

**Expected Results:**

- ✅ 3 tabs visible at top
- ✅ Tabs are tappable and switch content
- ✅ Default tab shows empty state with message
- ✅ FAB (Floating Action Button) shows ✨ sparkle icon

**Verification:**

- Swipe between tabs → Smooth transitions
- Tap each tab → Content area updates
- FAB icon changes when switching to "My Todos" tab (changes to ➕ icon)

---

## Test Scenario 2: Generate Daily Quests 🎯

**Steps:**

1. Switch to **"Daily Quests"** tab
2. Tap the **✨ Floating Action Button**
3. Wait for loading indicator
4. Quest cards should appear

**Expected Results:**

- ✅ Loading indicator shows briefly
- ✅ 3-4 quest cards appear
- ✅ Success snackbar: "✨ New quests generated!"
- ✅ Each quest card shows:
  - Category emoji (😊, 📝, 👥, 🔥, ⭐)
  - Task description
  - Difficulty stars (1-3 stars, color-coded)
  - Progress bar (0/X)
  - XP reward with medal icon
  - Time remaining (e.g., "23h 45m")

**Verification:**

- Check quest categories are diverse (mood, journal, general, streak)
- Verify difficulty colors: Green (Easy), Orange (Medium), Red (Hard)
- Confirm time remaining shows 24 hours or less

---

## Test Scenario 3: Generate Weekly Quests 📅

**Steps:**

1. Switch to **"Weekly Quests"** tab
2. Tap the **✨ Floating Action Button**
3. Wait for loading
4. Quest cards should appear

**Expected Results:**

- ✅ 2-3 quest cards appear
- ✅ Quests have higher progress requirements (e.g., "Complete 10 tasks this week")
- ✅ Time remaining shows ~7 days
- ✅ XP rewards are higher than daily quests (25-50 XP)

**Verification:**

- Compare XP rewards: Weekly should be 2-3x higher than daily
- Time remaining should show days (e.g., "6d 23h")

---

## Test Scenario 4: Quest Progress Update - Mood Logging 😊

**Steps:**

1. Go to **Daily Quests** tab
2. Note any mood-related quest (e.g., "Log your mood 3 times today")
3. Note current progress (e.g., 0/3)
4. Navigate to **Mood** screen
5. Log a mood (select any mood like Happy, select intensity)
6. Save mood log
7. Return to **Daily Quests** tab
8. Pull down to refresh

**Expected Results:**

- ✅ Mood quest progress incremented by 1 (0/3 → 1/3)
- ✅ Progress bar updates visually (~33% filled)
- ✅ No errors in console

**Verification:**

- Check backend logs for: `POST /quests/progress` request
- Verify quest progress persists after app restart

---

## Test Scenario 5: Quest Progress Update - Journal Writing 📝

**Steps:**

1. Check for journal quest (e.g., "Write 2 journal entries")
2. Note current progress
3. Navigate to **Journal** screen
4. Write a new journal entry (title + content)
5. Tap **Save**
6. Return to **Daily Quests** tab
7. Refresh

**Expected Results:**

- ✅ Journal quest progress incremented (0/2 → 1/2)
- ✅ Progress bar updates (50% filled)

---

## Test Scenario 6: Quest Progress Update - Todo Completion ✅

**Steps:**

1. Check for general quest (e.g., "Complete 5 tasks today")
2. Note current progress
3. Switch to **"My Todos"** tab
4. Add a new todo task
5. Tap checkbox to mark it complete
6. Switch back to **"Daily Quests"** tab
7. Refresh

**Expected Results:**

- ✅ General quest progress incremented (0/5 → 1/5)
- ✅ Progress bar updates (20% filled)

---

## Test Scenario 7: Quest Completion & Level-Up 🎉

**Steps:**

1. Find a quest close to completion (e.g., "Complete 3 tasks", currently 2/3)
2. Complete one more relevant action:
   - For mood quest: Log one more mood
   - For journal quest: Write one more journal
   - For general quest: Complete one more todo
3. Return to quests tab
4. Refresh to update progress

**Expected Results:**

- ✅ Quest shows completed state:
  - Progress bar fully filled (100%)
  - Checkmark icon overlay
  - Card has success color tint
- ✅ XP is added to your account (visible in XP progress bar on Home)
- ✅ If XP crosses level threshold → **LevelUpDialog** appears with:
  - Confetti animation
  - Old level → New level display
  - XP earned breakdown
  - "Awesome!" button to dismiss

**Verification:**

- Check XP progress bar on Home screen increased
- Verify quest is marked as completed in backend (Swagger UI: `GET /quests/active`)

---

## Test Scenario 8: Daily Check-in → Streak Quest Update 🔥

**Steps:**

1. Check for streak quest (e.g., "Maintain 7-day streak")
2. Note current progress
3. Trigger **Daily Check-in Dialog** (open app after midnight, or use manual trigger)
4. Tap "Claim Reward"
5. Return to **Daily Quests** tab
6. Refresh

**Expected Results:**

- ✅ Streak quest progress incremented (0/7 → 1/7)
- ✅ Progress bar updates (~14% filled)

---

## Test Scenario 9: Pull-to-Refresh 🔄

**Steps:**

1. On any quest tab (Daily/Weekly)
2. Pull down from top of quest list
3. Loading indicator should show
4. Quest list refreshes

**Expected Results:**

- ✅ Loading spinner appears during refresh
- ✅ Quest data reloads from backend
- ✅ Progress updates reflect latest backend state
- ✅ No errors or crashes

---

## Test Scenario 10: Empty State Behavior 📭

**Steps:**

1. Delete all quests from backend (Swagger UI: `DELETE /quests/cleanup`)
2. Refresh Daily Quests tab in app

**Expected Results:**

- ✅ Empty state displayed with:
  - Gray task icon
  - "No Daily Quests" text
  - "Tap ✨ to generate new quests" helper text
- ✅ Pull-to-refresh still works on empty state
- ✅ Tapping ✨ FAB generates new quests

---

## Test Scenario 11: Tab Persistence 💾

**Steps:**

1. Switch to **"Weekly Quests"** tab
2. Navigate away from Todo List screen (go to Home or Profile)
3. Return to Todo List screen

**Expected Results:**

- ✅ Tab state preserved (still shows Weekly Quests tab)
- ✅ Quest data persists (no unnecessary reload)

**Alternative Test:**

- Switch tabs multiple times rapidly
- Verify no flickering or data loss

---

## Test Scenario 12: Multiple Quests Completion 🏆

**Steps:**

1. Generate 3-4 daily quests
2. Complete actions to fulfill **all quests** in one session:
   - Log 3 moods (for mood quest)
   - Write 2 journals (for journal quest)
   - Complete 5 todos (for general quest)
3. Return to Daily Quests tab after each action
4. Refresh to see updates

**Expected Results:**

- ✅ All quest progress bars update correctly
- ✅ Multiple quests can complete in one session
- ✅ Total XP gained = Sum of all quest rewards
- ✅ May trigger level-up dialog if combined XP crosses threshold

**Verification:**

- Check backend: `GET /users/me` → `xp` field increased by combined amount
- Verify level increases if applicable

---

## Test Scenario 13: Quest Expiry (Advanced) ⏰

**Note:** This requires backend database access.

**Steps:**

1. Generate daily quest (24h expiry)
2. Via Swagger UI or DB tool, modify `expires_at` to past time
3. Call `DELETE /quests/cleanup` in Swagger
4. Refresh Daily Quests tab in app

**Expected Results:**

- ✅ Expired quest removed from list
- ✅ Only active quests displayed
- ✅ No errors when loading quests

---

## Test Scenario 14: Backend Integration Validation 🔌

**Steps:**

1. Open Swagger UI: `http://localhost:8000/docs`
2. Authenticate (use login endpoint to get token)
3. Test these endpoints manually:
   - `GET /quests/active` → Returns `{"daily_quests": [...], "weekly_quests": [...]}`
   - `POST /quests/generate/daily` → Creates 3-4 quests
   - `POST /quests/generate/weekly` → Creates 2-3 quests
   - `POST /quests/progress` with `{"category": "mood", "increment": 1}` → Updates progress
4. Compare Swagger results with app display

**Expected Results:**

- ✅ All endpoints return 200 status codes
- ✅ Quest data matches between Swagger and app
- ✅ Progress updates reflected in both Swagger and app

---

## Common Issues & Solutions 🛠️

### Issue 1: "No quests appear after generating"

**Solution:**

- Check backend logs for errors
- Verify `seed_data.py` was run to seed quest templates
- Try manual generation via Swagger UI

### Issue 2: "Quest progress not updating"

**Solution:**

- Check network logs in Flutter DevTools (Network tab)
- Verify `updateQuestProgress` is called in relevant screens:
  - `mood_screen.dart` (line ~442)
  - `journal_screen.dart` (line ~141)
  - `todo_list_screen.dart` (line ~320)
  - `daily_checkin_dialog.dart` (line ~72)
- Check backend logs for `POST /quests/progress` requests

### Issue 3: "Level-up dialog not appearing"

**Solution:**

- Verify `_checkLevelUp()` is called after quest completion
- Check if XP actually crossed level threshold (use Swagger to check user's XP)
- Verify `LevelUpDialog` is imported in `todo_list_screen.dart`

### Issue 4: "Tabs not switching content"

**Solution:**

- Check TabController initialization: `TabController(length: 3, vsync: this)`
- Verify TabBarView has exactly 3 children matching 3 tabs
- Check for errors in console related to TabController

### Issue 5: "Empty state shows but can't generate quests"

**Solution:**

- Check FAB's `onPressed` callback is wired to `_generateQuests()`
- Verify API endpoint is correct: `ApiConstants.questsDailyGenerate`
- Check backend is running and accessible

---

## Performance Checks ⚡

### Load Time

- **Quest List Load:** Should be < 500ms
- **Quest Generation:** Should be < 1 second
- **Progress Update:** Should be < 300ms
- **Tab Switching:** Should be instant (< 100ms)

### Memory Usage

- Monitor Flutter DevTools → Memory tab
- Quest list should not cause memory leaks
- Tab switching should not increase memory significantly

### Network Efficiency

- Quest data loaded once per screen open
- Pull-to-refresh only reloads when user triggers
- Progress updates use single API call (not batched yet, but efficient)

---

## Regression Testing Checklist 🔍

After implementing Quest UI, verify these existing features still work:

- ✅ **Home Screen:** Still displays normally
- ✅ **Mood Logging:** Still saves moods correctly
- ✅ **Journal Writing:** Still saves entries correctly
- ✅ **Todo Management:** Add/Edit/Delete todos still works
- ✅ **Daily Check-in:** Still claims rewards and updates streak
- ✅ **Profile Screen:** Rewards, Achievements, Pets tabs still work
- ✅ **Level-Up Dialog:** Still appears after XP gain in other screens
- ✅ **XP Progress Bar:** Still updates in real-time on Home screen

---

## Success Criteria ✅

**All tests passed if:**

- ✅ 3 tabs display correctly (Daily Quests, Weekly Quests, My Todos)
- ✅ Quest generation works for both daily and weekly
- ✅ Quest cards show all required info (category, difficulty, progress, XP, time)
- ✅ Quest progress updates from mood logs, journals, todos, daily check-ins
- ✅ Quest completion triggers level-up check
- ✅ Level-up dialog appears when XP crosses threshold
- ✅ Empty states display with helpful messages
- ✅ Loading states show during async operations
- ✅ Pull-to-refresh works on all tabs
- ✅ Tab navigation is smooth and state persists
- ✅ No compilation errors or runtime crashes

---

## Quick Test Script (5 Minutes) 🚀

**Ultra-fast smoke test to verify everything works:**

1. **Start backend** → `python main.py`
2. **Start frontend** → `flutter run`
3. **Open Todo List screen** → Verify 3 tabs visible
4. **Tap ✨ button** → Daily quests generated
5. **Switch to Weekly Quests** → Tap ✨ → Weekly quests generated
6. **Log a mood** → Return to Daily Quests → Pull to refresh → Progress updated
7. **Write a journal** → Return to Daily Quests → Refresh → Progress updated
8. **Complete a todo** → Return to Daily Quests → Refresh → Progress updated
9. **Verify level-up** → If quest completes → Dialog should appear
10. **Switch to My Todos tab** → FAB icon changes to ➕

**If all 10 steps pass → Quest System is fully functional! 🎉**

---

## Backend Testing (Swagger UI) 🔧

### Quick API Test

1. Open: `http://localhost:8000/docs`
2. Authenticate (Login endpoint)
3. Run these tests:

**Test 1: Generate Daily Quests**

```
POST /quests/generate/daily
Expected: 201 status, returns array of 3-4 quests
```

**Test 2: Get Active Quests**

```
GET /quests/active
Expected: 200 status, returns:
{
  "daily_quests": [...],
  "weekly_quests": [...]
}
```

**Test 3: Update Progress**

```
POST /quests/progress
Body: {"category": "mood", "increment": 1}
Expected: 200 status, returns updated quests with progress incremented
```

**Test 4: Cleanup Expired**

```
DELETE /quests/cleanup
Expected: 200 status, returns count of deleted quests
```

---

## Debugging Tips 🐛

### Enable Verbose Logging

**Backend (main.py):**

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Frontend (lib/data/services/dio_client.dart):**

```dart
// Already has logging in interceptor, check console output
```

### Common Log Messages to Look For

**Success Indicators:**

- `POST /quests/progress → 200` (progress updated)
- `GET /quests/active → 200` (quests loaded)
- `POST /quests/generate/daily → 201` (quests created)

**Error Indicators:**

- `401 Unauthorized` → Token expired, re-login required
- `404 Not Found` → Endpoint path wrong or backend not running
- `500 Internal Server Error` → Backend error, check backend logs

---

## Final Notes 📝

- **Test on real device** for best performance assessment
- **Check both Android and iOS** if possible (emulators also fine)
- **Monitor backend logs** during testing for any errors
- **Use Flutter DevTools** for performance profiling if issues arise

**Happy Testing! 🚀**

---

**Testing Guide Version:** 1.0  
**Last Updated:** January 2025  
**Compatible With:** Quest System v1.0
