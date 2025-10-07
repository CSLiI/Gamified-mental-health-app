# Backend Setup Instructions

## What's Been Added

### New Features Implemented:
1. ✅ **Character System** - Full CRUD with mood-based character states
2. ✅ **Interests System** - User interests management
3. ✅ **Achievement System** - Gamified achievements with automatic checking
4. ✅ **Reward System** - Unlockable rewards with XP costs
5. ✅ **Journal Prompts** - Mood-based writing prompts
6. ✅ **Avatar-Mood Sync** - Character state reflects user's emotional patterns

## Installation Steps

### 1. Update Database Models

Add these new models to your `app/models.py`:

```python
# Add this enum at the top with other enums
class AchievementCategory(str, enum.Enum):
    mood_tracking = "mood_tracking"
    journaling = "journaling"
    consistency = "consistency"
    todos = "todos"
    emotional_growth = "emotional_growth"

# Then add these model classes (from achievements_models artifact)
```

### 2. Update Schemas

Add the new schemas from `schemas_additions` artifact to your `app/schemas.py`

### 3. Install New CRUD Files

Create these new files in `app/CRUD/`:
- `characters.py` (from characters_crud artifact)
- `interests.py` (from interests_crud artifact)
- `achievements.py` (from achievements_crud artifact)
- `rewards.py` (from rewards_crud artifact)
- `journal_prompts.py` (from journal_prompts_crud artifact)

Replace `journals.py` with the fixed version.

### 4. Install New Route Files

Create these new files in `app/routers/`:
- `achievement_routes.py`
- `reward_routes.py`
- `interest_routes.py`
- `journal_prompt_routes.py`

Update `character_routes.py` with the completed version.

### 5. Update main.py

Replace your `main.py` with the updated version that includes all new routers.

### 6. Database Migration

Run this SQL to add new tables:

```sql
-- Create achievement_category enum
CREATE TYPE achievement_category AS ENUM (
    'mood_tracking',
    'journaling',
    'consistency',
    'todos',
    'emotional_growth'
);

-- Achievements table
CREATE TABLE achievements (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    category achievement_category NOT NULL,
    icon_url TEXT,
    xp_reward INTEGER DEFAULT 0,
    requirement_count INTEGER DEFAULT 1,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Achievements table
CREATE TABLE user_achievements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER DEFAULT 0,
    is_claimed BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, achievement_id)
);

-- Rewards table
CREATE TABLE rewards (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    image_url TEXT,
    cost_xp INTEGER DEFAULT 0,
    rarity VARCHAR(20),
    is_limited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Rewards table
CREATE TABLE user_rewards (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reward_id INTEGER NOT NULL REFERENCES rewards(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_equipped BOOLEAN DEFAULT FALSE,
    UNIQUE(user_id, reward_id)
);

-- Journal Prompts table
CREATE TABLE journal_prompts (
    id SERIAL PRIMARY KEY,
    prompt_text TEXT NOT NULL,
    mood mood_enum,
    category VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX idx_user_rewards_user_id ON user_rewards(user_id);
CREATE INDEX idx_journal_prompts_mood ON journal_prompts(mood);
CREATE INDEX idx_journal_prompts_category ON journal_prompts(category);
```

### 7. Seed Initial Data

After starting the server, make these API calls:

```bash
# Seed journal prompts
curl -X POST "http://localhost:8000/journal-prompts/seed"

# Create sample achievements
curl -X POST "http://localhost:8000/achievements/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "First Steps",
    "description": "Log your first mood",
    "category": "mood_tracking",
    "xp_reward": 10,
    "requirement_count": 1
  }'

# Create sample characters
curl -X POST "http://localhost:8000/characters/" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Buddy",
    "description": "A friendly companion on your mental health journey",
    "image_url": "https://example.com/buddy.png"
  }'

# Create sample interests
curl -X POST "http://localhost:8000/interests/bulk" \
  -H "Content-Type: application/json" \
  -d '["Gaming", "Reading", "Music", "Sports", "Art", "Coding", "Meditation"]'
```

## Testing the New Features

### Test Character Mood Sync:
```bash
# 1. Log some moods
# 2. Check character state
curl -X GET "http://localhost:8000/characters/me/mood-state" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Achievements:
```bash
# Check if achievements are awarded automatically
curl -X POST "http://localhost:8000/achievements/me/check" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Rewards:
```bash
# Get available rewards
curl -X GET "http://localhost:8000/rewards/me/available" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Unlock a reward
curl -X POST "http://localhost:8000/rewards/me/unlock/1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## API Documentation

Once running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Troubleshooting

### Import Errors
Make sure all `__init__.py` files exist in:
- `app/CRUD/`
- `app/routers/`
- `app/utils/`

### Database Connection Issues
Check your `.env` file has:
```
DATABASE_URL=your_postgresql_url
JWT_SECRET=your_secret_key
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### Table Already Exists
If migrations fail, either:
1. Drop existing tables and recreate
2. Use Alembic for proper migrations

## Next Steps for Frontend

Your Flutter frontend should now integrate with these new endpoints:

1. **Character Selection Screen** - `/characters/` and `/characters/me/choose/{id}`
2. **Achievement Screen** - `/achievements/me/achievements`
3. **Reward Shop** - `/rewards/me/available` and `/rewards/me/unlock/{id}`
4. **Journal with Prompts** - `/journal-prompts/daily`
5. **Character Mood Visualization** - `/characters/me/mood-state`

## Performance Considerations

For production:
1. Add database indexes (already included in migration)
2. Implement caching for frequently accessed data
3. Add rate limiting to prevent abuse
4. Use connection pooling (already configured)

## Security Notes

Before deploying to production:
1. Change `allow_origins=["*"]` to specific domains
2. Add API rate limiting
3. Implement proper authentication middleware
4. Add input validation for all endpoints
5. Enable HTTPS only