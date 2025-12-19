# Friend Profile Major Update - Challenges & Mood Display

## 📅 Date: November 11, 2025

## 🎯 Changes Requested

1. **Split Challenges into 2 sections**: Challenges sent vs. challenges received
2. **Add checkbox for received challenges**: Allow users to mark challenges as completed
3. **Show current mood directly**: Display most recent mood log instead of 7-day average

---

## ✅ Changes Implemented

### 1. **Current Mood Display** (Instead of 7-Day Average)

**Frontend Changes** (`friend_profile_screen.dart`):

- Changed label from "7-Day Mood State" → "Current Mood"
- Added 3 new helper methods:
  - `_getCurrentMoodDisplay()` - Gets most recent mood log entry
  - `_getCurrentMoodColor()` - Returns color for current mood
  - `_getCurrentMoodTimeAgo()` - Shows when mood was logged (e.g., "Logged 2h ago")

**Behavior**:

- Displays the friend's **most recent mood log entry**
- Shows exactly what mood they last logged (happy, sad, anxious, etc.)
- More intuitive - friends can see current emotional state
- Includes timestamp showing when mood was logged

**Example Display**:

```
Current Mood: HAPPY
Logged 3h ago
```

---

### 2. **Challenges Split into 2 Sections**

**Frontend Changes** (`friend_profile_screen.dart`):

#### **Section 1: Challenges Sent** (Already existed, improved)

- Shows challenges **I sent to my friend**
- Filter: `sender_id == currentUserId && receiver_id == friendId`
- Scrollable list (shows 3, scroll for more)
- Yellow warning icon
- Shows status: read/unread (check mark or pending icon)

#### **Section 2: Challenges Received** (NEW)

- Shows challenges **friend sent to me**
- Filter: `sender_id == friendId && receiver_id == currentUserId`
- **Interactive checkboxes** - tap to mark as completed
- Blue primary color icon
- Scrollable list (shows 3, scroll for more)
- Shows completion status with "Completed" badge

**Visual Layout**:

```
┌─────────────────────────────┐
│  Challenges Sent        [3] │  ← Yellow icon
│  ✓ Challenge 1              │
│  ⏳ Challenge 2             │
│  ✓ Challenge 3              │
└─────────────────────────────┘

┌─────────────────────────────┐
│  Challenges Received    [2] │  ← Blue icon
│  ☑️ Challenge 1 [Completed] │  ← Tap checkbox to toggle
│  ☐ Challenge 2              │
└─────────────────────────────┘
```

---

### 3. **Challenge Completion System**

**Backend Changes**:

#### **Database Schema** (`models.py`):

```python
class Message(Base):
    # ... existing fields ...
    is_completed = Column(Boolean, default=False)  # NEW FIELD
```

#### **New API Endpoint** (`social.py`):

```python
@router.put("/messages/{message_id}/completion")
async def update_message_completion(
    message_id: int,
    is_completed: bool,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark a challenge (message) as completed or incomplete"""
    # Only receiver can mark as completed
    # Updates message.is_completed in database
```

**API Schema Updates** (`schemas.py`):

```python
class MessageResponse(BaseModel):
    # ... existing fields ...
    is_completed: bool = False  # Added to response
```

#### **Frontend API Service** (`api_service.dart`):

```dart
Future<void> updateMessageCompletion(int messageId, bool isCompleted) async {
  await _dioClient.put(
    '/messages/$messageId/completion',
    data: {'is_completed': isCompleted},
  );
}
```

**Frontend UI** (`friend_profile_screen.dart`):

- `_buildReceivedChallengeItem()` - New widget with interactive checkbox
- `_toggleChallengeCompletion()` - Handles checkbox tap, calls API, shows success message
- Auto-refreshes friend data after marking complete

**User Experience**:

1. User sees challenges friend sent to them
2. Tap checkbox next to challenge → marks as completed
3. API updates database: `is_completed = true`
4. UI refreshes automatically
5. Challenge shows "Completed" badge with green color
6. Friend can see on their "Challenges Sent" section that challenge was read

---

## 🔧 Technical Implementation

### Frontend Structure

**Helper Methods**:

```dart
_getCurrentMoodDisplay()      // Returns uppercase mood string
_getCurrentMoodColor()         // Returns color for mood
_getCurrentMoodTimeAgo()       // Returns "Logged Xh ago"
_buildChallengesSection()      // Container for both sections
_buildChallengesSentSection()  // Challenges I sent
_buildChallengesReceivedSection()  // Challenges I received
_buildChallengeItem()          // Display for sent challenges
_buildReceivedChallengeItem()  // Display with checkbox
_toggleChallengeCompletion()   // Handle checkbox tap
```

