# Quick Reference: How Features Work

## 1. How Task Sharing Works

**User Side:**

- Your tasks come from your daily todo list
- Only today's tasks are shown
- Real-time updates when you complete tasks

**Friend Side:**

- Shows friend's daily tasks (once backend implemented)
- Updates when friend completes tasks
- Empty state if friend has no tasks

**API Call:**

```dart
// Your tasks - already working
final myTasks = await apiService.getTodos(periodType: 'daily');

// Friend tasks - needs backend
final friendTasks = await apiService.getFriendTodos(friendUserId, periodType: 'daily');
```

## 2. How Streak Sharing Works

**Data Shown:**

- Current streak (consecutive days)
- Longest streak ever
- Last activity date

**API Call:**

```dart
// Your streak - already working
final myStreak = await apiService.getMyStreak();

// Friend streak - needs backend
final friendStreak = await apiService.getFriendStreak(friendUserId);
```

**Backend Calculation:**

- Counts consecutive days with mood logs
- Resets if a day is missed
- Shows longest historical streak

## 3. How Encouragement Works

**Sending:**

1. User taps "Send Encouragement" button
2. Frontend calls: `apiService.sendEncouragement(friendId, "Keep it up! 💪")`
3. Backend stores in `encouragements` table
4. Backend can send push notification (optional)

**Receiving:**

1. Backend stores encouragement
2. User can view in notifications/encouragements screen
3. Marks as read when viewed

**API Calls:**

```dart
// Send
await apiService.sendEncouragement(friendId, message);

// Receive
final encouragements = await apiService.getEncouragements(unreadOnly: true);

// Mark read
await apiService.markEncouragementRead(encouragementId);
```

## 4. How Profile Viewing Works

**What's Shown:**

- Friend's name
- Friend's email
- Friend's chosen character (mood gif) ← **Profile picture**
- Friend's interests

**Character Display:**
The character the friend chose in character selection becomes their "profile picture" throughout the social features. It's displayed as:

- Avatar circle with character name/icon
- Full character info in profile dialog

**API Call:**

```dart
final profile = await apiService.getFriendProfile(friendUserId);
// Returns: name, email, character object, interests array
```

## 5. How Messaging Works

**Sending Message:**

1. User taps "Send Message" from friend options
2. Dialog opens with text field
3. Message sent via API
4. Stored in `messages` table

**Viewing Conversation:**

1. Get all messages between users
2. Display in chronological order
3. Auto-mark as read when viewed
4. Show sender name with each message

**API Calls:**

```dart
// Send
await apiService.sendMessage(friendId, messageText);

// View conversation
final messages = await apiService.getMessages(friendId);
```

## 6. How Character Acts as Profile Picture

**System Design:**
Your gamified character system already has users choose a character. This character is now used as their "profile picture" in social features.

**Where It Appears:**

1. **Friend Card**: Avatar circle with first initial
2. **Profile Dialog**: Full character display with name and image path
3. **Accountability View**: Avatar in task/streak sections
4. **Message Thread**: Sender avatar (future enhancement)

**Implementation:**

```dart
// In profile view
if (profile['character'] != null) {
  // Display character info
  Text(profile['character']['name'])
  // Or load character image from profile['character']['image_path']
}
```

**Character-to-Profile Mapping:**

- Character selected → Stored in `users.selected_character_id`
- Profile fetch → Includes character object
- Social features → Display character as profile picture

## 7. How Friend Options Menu Works

**Three Actions:**

1. **View Profile**

   - Opens dialog with character and info
   - API: `getFriendProfile(userId)`

2. **Send Message**

   - Opens message dialog
   - API: `sendMessage(friendId, text)`

3. **Remove Friend**
   - Confirms and removes friendship
   - API: `removeFriend(friendId)`

## Data Flow Diagram

```
User A (You)                    Backend                     User B (Friend)
     |                              |                              |
     |-- View Friend Tasks -------->|                              |
     |                              |<--- Query User B's Todos ----|
     |<---- Return Tasks -----------|                              |
     |                              |                              |
     |-- Send Encouragement ------->|                              |
     |                              |--- Store in DB               |
     |<---- Success ----------------|                              |
     |                              |--- Notify User B (optional)->|
     |                              |                              |
     |-- View Profile ------------->|                              |
     |                              |<--- Get User B Data ---------|
     |                              |<--- Get Character Data ------|
     |<---- Return Profile ---------|                              |
     |                              |                              |
     |-- Send Message ------------->|                              |
     |                              |--- Store Message             |
     |<---- Success ----------------|                              |
     |                              |--- Notify User B (optional)->|
```

## Empty State Behavior

**No Backend Endpoint:**

- Shows "No data available" message
- Icon displays (inbox, visibility_off, etc.)
- No crash, graceful fallback

**Backend Error:**

- Catches exception
- Logs error to console
- Shows user-friendly message
- Returns empty array/object

**No Data Available:**

- Backend returns successfully but empty
- Shows encouraging empty state
- "Start logging to build streaks"
- "No shared tasks yet"

## Testing Checklist

### Before Backend:

- [x] UI displays correctly
- [x] Empty states show
- [x] No crashes on missing data
- [x] Loading indicators work
- [x] Error messages are user-friendly

### After Backend:

- [ ] Tasks show real friend data
- [ ] Streaks show real friend data
- [ ] Encouragement arrives in notification
- [ ] Profile shows character correctly
- [ ] Messages send and receive
- [ ] Character image displays properly

## Common Issues & Solutions

**Issue**: Friend's tasks don't show
**Solution**: Backend endpoint `/users/{user_id}/todos` not implemented yet

**Issue**: Friend's streak shows 0
**Solution**: Backend endpoint `/users/{user_id}/streak` not implemented yet

**Issue**: Encouragement doesn't send
**Solution**: Backend endpoint `/friends/{friend_id}/encouragement` not implemented yet

**Issue**: Profile shows incomplete info
**Solution**: Backend endpoint `/users/{user_id}/profile` missing character data

**Issue**: Character doesn't display as profile picture
**Solution**: Ensure `selected_character_id` is set and character relationship is loaded

## Character Image Display

**To show actual character GIF/image:**

```dart
// In profile dialog
if (profile['character']?['image_path'] != null) {
  Image.asset(
    'assets/characters/${profile['character']['image_path']}',
    width: 150,
    height: 150,
  );
}
```

**Character GIF Paths:**
Based on your project structure:

- Boy character: `assets/images/Boy_Gif_33FPS/`
- Girl character: `assets/images/Girl_Gif_33FPS/`

Store in DB as: `"Boy_Gif_33FPS/frame_01.png"` or full animation path.

---

**Key Takeaway**: The character system doubles as the profile picture system. Users express themselves through their character choice, which appears throughout social features.
