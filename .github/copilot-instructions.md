# Mental Health Gamified App - AI Agent Instructions

> **Academic Project**: This is a Final Year Project (FYP) for Sunway University by CHAN SOON LI, supervised by Ts. Dr Tan Tee Huan. This repository demonstrates full-stack development with gamification mechanics for mental health support.

## Project Overview

This is a **gamified mental health app for students** built as a Final Year Project (FYP). The system consists of:

- **Flutter frontend** (`mental_health_app/`) - Mobile app with character-based gamification
- **FastAPI backend** (`mental_health_app_backend/`) - REST API with PostgreSQL database

The core concept: Users track moods, write journals, complete todos, and maintain streaks. Their chosen character's appearance **dynamically changes based on emotional patterns**, creating a visual feedback loop for mental wellness.

## Architecture

### Backend (FastAPI + SQLAlchemy)

- **Entry point**: `mental_health_app_backend/main.py` - includes all routers
- **Database**: PostgreSQL with SQLAlchemy ORM (`app/database.py`)
- **Models**: `app/models.py` - 15+ tables including User, MoodLog, JournalEntry, Character, Achievement, Reward
- **Auth**: JWT tokens with bcrypt password hashing (`app/auth.py`)
- **Structure**: Modular router pattern
  - Routes: `app/routers/*.py` (10 route modules)
  - CRUD operations: `app/CRUD/*.py` (separated from routes)
  - Schemas: `app/schemas.py` (Pydantic models for validation)

**Key Backend Patterns**:

```python
# All routes use dependency injection for DB and auth
@router.get("/moods/")
async def get_moods(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return CRUD_operation(db, current_user.id)
```

### Frontend (Flutter + Local State)

- **Entry point**: `lib/main.dart` - MaterialApp with GoRouter
- **State management**: StatefulWidget with `setState()` (local state, no global state manager)
- **Navigation**: GoRouter (`lib/core/router/app_router.dart`)
- **API Layer**:
  - `lib/data/services/dio_client.dart` - HTTP client with interceptors for JWT
  - `lib/data/services/api_service.dart` - Typed API methods wrapping DioClient
- **Architecture**: Feature-first structure
  - `lib/presentation/screens/` - Feature screens (auth, home, mood, journal, todos, profile, character)
  - `lib/data/models/` - Data models
  - `lib/core/` - Shared utilities, constants, theme

**Critical Flutter Pattern - API Configuration**:

```dart
// lib/core/constants/api_constants.dart
// Change baseUrl based on testing device:
// Android Emulator: 'http://10.0.2.2:8000'
// iOS Simulator: 'http://localhost:8000'
// Physical Device: 'http://YOUR_MACHINE_IP:8000'
```

## Critical Workflows

### Starting Development

```bash
# Backend (PowerShell)
cd mental_health_app_backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
# Create .env with DATABASE_URL, JWT_SECRET, JWT_ALGORITHM
python seed_data.py  # Seed initial data (characters, interests, achievements, rewards, prompts)
python main.py  # Starts on http://localhost:8000

# Frontend (PowerShell)
cd mental_health_app
flutter pub get
flutter run  # Choose device (emulator/physical)
```

### Testing Backend

- **Swagger UI**: `http://localhost:8000/docs` - Interactive API testing
- **Test script**: `python test_api_endpoints.py` - Automated endpoint validation
- **Health check**: `GET /health` - Verify database connection

### Database Schema Key Points

- All user-specific tables have `user_id` foreign key with `ON DELETE CASCADE`
- Enums match between SQLAlchemy (Python) and PostgreSQL: `MoodEnum`, `GenderEnum`, `AchievementCategory`
- **Character-mood sync logic**: Queries last 7 days of mood logs to calculate character state (thriving/content/struggling/needs_support)
- **Achievement auto-check**: Triggered after mood logs, journal entries, todo completions
- **Schema creation**: Uses `models.Base.metadata.create_all()` - simple approach for development (creates tables if not exist)
- **No migration tool**: For schema changes, drop/recreate tables or manually ALTER in PostgreSQL (acceptable for FYP scope)

## Project-Specific Conventions

### API Response Patterns

- **Login endpoint** uses `application/x-www-form-urlencoded` (OAuth2 spec), others use JSON
- **Authentication**: All protected endpoints require `Authorization: Bearer <token>` header
- **Pagination**: Most list endpoints support `?skip=0&limit=20` query params
- **Error responses**: Return `{"detail": "error message"}` with appropriate HTTP status codes