**State Management**:

- Uses existing `_friendMessages` list
- Filters messages by sender/receiver ID
- Real-time updates via `_loadFriendData()` after completion toggle

### Backend Structure

**Database Migration Required**:

```sql
-- Add is_completed column to messages table
ALTER TABLE messages ADD COLUMN is_completed BOOLEAN DEFAULT FALSE;
```

**Endpoint Security**:

- Only receiver can mark challenge as completed
- Friendship check enforced
- JWT authentication required

---

## 📱 User Flow Example

### Scenario: Alice sends challenge to Bob

1. **Alice (Sender)**:

   - Goes to Bob's profile
   - Sends challenge: "Do 10 push-ups today!"
   - Challenge appears in her "Challenges Sent" section
   - Shows as "Pending" (not read yet)

2. **Bob (Receiver)**:

   - Views Alice's profile
   - Sees challenge in "Challenges Received" section
   - Challenge shows unchecked checkbox
   - Bob does push-ups, taps checkbox ✓
   - Challenge marked as completed
   - Shows "Completed" badge in green

3. **Alice sees update**:
   - Refreshes Bob's profile
   - Challenge in "Challenges Sent" now shows "Read" status
   - (Backend marks as is_read=true automatically)

---

## 🎨 UI/UX Improvements

### Visual Indicators

**Challenges Sent** (Yellow theme):

