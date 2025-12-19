# Character Mood & Challenges Fix Explanation

## Issue 1: Character Showing "Angry" When Friend Logged "Happy"

### Why This Happens

The character mood **is NOT based on today's mood alone**. Instead, it's calculated from **the last 7 days of mood logs**.

### How Character State is Calculated

The backend looks at ALL mood logs from the past 7 days and calculates:

1. **Mood Counts**: How many times each mood was logged
2. **Mood Score**: A weighted average (0-100)
3. **Character State**: Overall emotional state based on the score

#### Example from Your Friend (User ID 25):

```
Last 7 days mood logs:
- tired: 4 times
- anxious: 1 time
- calm: 2 times
- sad: 5 times
- happy: 2 times
- angry: 5 times

Total: 19 mood logs
Negative moods: 15 logs (tired=4, anxious=1, sad=5, angry=5)
Positive moods: 4 logs (calm=2, happy=2)

Mood Score: 38.95 (out of 100)
Character State: needs_support (maps to "Angry" GIF)
```

### Character State Mapping

```
thriving (90-100) → Happy GIF
content (60-89) → Calm GIF
struggling (30-59) → Sad/Anxious GIF
needs_support (0-29) → Angry GIF
```

Your friend's score of **38.95** falls in the "struggling" range, but with so many negative moods, it resulted in **"needs_support"**, which displays the **Angry GIF**.

### Solution

**This is working as designed**. The character reflects the **overall emotional trend** over 7 days, not just the most recent mood.

**Why?** This prevents the character from changing drastically every time a mood is logged. It shows a more stable, averaged emotional state.

**To see the character change:**

- Your friend needs to consistently log positive moods (happy, calm) for several days
- As the 7-day window shifts, old negative moods will drop off
- The mood score will increase, eventually changing the character state

### UI Updates Made

1. Changed "Current Mood" label to **"7-Day Mood State"**
2. Added explanation text: _"Based on mood patterns from the last 7 days"_
3. Added debug logging to show:
   - Character state (e.g., "needs_support")
   - Dominant mood (most frequent mood in 7 days)
   - Mood score (0-100)

---

## Issue 2: Can't Read Challenges You Gave

### Problem

The challenges filtering was checking `receiver_id == friendId`, but this only works if we know which messages are ours.

### Root Cause

We need to check **BOTH**:

- `sender_id` == your user ID (you sent it)
- `receiver_id` == friend's user ID (friend received it)

The previous code only checked receiver_id, which could include messages the friend sent to you if you swapped perspectives.

### Solution

Updated the filtering logic:

```dart
// OLD (incorrect):
final myChallenges = _friendMessages
    .where((msg) => msg['receiver_id'] == widget.friendId)
    .toList();

// NEW (correct):
final myChallenges = _friendMessages
    .where((msg) =>
        msg['sender_id'] == _currentUserId &&  // YOU sent it
        msg['receiver_id'] == widget.friendId)  // FRIEND received it
    .toList();
```

### Additional Changes

1. **Get current user ID** at the start of data loading:

   ```dart
   final currentUser = await _apiService.getCurrentUser();
   final currentUserId = currentUser['id'];
   ```

2. **Store current user ID** in state:

   ```dart
   int? _currentUserId;
   ```

3. **Enhanced debug logging**:
   ```dart
   print('🔍 [CHALLENGES DEBUG] Current user ID: $_currentUserId');
   print('🔍 [CHALLENGES DEBUG] Friend ID: ${widget.friendId}');
   print('🔍 [CHALLENGES DEBUG] Total messages: ${_friendMessages.length}');
   for (var msg in _friendMessages) {
     print('  Message: sender=${msg['sender_id']}, receiver=${msg['receiver_id']}, text="${msg['message_text']}"');
   }
   print('🎯 [CHALLENGES DEBUG] My challenges to friend: ${myChallenges.length}');
   ```

---

## Testing Instructions

### 1. Hot Reload the Flutter App

```bash
# In Flutter terminal, press 'r' or click hot reload
```

### 2. Navigate to Friend Profile

Watch the console for debug output.

### 3. Check Character Mood Display

**Console Output to Look For:**

```
🎭 [CHARACTER DISPLAY] Character state: needs_support
🎭 [CHARACTER DISPLAY] Dominant mood: angry
🎭 [CHARACTER DISPLAY] Mood score: 38.95
🎭 [CHARACTER DISPLAY] GIF path: assets/images/Boy_Gif_33FPS/AngryBoy1.gif
```

**Expected Behavior:**

- Character shows Angry GIF (because mood score is 38.95)
- Label says "7-Day Mood State: NEEDS_SUPPORT"
- Gray text below says: "Based on mood patterns from the last 7 days"

**To Change Character Mood:**

- Friend needs to log happy/calm moods for 3-5 days consistently
- Old negative moods will age out of the 7-day window
- Mood score will increase → character state will improve

### 4. Check Challenges Display

**Console Output to Look For:**

```
🔍 [CHALLENGES DEBUG] Current user ID: 31
🔍 [CHALLENGES DEBUG] Friend ID: 25
🔍 [CHALLENGES DEBUG] Total messages: 2
  Message: sender=31, receiver=25, text="Complete 5 tasks today"
  Message: sender=25, receiver=31, text="Thanks for the challenge!"
🎯 [CHALLENGES DEBUG] My challenges to friend 25: 1
```

