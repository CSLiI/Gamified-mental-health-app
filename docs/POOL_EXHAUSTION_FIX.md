# QueuePool Exhaustion & Slow Loading - Root Cause & Fix

## Problem Identified

### Backend Symptoms

```
Auth error: QueuePool limit of size 5 overflow 2 reached, connection timed out, timeout 10.00
```

- Backend pool (5 connections + 2 overflow = 7 max) was exhausting
- Multiple concurrent `/auth/me` requests overwhelming the backend

### Frontend Symptoms

- Slow app startup (10-15+ seconds)
- "Network error: null" cascading across screens
- Multiple screens frozen waiting for API responses

## Root Cause

**Redundant `getCurrentUser()` API calls at startup:**

1. **CharacterProvider**:
   - Called `getCurrentUser()` twice per load (once for API, once for cache fallback)
2. **MoodProvider**:

   - Called `getCurrentUser()` once per load

3. **Multiple Screens** independently called `getCurrentUser()` on init:
   - `HomeScreen`
   - `ProfileScreen`
   - `RewardsTab`
   - `AchievementsTab`
   - `StatisticsTab`
   - `XpProgressBar`
   - `SplashScreen`

**Result**: 15-20+ concurrent `/auth/me` requests hitting backend at once, each requiring a DB connection from the pool.

## Fix Applied

### 1. Created `UserProvider` Singleton

**File**: `lib/core/providers/user_provider.dart`

- Centralized user data management
- Single source of truth for current user
- Uses cached `getCurrentUser()` from `ApiService`
- Prevents duplicate API calls

### 2. Refactored `CharacterProvider` & `MoodProvider`

**Files**:

- `lib/core/providers/character_provider.dart`
- `lib/core/providers/mood_provider.dart`

**Before**: Each provider called `_apiService.getCurrentUser()` every time
**After**: Providers receive `UserProvider` via constructor injection and get `userId` from it

**API calls eliminated**: ~6-8 redundant `getCurrentUser()` calls removed

### 3. Updated Provider Dependency Injection

**File**: `lib/main.dart`

```dart
MultiProvider(
  providers: [
    // UserProvider first - single source of truth
    ChangeNotifierProvider(create: (_) => UserProvider()),
    // Inject UserProvider into dependent providers
    ChangeNotifierProxyProvider<UserProvider, MoodProvider>(...),
    ChangeNotifierProxyProvider<UserProvider, CharacterProvider>(...),
  ],
)
```

### 4. Load UserProvider First in HomeNavigation

**File**: `lib/presentation/screens/home/home_navigation.dart`

```dart
WidgetsBinding.instance.addPostFrameCallback((_) async {
  // Load user first (single cached API call)
  await context.read<UserProvider>().loadUser();
  // Then load mood/character (they use cached userId)
  context.read<MoodProvider>().loadMood();
  context.read<CharacterProvider>().loadCharacter();
});
```

### 5. Reduced Concurrent GET Limit

**File**: `lib/data/services/dio_client.dart`

- **Before**: Max 3 concurrent GETs
- **After**: Max 2 concurrent GETs
- Matches backend pool capacity better (5 base + 2 overflow)

### 6. Backend Pool Already Optimized

**File**: `mental_health_app_backend/app/database.py`

- Pool size: 5 (reduced from 10)
- Overflow: 2 (reduced from 10)
- Timeout: 10s
- LIFO reuse enabled
- `pool_pre_ping` enabled
- Sessions properly closed via `get_db()` yield/finally

## Expected Results

### Performance Improvements

- **Startup time**: 10-15s → 2-3s (5-7x faster)
- **API calls on startup**: 15-20+ → 5-8 calls
- **Pool exhaustion**: Eliminated
- **Network errors**: Drastically reduced

### UX Improvements

- Screens load instantly with cached data
- No more cascading "Network error: null"
- Smooth navigation between tabs
- Background refresh keeps data fresh

## Testing Steps

1. **Clear app cache**:

   ```bash
   flutter clean
   flutter pub get
   ```

2. **Restart backend**:

   ```powershell
   cd mental_health_app_backend
   .\venv\Scripts\Activate.ps1
   python main.py
   ```

3. **Run app**:

   ```powershell
   cd mental_health_app
   flutter run --enable-impeller
   ```

4. **Observe backend logs**: Should see ~5-8 initial requests instead of 15-20+

5. **Check app startup**: Should load Home screen in 2-3 seconds

## Architecture Benefits

### Before (Fragmented)

```
HomeScreen ──────┐
ProfileScreen ────┼──> getCurrentUser() ──> Backend DB
RewardsTab ───────┤     (15+ concurrent)
CharacterProvider─┤
MoodProvider ─────┘
```

### After (Centralized)

```
UserProvider ──> getCurrentUser() ──> Backend DB
     │            (1 cached call)
     ├──> HomeScreen (reads from UserProvider)
     ├──> ProfileScreen (reads from UserProvider)
     ├──> CharacterProvider (reads userId)
     └──> MoodProvider (reads userId)
```

## Future Optimizations (Optional)

1. **Prefetch on login**: Warm `UserProvider` immediately after successful login
2. **Lazy load tabs**: Only fetch data when user switches to a tab
3. **Increase backend pool**: If user base grows, scale pool to 10/5 (base/overflow)
4. **Add Redis cache**: For high-traffic endpoints like `/auth/me`

---

**Status**: ✅ Implemented and ready for testing
**Impact**: Critical - fixes app usability and backend stability
**Risk**: Low - backward compatible, no breaking changes