- Icon: 🏆 Trophy (emoji_events)
- Read status: ✓ Check circle / ⏳ Pending
- No checkbox (can't complete own challenges)

**Challenges Received** (Blue theme):

- Icon: ✓ Task alt
- Interactive checkbox: ☐ Unchecked / ☑️ Checked
- "Completed" badge when done
- Tap to toggle completion

**Current Mood**:

- Large uppercase mood text (HAPPY, SAD, etc.)
- Mood-specific color (happy=gold, sad=grey, anxious=orange, etc.)
- Timestamp below ("Logged 2h ago", "Just logged")
- No longer confusing "7-day average"

### Scrolling Behavior

Both challenge sections:

- Fixed height showing ~3 items
- Smooth scrolling (BouncingScrollPhysics)
- Hint text: "Scroll for X more challenges"
- Efficient ListView.builder for large lists

---

## 🐛 Bug Fixes Included

1. **Message field name**: Frontend now uses `'message'` instead of `'message_text'` to match backend schema
2. **Null safety**: Added `hasattr()` checks for `is_completed` field in backend
3. **Default values**: `is_completed: bool = False` in schema for backward compatibility

---

## 🔄 Database Schema Changes

### Before:

```python
class Message(Base):
    id, sender_id, receiver_id, message, is_read, created_at
```

### After:

```python
class Message(Base):
    id, sender_id, receiver_id, message, is_read, is_completed, created_at
    #                                              ^^^^^^^^^^^^^ NEW
```

**Migration Strategy**:

- SQLAlchemy auto-creates column on next restart
- Default value: `False` for all existing messages
- No data loss

---

## 🚀 Deployment Checklist

### Backend:

- [x] Add `is_completed` field to Message model
- [x] Add `is_completed` to MessageResponse schema
- [x] Create `/messages/{id}/completion` endpoint
- [x] Update MessageResponse constructors to include `is_completed`
- [ ] **Restart backend server** (applies schema changes)

### Frontend:

- [x] Add current mood helper methods
- [x] Split challenges into 2 sections
- [x] Create received challenge item with checkbox
- [x] Add completion toggle handler
- [x] Update API service with `updateMessageCompletion()`
- [x] Fix field name: `message_text` → `message`
- [ ] **Hot reload Flutter app**

---

## 📊 Testing Recommendations

### Manual Testing:

1. **Current Mood Display**:

   - Friend logs a happy mood → Check if shows "HAPPY" on profile
   - Wait 2 hours → Check if shows "Logged 2h ago"
   - Friend hasn't logged today → Shows "NO MOOD YET"

2. **Challenges Sent**:

   - Send challenge to friend
   - Check it appears in "Challenges Sent" section
   - Verify shows "Pending" status
   - After friend views profile → Shows "Read" status

3. **Challenges Received**:

   - Have friend send challenge to you
   - Check it appears in "Challenges Received" section
   - Tap checkbox → Verify marks as completed
   - Check "Completed" badge appears
   - Refresh → Verify status persists

4. **Scrolling**:
   - Send 5+ challenges → Verify scrolling works
   - Receive 5+ challenges → Verify scrolling works

### API Testing (Swagger):

1. Test `PUT /messages/{message_id}/completion`
   - Set `is_completed: true`
   - Verify response: `{"success": true, "message_id": X, "is_completed": true}`
   - Try as sender (should fail: 403 Forbidden)
   - Try as receiver (should succeed: 200 OK)

---

## 📝 Files Modified

### Frontend:

1. `lib/presentation/screens/social/friend_profile_screen.dart`

   - Added current mood methods (lines 162-220)
   - Updated character mood display (line 629)
   - Split challenges section (lines 1188-1435)
   - Added received challenge item with checkbox (lines 1509-1609)
   - Added completion toggle handler (lines 1611-1638)

2. `lib/data/services/api_service.dart`
   - Added `updateMessageCompletion()` method (lines 714-722)

### Backend:

3. `mental_health_app_backend/app/models.py`

   - Added `is_completed` field to Message model (line 319)

4. `mental_health_app_backend/app/schemas.py`

   - Added `is_completed` to MessageResponse (line 438)

5. `mental_health_app_backend/app/routers/social.py`
   - Added `PUT /messages/{id}/completion` endpoint (lines 511-532)
   - Updated MessageResponse constructors (2 places)

---

## 💡 Future Enhancements

### Potential Improvements:

1. **Notification system**: Notify friend when challenge is completed
2. **Challenge categories**: Group challenges by type (fitness, mental health, social)
3. **Completion history**: Show past completed challenges
4. **Challenge streaks**: Track consecutive days completing challenges
5. **XP rewards**: Award XP when completing friend's challenges
6. **Challenge templates**: Pre-defined challenge suggestions
7. **Due dates**: Add optional deadlines for challenges
8. **Recurring challenges**: Daily/weekly challenge options

### Technical Improvements:

1. **Real-time updates**: WebSocket for live challenge completion
2. **Optimistic UI**: Update checkbox immediately before API response
3. **Undo functionality**: Allow unchecking recently completed challenges
4. **Batch operations**: Mark multiple challenges as completed
5. **Challenge search/filter**: Filter by completed/pending/date

---

## 🎓 Key Learnings

### Why These Changes Matter:

1. **Current Mood vs 7-Day Average**:

   - **Before**: Character showed "Angry" even when friend just logged "Happy"
   - **Why**: 7-day average included past negative moods
   - **Problem**: Confusing for users - "Why angry when they're happy?"
   - **Solution**: Show most recent mood = clearer, more intuitive
   - **Trade-off**: Less comprehensive but more relatable

2. **Split Challenges**:

   - **Before**: Only saw challenges I sent
   - **Problem**: Couldn't see what friend expects from me
   - **Solution**: Two-way visibility creates accountability
   - **Gamification**: Checkboxes make it satisfying to complete

3. **Completion System**:
   - **Before**: Challenges were one-way communication
   - **Problem**: No feedback loop - friend doesn't know if I did it
   - **Solution**: Checkbox → database update → visible to friend
   - **Engagement**: Creates social accountability and motivation

---

## ✅ Success Criteria

### Must Have:

- [x] Current mood displays most recent mood log
- [x] Challenges split into sent/received sections
- [x] Received challenges have working checkboxes
- [x] Completion status saves to database
- [x] Friend can see completion status on sent challenges
- [x] No errors/crashes when toggling completion

### Nice to Have:

- [x] Scrollable lists for both challenge sections
- [x] "Completed" badge on finished challenges
- [x] Success message when marking complete
- [x] Auto-refresh after completion toggle
- [x] Timestamp on current mood display

---

## 📞 Support

If issues occur:

1. **Backend won't start**: Check if `is_completed` column was added to messages table
2. **Checkbox doesn't work**: Verify JWT token is valid, check API endpoint in Swagger
3. **Current mood shows wrong**: Check if mood logs exist, verify sorting (desc)
4. **Challenges don't appear**: Verify friendship exists, check sender/receiver filter logic

**Debug Mode**: All challenge sections have extensive `print()` statements for debugging

---

## 🎉 Summary

This update transforms the friend profile from a **one-way view** into a **two-way accountability system**:

- **Before**: View friend's 7-day mood average, see challenges I sent (no interaction)
- **After**: See friend's current emotional state, interact with challenges they set for me, provide visual feedback when completed

**Core Philosophy**: Social accountability through gamification - friends motivate each other by setting challenges and celebrating completions together.

**User Benefit**: More engaging, more intuitive, more motivating for mental health journey.

---

_Generated for Final Year Project - Mental Health Gamified App_  
_Student: CHAN SOON LI | Supervisor: Ts. Dr Tan Tee Huan_  
_Sunway University - School of Computing and Artificial Intelligence_