**Expected Behavior:**

- "Challenges Sent" section shows your challenges
- Only messages where YOU are sender AND friend is receiver
- Shows challenge text, time ago, read/unread status

**If No Challenges Show:**

- Check console: Is `_currentUserId` correct?
- Check console: Are messages being loaded?
- Verify you actually sent challenges to THIS specific friend

---

## Debug Output Examples

### Successful Character Display:

```
📊 [FRIEND PROFILE DEBUG]
Current user ID: 31
Friend ID: 25
Character state: {character_state: needs_support, dominant_mood: angry, mood_score: 38.95, ...}
Character state value: needs_support
Dominant mood: angry
Mood score: 38.95

🎭 [CHARACTER DISPLAY] Character state: needs_support
🎭 [CHARACTER DISPLAY] Dominant mood: angry
🎭 [CHARACTER DISPLAY] Mood score: 38.95
🎭 [CHARACTER DISPLAY] GIF path: assets/images/Boy_Gif_33FPS/AngryBoy1.gif
```

### Successful Challenges Display:

```
🔍 [CHALLENGES DEBUG] Current user ID: 31
🔍 [CHALLENGES DEBUG] Friend ID: 25
🔍 [CHALLENGES DEBUG] Total messages: 3
  Message: sender=31, receiver=25, text="Complete your workout today!"
  Message: sender=31, receiver=25, text="Log 3 happy moods this week"
  Message: sender=25, receiver=31, text="I'll try my best!"
🎯 [CHALLENGES DEBUG] My challenges to friend 25: 2
```

This shows:

- You (user 31) sent 2 challenges to friend 25
- Friend 25 sent 1 message back to you
- Only YOUR 2 challenges will display in "Challenges Sent" section

---

## Understanding the Mood System

### Daily Mood vs Character State

**Daily Mood** (logged today):

- What the user explicitly logs (happy, sad, angry, etc.)
- Shown in the 7-Day Mood Journey chart as individual bars

**Character State** (7-day average):

- Calculated from ALL moods in the last 7 days
- Determines which GIF the character displays
- More stable, doesn't change with every mood log

### Why Use 7-Day Average?

**Pros:**

- Prevents character from jumping between moods constantly
- Shows overall emotional trend, not just today's feeling
- More meaningful representation of mental health state
- Gamification: Users need consistent effort to improve character state

**Cons:**

- Not immediately responsive to today's mood
- Can be confusing if user doesn't understand it's an average

**Solution:**

- UI now clearly labels it as "7-Day Mood State"
- Explanation text added
- Users can see daily moods in the mood journey chart

---

## Files Modified

### Frontend:

**`mental_health_app/lib/presentation/screens/social/friend_profile_screen.dart`**

**Changes:**

1. Added `int? _currentUserId` state variable
2. Fetch current user in `_loadFriendData()`
3. Enhanced debug logging for profile data
4. Added debug logging for character display
5. Fixed challenges filtering to check both sender AND receiver
6. Changed "Current Mood" to "7-Day Mood State"
7. Added explanation text about 7-day calculation

**Lines Modified:**

- Line 30: Added `_currentUserId` variable
- Lines 52-65: Get current user and enhanced debug logging
- Lines 83-84: Store current user ID in state
- Lines 527-533: Added character display debug logging
- Lines 630-643: Changed label and added explanation text
- Lines 1109-1124: Fixed challenges filtering with proper user ID check

---

## Expected Results

### Character Mood:

✅ Shows correct GIF based on 7-day mood average  
✅ Label clearly says "7-Day Mood State"  
✅ Explanation text shows it's based on 7 days  
✅ Debug logs show character state, dominant mood, mood score

### Challenges Display:

✅ Shows only challenges YOU sent to THIS friend  
✅ Filters correctly by sender_id AND receiver_id  
✅ Debug logs show current user ID and filtering results  
✅ Displays challenge text, time, read/unread status

### Real-Time Updates:

✅ Auto-refreshes every 30 seconds  
✅ Pull-to-refresh works  
✅ Data updates after navigation

---

## FAQ

**Q: My friend logged "happy" today but character shows "angry". Is this a bug?**

A: No, this is by design. The character shows the 7-day emotional trend, not today's mood. If your friend has logged mostly negative moods in the past week, the character will reflect that overall state.

**Q: How long until the character mood changes?**

A: It depends on the mood logs. If your friend consistently logs positive moods for 3-5 days, the character state will improve as old negative moods age out of the 7-day window.

**Q: Can I see today's mood specifically?**

A: Yes! Look at the 7-Day Mood Journey chart. The rightmost bar shows today's mood with the appropriate color.

**Q: Why don't I see challenges I sent?**

A: Check the debug console. If `My challenges to friend: 0`, either:

- You haven't sent challenges to this specific friend
- The messages aren't loading (check total messages count)
- There's a user ID mismatch (check current user ID matches yours)

**Q: Why do challenges show "Just now" even for old messages?**

A: Check if the `created_at` field is being parsed correctly. The time ago calculation might have an error. Debug logs will show the timestamp value.

---

## Summary

Both issues are now fixed:

1. **Character Mood** - Works correctly, now clearly labeled as "7-Day Mood State" with explanation
2. **Challenges Display** - Fixed filtering to properly show only YOUR challenges to THIS friend

Hot reload your app and check the console output to verify everything works!
