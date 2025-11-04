# Social Accountability Features - Swagger Testing Guide

## 🚀 Setup Instructions

### 1. Start Backend Server

```powershell
cd mental_health_app_backend
python main.py
```

**That's it!** The new database tables (`encouragements` and `messages`) are **automatically created** by SQLAlchemy's `Base.metadata.create_all()` in `main.py` when the server starts.

Server starts on: `http://localhost:8000`

### 2. Access Swagger UI

Open your browser: **http://localhost:8000/docs**

You'll see all API endpoints with interactive testing interface.

---

## 🔐 Authentication Setup

**ALL social endpoints require authentication.** Follow these steps:

### Step 1: Login to Get Token

1. In Swagger UI, find **POST /auth/login**
2. Click "Try it out"
3. Fill in the form-data (use existing user from seed_data.py):
   ```
   username: johndoe@example.com
   password: password123
   ```
4. Click "Execute"
5. Copy the `access_token` from the response (looks like: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

### Step 2: Authorize in Swagger

1. Click the **🔓 Authorize** button at the top right
2. In the "Value" field, paste: `Bearer YOUR_TOKEN_HERE`
   - Example: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
3. Click "Authorize" then "Close"

Now all requests will include your authentication token! ✅

---

## 🧪 Testing Endpoints Step-by-Step

### Prerequisites: Create Friendships

Before testing social features, you need friends! Use these endpoints first:

#### 1. Send Friend Request

**POST /friends/request**

```json
{
  "friend_email": "janedoe@example.com"
}
```

#### 2. Accept Friend Request

- Login as the other user (janedoe@example.com)
- Get pending requests: **GET /friends/requests**
- Copy the `request_id` from response
- Accept: **PUT /friends/request/{request_id}/accept**

#### 3. Get Your Friends List

**GET /friends/**

Copy a `friendship_id` (the `id` field) and `friend_user_id` (the `friend_id` field) for the next tests.

---

## 📋 Test Social Features (9 New Endpoints)

### 1️⃣ View Friend's Daily Tasks

**Endpoint:** `GET /users/{user_id}/todos`

**Purpose:** See what tasks your friend has for today.

**Steps:**

1. Find **GET /users/{user_id}/todos** in Swagger
2. Click "Try it out"
3. Enter `user_id`: `2` (Jane Doe's user_id from GET /friends/)
4. Optional: Enter `period_type`: `morning` (or leave blank for all)
5. Click "Execute"

**Expected Response:**

```json
[
  {
    "id": 5,
    "user_id": 2,
    "title": "Morning meditation",
    "description": "10 minutes mindfulness",
    "is_completed": true,
    "period_type": "morning",
    "created_at": "2024-01-15T08:00:00"
  },
  {
    "id": 6,
    "user_id": 2,
    "title": "Study session",
    "description": "Review notes",
    "is_completed": false,
    "period_type": "afternoon",
    "created_at": "2024-01-15T09:00:00"
  }
]
```

**Empty State (No Tasks):**

```json
[]
```

---

### 2️⃣ View Friend's Streak

**Endpoint:** `GET /users/{user_id}/streak`

**Purpose:** See your friend's consistency with their mental health habits.

**Steps:**

1. Find **GET /users/{user_id}/streak**
2. Click "Try it out"
3. Enter `user_id`: `2`
4. Click "Execute"

**Expected Response:**

```json
{
  "current_streak": 7,
  "longest_streak": 14,
  "last_log_date": "2024-01-15"
}
```

**Empty State (New User):**

```json
{
  "current_streak": 0,
  "longest_streak": 0,
  "last_log_date": null
}
```

---

### 3️⃣ Send Encouragement

**Endpoint:** `POST /friends/{friendship_id}/encouragement`

**Purpose:** Send a motivational message to your friend.

**Steps:**

1. Get your friendship_id first: **GET /friends/** (look for the `id` field, not `friend_id`)
2. Find **POST /friends/{friendship_id}/encouragement**
3. Click "Try it out"
4. Enter `friendship_id`: (use the id from step 1, e.g., `1`)
5. Enter request body:
   ```json
   {
     "message": "You're doing amazing! Keep up the great work! 💪"
   }
   ```
6. Click "Execute"

**Expected Response:**

```json
{
  "message": "Encouragement sent successfully"
}
```

**Try Different Messages:**

- "Proud of your progress! 🌟"
- "You've got this! Keep going! 🚀"
- "Sending positive vibes your way! ✨"

---

### 4️⃣ Get Your Encouragements

**Endpoint:** `GET /encouragements`

**Purpose:** See all encouragement messages sent to you.

**Steps:**

1. **Switch user:** Logout and login as `janedoe@example.com` (the receiver)
2. Find **GET /encouragements**
3. Click "Try it out"
4. Optional: Set `unread_only`: `true` (to see only unread)
5. Click "Execute"

**Expected Response:**

```json
[
  {
    "id": 1,
    "sender_id": 1,
    "receiver_id": 2,
    "sender_first_name": "John",
    "sender_last_name": "Doe",
    "message": "You're doing amazing! Keep up the great work! 💪",
    "is_read": false,
    "created_at": "2024-01-15T14:25:30.123456"
  }
]
```

**Empty State:**

```json
[]
```

---

### 5️⃣ Get Unread Encouragement Count

**Endpoint:** `GET /encouragements/unread-count`

**Purpose:** Quick check for notification badge.

**Steps:**

1. Find **GET /encouragements/unread-count**
2. Click "Try it out"
3. Click "Execute"

**Expected Response:**

```json
{
  "unread_count": 3
}
```

---

### 6️⃣ Mark Encouragement as Read

**Endpoint:** `PUT /encouragements/{encouragement_id}/read`

**Purpose:** Mark message as seen (like marking notification as read).

**Steps:**

1. First get encouragements: **GET /encouragements**
2. Copy an `id` from the response (e.g., `1`)
3. Find **PUT /encouragements/{encouragement_id}/read**
4. Click "Try it out"
5. Enter `encouragement_id`: `1`
6. Click "Execute"

**Expected Response:**

```json
{
  "message": "Marked as read"
}
```

Notice if you call **GET /encouragements** again, the `is_read` field will be `true`! ✅

---

### 7️⃣ Send Message

**Endpoint:** `POST /friends/{friendship_id}/messages`

**Purpose:** Send a private message to your friend (chat feature).

**Steps:**

1. **Switch back** to `johndoe@example.com` user
2. Find **POST /friends/{friendship_id}/messages**
3. Click "Try it out"
4. Enter `friendship_id`: (use the same friendship_id from step 3, e.g., `1`)
5. Enter request body:
   ```json
   {
     "message": "Hey! How are you feeling today?"
   }
   ```
6. Click "Execute"

**Expected Response:**

```json
{
  "message": "Message sent successfully"
}
```

**Send More Messages:**

```json
{"message": "Want to do a study session together?"}
{"message": "I completed all my morning tasks! 🎉"}
```

---

### 8️⃣ Get Conversation History

**Endpoint:** `GET /friends/{friendship_id}/messages`

**Purpose:** View all messages between you and a friend (chat history).

**Steps:**

1. Find **GET /friends/{friendship_id}/messages**
2. Click "Try it out"
3. Enter `friendship_id`: (use the same friendship_id, e.g., `1`)
4. Click "Execute"

**Expected Response:**

```json
[
  {
    "id": 1,
    "sender_id": 1,
    "receiver_id": 2,
    "sender_first_name": "John",
    "sender_last_name": "Doe",
    "message": "Hey! How are you feeling today?",
    "is_read": true,
    "created_at": "2024-01-15T14:30:00.123456"
  },
  {
    "id": 2,
    "sender_id": 1,
    "receiver_id": 2,
    "sender_first_name": "John",
    "sender_last_name": "Doe",
    "message": "Want to do a study session together?",
    "is_read": true,
    "created_at": "2024-01-15T14:31:00.123456"
  },
  {
    "id": 3,
    "sender_id": 2,
    "receiver_id": 1,
    "sender_first_name": "Jane",
    "sender_last_name": "Doe",
    "message": "I'm doing well! Just finished my workout.",
    "is_read": true,
    "created_at": "2024-01-15T14:32:00.123456"
  }
]
```

**Note:** Messages are sorted in chronological order (oldest first), and any unread messages are automatically marked as read when you fetch them!

**Empty State (No Messages):**

```json
[]
```

---

### 9️⃣ Get Friend Profile

**Endpoint:** `GET /users/{user_id}/profile`

**Purpose:** View friend's full profile with character (for profile picture display).

**Steps:**

1. Find **GET /users/{user_id}/profile**
2. Click "Try it out"
3. Enter `user_id`: `2`
4. Click "Execute"

**Expected Response:**

```json
{
  "id": 2,
  "email": "janedoe@example.com",
  "first_name": "Jane",
  "last_name": "Doe",
  "date_of_birth": "1998-03-20",
  "gender": "female",
  "character": {
    "id": 2,
    "name": "Luna",
    "gender": "female",
    "description": "A calm and peaceful character",
    "image_url": "/characters/luna_neutral.png",
    "number": 2
  },
  "interests": [
    { "id": 1, "name": "Meditation" },
    { "id": 3, "name": "Reading" }
  ]
}
```

**Character Field:** This is used as the profile picture (mood GIF) in the Flutter app!

---

## 🎯 Complete Testing Flow

Test the full user journey:

### Scenario: Two Friends Encouraging Each Other

**User A (John): johndoe@example.com**
**User B (Jane): janedoe@example.com**

1. **John sends encouragement to Jane:**

   - Login as John
   - `POST /friends/{friendship_id}/encouragement` with message: "Keep going! 💪"

2. **Jane receives notification:**

   - Login as Jane
   - `GET /encouragements/unread-count` → Should show `1`
   - `GET /encouragements` → See John's message

3. **Jane reads the encouragement:**

   - `PUT /encouragements/1/read`
   - `GET /encouragements/unread-count` → Should show `0`

4. **Jane views John's progress:**

   - `GET /users/1/todos` → See John's daily tasks
   - `GET /users/1/streak` → See John's streak

5. **Jane sends back encouragement:**

   - Get friendship_id first: `GET /friends/` (look for John, get the `id`)
   - `POST /friends/{friendship_id}/encouragement` with message: "You too! Amazing work! ✨"

6. **They start chatting:**
   - Jane: `POST /friends/{friendship_id}/messages` → `{"message": "Hey! Thanks for the encouragement!"}`
   - John (login as John): `GET /friends/{friendship_id}/messages` → See Jane's message
   - John: `POST /friends/{friendship_id}/messages` → `{"message": "No problem! Want to study together?"}`
   - Jane (login as Jane): `GET /friends/{friendship_id}/messages` → See conversation history

---

## 🐛 Troubleshooting

### Error: "Not authenticated"

**Fix:** Make sure you clicked the 🔓 Authorize button and entered `Bearer YOUR_TOKEN`

### Error: "Friendship not found"

**Fix:** Create a friendship first using:

1. `POST /friends/request`
2. Login as other user
3. `PUT /friends/request/{id}/accept`

**OR** Make sure you're using the correct `friendship_id` (the `id` field from `/friends/`), not the `friend_id`.

### Error: "Encouragement not found" / "Message not found"

**Fix:** Make sure you're accessing messages/encouragements where you're the receiver, not sender.

### Error: "Could not find encouragement with id X"

**Fix:** You can only mark YOUR OWN received encouragements as read (not ones you sent).

### Database Table Not Found

**Fix:** Restart the server with `python main.py` - tables are auto-created on startup!

---

## ✅ Success Checklist

After testing, verify:

- [ ] Can view friend's tasks (with and without data)
- [ ] Can view friend's streak (with and without data)
- [ ] Can send encouragement
- [ ] Can receive encouragement
- [ ] Can get unread count
- [ ] Can mark encouragement as read
- [ ] Can send message
- [ ] Can view conversation history
- [ ] Can view friend profile with character
- [ ] All empty states return proper responses
- [ ] Authentication works for all endpoints

---

## 🎨 Frontend Integration

These endpoints are already integrated in `social_screen.dart`:

| Feature             | Endpoint                                      | UI Element                       |
| ------------------- | --------------------------------------------- | -------------------------------- |
| Friend tasks        | `GET /users/{user_id}/todos`                  | Task sharing cards               |
| Friend streak       | `GET /users/{user_id}/streak`                 | Streak comparison                |
| Send encouragement  | `POST /friends/{friendship_id}/encouragement` | "Send Encouragement" button      |
| View encouragements | `GET /encouragements/`                        | (Not yet in UI - you can add)    |
| Send message        | `POST /friends/{friendship_id}/messages`      | "Send Message" dialog            |
| View messages       | `GET /friends/{friendship_id}/messages`       | (Not yet in UI - you can add)    |
| Friend profile      | `GET /users/{user_id}/profile`                | Character display as profile pic |

The Flutter app will automatically use these endpoints once the backend is running! 🎉

---

## 📝 Next Steps

1. ✅ Start backend: `python main.py` (tables auto-created!)
2. ✅ Test all endpoints in Swagger
3. ✅ Run the Flutter app and see real data
4. 🎯 Add encouragement/message inbox to Flutter UI (optional)
5. 🎯 Add push notifications for new encouragements/messages (optional)

**Happy Testing! 🚀**
