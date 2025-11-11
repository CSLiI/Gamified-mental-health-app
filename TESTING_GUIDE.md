# Quick Testing Guide - Friend Profile Fixes

## 🚀 Start Here

### 1. Restart Backend Server

```powershell
cd mental_health_app_backend
python main.py
```

Wait for: `Uvicorn running on http://0.0.0.0:8000`

### 2. Hot Reload Flutter App

Your Flutter app should automatically hot reload. If not:

- Press `r` in terminal, OR
- Press `Ctrl+Shift+F5` in VS Code

---

## ✅ Test Checklist (5 Minutes)

### Test 1: Character Display (Square Banner)

1. Open friend profile
2. **Expected**: Character image is SQUARE with rounded corners (not circle)
3. **Verify**: Correct character GIF shows (matching friend's chosen character)

### Test 2: Friend's Stats Accuracy

1. Open friend profile
2. **Check Stats Cards**: Level, Streak, XP
3. **Expected**: Should match friend's actual stats (not default 1/0/0)

### Test 3: Today's Goals Display

1. Scroll to "Today's Goals" section
2. **Expected**: Shows actual task names (NOT "Untitled Task")
3. **Check**: Only shows TODAY's tasks (not old ones)

### Test 4: Mood Updates in Friend List

1. From friend profile, go back to friend list
2. **Expected**: Character GIF and mood label update immediately
3. **No more**: Stuck on "Angry" or old mood

### Test 5: Challenges Viewing

1. Tap notifications bell icon 🔔 on home screen
2. Go to "Challenges" tab
3. **Expected**: Shows received challenges with sender names
4. **No more**: Empty state or "Not implemented yet"

---

## 🐛 If Something Doesn't Work

### Issue: Character still shows old GIF

**Fix**:

1. Hot restart (not just hot reload): `Shift+R` or stop and re-run
2. Clear app data and re-login

### Issue: Stats still show "Level 1"

**Fix**:

1. Check backend server is running (restarted after schema change)
2. Check terminal for API errors
3. Try logout and login again

### Issue: Todos still show "Untitled"

**Fix**:

1. Verify friend has created tasks TODAY (not yesterday)
2. Check backend date filtering is working
3. Refresh friend profile (swipe down)

### Issue: Challenges tab empty

**Fix**:

1. First SEND a challenge from another account
2. Refresh notifications screen (pull down)
3. Check backend terminal for errors

### Issue: Mood not updating in friend list

**Fix**:

1. Navigate to friend profile and back multiple times
2. Should see different character GIF if mood changed
3. Check backend logs for mood state calculation

---

## 🔍 Quick Debug Commands

### Check Backend is Running

```powershell
curl http://localhost:8000/health
```

Should return: `{"status":"healthy"}`

### Test Profile Endpoint (Replace USER_ID)

```powershell
# Windows PowerShell
$token = "YOUR_JWT_TOKEN"
$headers = @{ "Authorization" = "Bearer $token" }
Invoke-WebRequest -Uri "http://localhost:8000/users/USER_ID/profile" -Headers $headers
```

### Test Messages Endpoint

```powershell
$token = "YOUR_JWT_TOKEN"
$headers = @{ "Authorization" = "Bearer $token" }
Invoke-WebRequest -Uri "http://localhost:8000/messages/" -Headers $headers
```

---

## 📸 Expected Results (Screenshots Reference)

### Friend Profile - Before Fix

- ❌ Circle character image
- ❌ "Untitled Task" everywhere
- ❌ Level: 1, XP: 0 (always)
- ❌ Mood stuck on "Angry"

### Friend Profile - After Fix

- ✅ Square character image with rounded corners
- ✅ Actual task names visible
- ✅ Correct level, XP, streak
- ✅ Mood updates correctly

### Notifications Screen - Before Fix

- ❌ Challenges tab: Empty state
- ❌ "No challenges yet" message

### Notifications Screen - After Fix

- ✅ Challenges tab: Shows challenge messages
- ✅ Sender name, message content, time ago
- ✅ Unread indicator (if unread)

---

## 🎯 Critical Test Scenarios

### Scenario 1: Two-Account Full Test

1. **Account A (Sender)**:

   - Create a daily task: "Finish homework"
   - Log mood: "Happy"
   - Send encouragement to Account B: "You got this! 💪"
   - Send challenge to Account B: "Let's both journal today!"

2. **Account B (Receiver)**:

   - Open app → Tap notifications bell
   - See encouragement in Encouragement tab ✅
   - See challenge in Challenges tab ✅
   - Go to Friends list
   - Tap on Account A's profile
   - Verify: Character is SQUARE ✅
   - Verify: Correct character GIF for "Happy" mood ✅
   - Verify: Level, XP, Streak accurate ✅
   - Verify: "Finish homework" shows (not "Untitled") ✅

3. **Account A (Update)**:

   - Change mood to "Sad"

4. **Account B (Verify Update)**:
   - Go back to friend list
   - Verify: Account A's character GIF changed to Sad animation ✅
   - Tap on profile again
   - Verify: Mood status shows "SAD" ✅

---

## 🏁 Success Criteria

All 6 issues must be resolved:

1. ✅ Tasks show actual text (not "Untitled")
2. ✅ Character banner is square
3. ✅ Correct character GIF displays
4. ✅ Mood updates in friend list
5. ✅ Level, XP, Streak accurate
6. ✅ Challenges viewable in notifications

---

## 📞 Need Help?

### Check Backend Logs

Look in backend terminal for errors like:

- `403 Forbidden` - Friend check failing
- `404 Not Found` - Endpoint missing
- `500 Internal Server Error` - Database issue

### Check Flutter Logs

Look in Flutter debug console for:

- `Error loading friend data` - API call failing
- `[DEBUG UI]` messages - Character/mood data values
- DioException - Network/auth issues

### Common Fixes

1. **Restart Backend**: `Ctrl+C` then `python main.py`
2. **Hot Restart Flutter**: `R` (capital R) in terminal
3. **Clear App Data**: Uninstall and reinstall app
4. **Re-authenticate**: Logout and login again

---

**Testing Time**: ~5 minutes  
**Difficulty**: Easy  
**Required**: 2 user accounts (for full test)

Good luck! 🚀