### Flutter Authentication Flow

1. Login via `api_service.login()` → receives JWT token
2. `DioClient.login()` **automatically saves token** to `flutter_secure_storage` with key `'auth_token'`
3. All subsequent requests via `DioClient` **auto-inject token** in interceptor
4. On 401 response, token is deleted from storage (forces re-login)

**Critical**: Token storage is handled by DioClient, not manually in UI code.

### Gamification Integration Points

**Character State Visualization** (Frontend TODO):

```dart
// After mood log, call this to update character appearance
final state = await apiService.getCharacterMoodState();
// Returns: character_state ("thriving"|"content"|"struggling"|"needs_support")
//          environment ("vibrant"|"peaceful"|"cloudy"|"stormy")
//          mood_score (0-100)
// Use these to render character animation variant
```

**Achievement Checking Pattern**:

```dart
// After any activity (mood log, journal, todo completion)
final result = await apiService.checkAchievements();
// result: { "new_achievements": [...], "xp_earned": 50 }
// Show notification if new achievements unlocked
```

**Reward Shop Flow**:

```dart
// 1. Get affordable rewards (filters by user's current XP)
final rewards = await apiService.getAvailableRewards();
// 2. Unlock with XP
final unlockResult = await apiService.unlockReward(rewardId);
// unlockResult: { "success": true, "new_xp": 150, "reward": {...} }
```

### Common Pitfalls

1. **Android Emulator Network**: Use `10.0.2.2:8000` not `localhost:8000` in `api_constants.dart`
2. **JWT Token Lifecycle**: Token stored in secure storage persists across app restarts; check `isAuthenticated()` on app launch
3. **Database Foreign Keys**: Always delete via CRUD methods (don't bypass ORM) to respect CASCADE rules
4. **Mood Enum Sync**: Backend uses lowercase enums (`happy`, `sad`); keep frontend consistent
5. **Character Selection**: User must choose character via `/characters/me/choose/{id}` before accessing mood state endpoint

## Key Files Reference

- **Backend routing**: `mental_health_app_backend/main.py` (see included routers list)
- **Frontend navigation**: `lib/core/router/app_router.dart` (5 top-level routes)
- **API contracts**: `lib/core/constants/api_constants.dart` (all endpoint paths)
- **Character mood algorithm**: `mental_health_app_backend/app/CRUD/characters.py::get_character_mood_state()`
- **Achievement logic**: `mental_health_app_backend/app/CRUD/achievements.py::check_and_award_achievements()`

## Development Standards

- **Backend**: Follow router → CRUD → model pattern; never put business logic in routes
- **Frontend**: API calls go through `ApiService`, never call `DioClient` directly from UI
- **Asset paths**: All assets in `pubspec.yaml` must exist in `assets/` directory (characters, achievements, rewards subdirectories)
- **Error handling**: Always wrap API calls in try-catch; use `_handleError()` in ApiService for consistent error messages
- **Database queries**: Use SQLAlchemy ORM; avoid raw SQL unless absolutely necessary for performance

## Testing Checklist

When making backend changes:

1. Run `python main.py` and check Swagger docs update
2. Test via Swagger UI or Postman
3. Run `python test_api_endpoints.py`
4. Verify frontend still connects (check DioClient logs in Flutter debug console)

When making frontend changes:

1. Hot reload works for UI changes
2. Hot restart required for state initialization changes
3. Check Flutter DevTools network tab for API call verification
4. Test on both Android and iOS if cross-platform relevant
5. For API changes, verify token is still valid (check DioClient interceptor logs)

## Documentation Resources

- **Backend API**: `http://localhost:8000/docs` (Swagger) or `/redoc` (ReDoc)
- **Backend architecture**: `mental_health_app_backend/README.md` (comprehensive feature list)
- **Setup instructions**: `mental_health_app_backend/instructions.md`
- **Flutter packages**: `pubspec.yaml` (uses Dio, GoRouter, Lottie, FL Chart, flutter_secure_storage)

---

## Academic Context

**Institution**: School of Computing and Artificial Intelligence, Sunway University  
**Project Type**: Final Year Project (FYP) / Capstone Project  
**Student**: CHAN SOON LI (23012743)  
**Supervisor**: Ts. Dr Tan Tee Huan  
**Purpose**: Demonstrate full-stack development skills with gamification mechanics applied to mental health support for students
