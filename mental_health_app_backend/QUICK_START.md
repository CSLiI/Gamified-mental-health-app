# Quick Start Guide - Social Accountability Backend

## ✅ What's Been Implemented

### New Database Models

- **Encouragement** - Users can send motivational messages to friends
- **Message** - Private messaging between friends

### New API Endpoints (8 Total)

1. `GET /users/{user_id}/todos` - View friend's daily tasks
2. `GET /users/{user_id}/streak` - View friend's streak data
3. `POST /friends/{friendship_id}/encouragement` - Send encouragement
4. `GET /encouragements/` - Get received encouragements
5. `GET /encouragements/unread-count` - Count unread encouragements
6. `PUT /encouragements/{id}/read` - Mark encouragement as read
7. `POST /friends/{friendship_id}/messages` - Send message
8. `GET /friends/{friendship_id}/messages` - Get conversation history
9. `GET /users/{user_id}/profile` - Get friend's profile with character

### Files Modified/Created

- ✅ `app/models.py` - Added Encouragement and Message models
- ✅ `app/schemas.py` - Added 4 new schemas
- ✅ `app/routers/social.py` - New router with all endpoints
- ✅ `main.py` - Registered social router
- ✅ `create_social_tables.py` - Migration script
- ✅ `SWAGGER_TESTING_GUIDE.md` - Comprehensive testing guide

---

## 🚀 Setup Steps

### 1. Start Backend Server

```powershell
cd mental_health_app_backend
python main.py
```

**That's it!** The server will automatically:

- Create the `encouragements` and `messages` tables if they don't exist
- Start at: `http://localhost:8000`

You'll see output like:

```
✓ JWT_SECRET is set: True
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 2. Access Swagger UI

Open: **http://localhost:8000/docs**

---

## 🧪 Quick Test

### Test Flow (5 minutes)

1. **Login** (POST /auth/login):

   - Username: `johndoe@example.com`
   - Password: `password123`
   - Copy the `access_token`

2. **Authorize** (click 🔓 button):

   - Paste: `Bearer YOUR_TOKEN`

3. **Get Friends** (GET /friends/):

   - Copy a `friendship_id` (the `id` field, not `friend_id`)
   - Copy a `friend_user_id` (the `friend_id` field)

4. **View Friend's Tasks** (GET /users/{user_id}/todos):

   - Use `friend_user_id` from step 3

5. **Send Encouragement** (POST /friends/{friendship_id}/encouragement):

   - Use `friendship_id` from step 3
   - Body: `{"message": "You're doing great! 💪"}`

6. **Login as Friend** (logout and login as `janedoe@example.com`):
   - Get encouragements: GET /encouragements/
   - See your message!

---

## 📚 Full Documentation

- **Comprehensive Guide**: `SWAGGER_TESTING_GUIDE.md`
  - Step-by-step testing for all 9 endpoints
  - Sample request/response data
  - Troubleshooting tips
  - Complete testing scenarios

---

## 🔍 Verify Installation

Check that all endpoints appear in Swagger UI under **"Social Features"** tag:

- ✅ GET /users/{user_id}/todos
- ✅ GET /users/{user_id}/streak
- ✅ GET /users/{user_id}/profile
- ✅ POST /friends/{friendship_id}/encouragement
- ✅ GET /encouragements/
- ✅ GET /encouragements/unread-count
- ✅ PUT /encouragements/{encouragement_id}/read
- ✅ POST /friends/{friendship_id}/messages
- ✅ GET /friends/{friendship_id}/messages

---

## ⚠️ Important Notes

### Friendship IDs vs User IDs

- **User ID** (`user_id`): The actual user's database ID (use for viewing profile/todos/streak)
- **Friendship ID** (`friendship_id`): The ID of the friendship record (use for sending messages/encouragement)

Get both from `GET /friends/`:

```json
[
  {
    "id": 1,  // ← This is friendship_id
    "friend_id": 2,  // ← This is user_id
    "friend_first_name": "Jane",
    ...
  }
]
```

### Authentication

All social endpoints require authentication. Always:

1. Login first
2. Click 🔓 Authorize
3. Paste: `Bearer YOUR_TOKEN`

### Friendship Requirement

You can only view/message users who are your friends:

1. Send friend request: `POST /friends/request`
2. Other user accepts: `PUT /friends/request/{id}/accept`
3. Now you can use social features!

---

## 🐛 Common Issues

### "Friendship not found"

**Fix:** Make sure you're using the correct `friendship_id` from `GET /friends/`, not the `friend_id`.

### "Not authenticated"

**Fix:** Click 🔓 Authorize button and enter `Bearer YOUR_TOKEN`.

### "Table does not exist"

**Fix:** Restart the server with `python main.py` - tables are auto-created on startup.

### "You must be friends to view"

**Fix:** Create friendship first (send + accept friend request).

---

## 📱 Frontend Integration

The Flutter app (`social_screen.dart`) is already configured to use these endpoints!

Just start the backend and the Flutter app will automatically:

- Show real friend tasks and streaks
- Send encouragements
- Send messages
- Display friend's character as profile picture

---

## ✅ Success Checklist

- [ ] Started backend server (tables auto-created!)
- [ ] Accessed Swagger UI
- [ ] Can login and get token
- [ ] Authorized in Swagger
- [ ] Can view friend's tasks
- [ ] Can send encouragement
- [ ] Can send message
- [ ] All endpoints work!

**Ready to test!** 🎉

For detailed testing instructions, see: `SWAGGER_TESTING_GUIDE.md`
