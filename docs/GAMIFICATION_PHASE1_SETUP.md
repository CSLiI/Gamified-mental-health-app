# 🎮 Gamification System - Phase 1 Implementation Guide

## ✅ What's Been Implemented

### Backend ✅

1. **Daily Check-in System**

   - Streak tracking (current & longest)
   - Progressive rewards (base 10 XP + streak bonus)
   - Milestone bonuses (7 days = 100 XP, 30 days = 500 XP)
   - Calendar showing past 7 days
   - Streak freeze system (protect streak when missed)

2. **API Endpoints**
   - `GET /daily/status` - Check if can claim today
   - `POST /daily/claim` - Claim daily reward
   - `GET /daily/calendar` - Get 7-day check-in calendar
   - `GET /daily/streak-freeze` - Check freeze availability
   - `POST /daily/streak-freeze/use` - Use streak protection

### Frontend ✅

1. **DailyCheckInDialog Widget**

   - Beautiful animated dialog
   - 7-day calendar with check marks
   - Streak display (current & best)
   - Claim button with success animation
   - XP reward breakdown

2. **XPProgressBar Widget**
   - Full version (shows level, XP, progress bar)
   - Compact version (mini bar for app bar)
   - Auto-calculates XP needed for next level
   - Gradient progress bar with glow effect

---

## 🚀 Setup Instructions

### Step 1: Run Database Migration

```powershell
# Connect to your Supabase/PostgreSQL database
# Run this SQL migration:
```

```sql
-- Add daily check-in and streak tracking columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_daily_claim TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_daily_claims INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_freeze_available BOOLEAN DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_freeze_used_this_week BOOLEAN DEFAULT FALSE;

-- Update existing users
UPDATE users SET
    current_streak = 0,
    longest_streak = 0,
    total_daily_claims = 0,
    streak_freeze_available = FALSE,
    streak_freeze_used_this_week = FALSE
WHERE current_streak IS NULL;
```

**Or use the migration file:**

```powershell
cd mental_health_app_backend
# Copy SQL from migrations/add_daily_rewards.sql and run in your database
```

### Step 2: Restart Backend

```powershell
cd mental_health_app_backend
py main.py
```

Check Swagger docs: http://localhost:8000/docs

- Look for `/daily` endpoints
- Test `/daily/status` endpoint

### Step 3: Add `intl` Package to Flutter

```powershell
cd mental_health_app
flutter pub add intl
```

### Step 4: Test Daily Check-in Dialog

Add to your home screen or anywhere you want the check-in button:

```dart
import '../widgets/daily_checkin_dialog.dart';

// In your build method, add a button:
FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => const DailyCheckInDialog(),
    );
  },
  child: const Icon(Icons.card_giftcard),
),
```

### Step 5: Add XP Bar to Screens

**Full version (for profile or progress screen):**

```dart
import '../widgets/xp_progress_bar.dart';

// In your screen:
Column(
  children: [
    const XPProgressBar(),  // Full version
    // ... rest of your content
  ],
)
```

**Compact version (for app bar):**

```dart
AppBar(
  title: const Text('Home'),
  actions: [
    const Padding(
      padding: EdgeInsets.only(right: 8),
      child: XPProgressBar(compact: true),  // Compact version
    ),
  ],
),
```

---

## 🎨 Where to Add Daily Check-in

### Option 1: Home Screen Badge (Recommended)

Add a daily check-in card on home screen:

```dart
// In home_screen.dart
InkWell(
  onTap: () {
    showDialog(
      context: context,
      builder: (context) => const DailyCheckInDialog(),
    );
  },
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const Icon(Icons.card_giftcard, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Reward',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Tap to claim!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
)
```

### Option 2: Auto-show on App Launch

Show dialog automatically once per day:

```dart
// In your main screen's initState:
@override
void initState() {
  super.initState();
  _checkDailyReward();
}

Future<void> _checkDailyReward() async {
  try {
    final status = await ApiService().getDailyStatus();
    if (status['can_claim'] == true) {
      // Wait 1 second then show dialog
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const DailyCheckInDialog(),
          );
        }
      });
    }
  } catch (e) {
    // Silent fail
  }
}
```

### Option 3: Notification Badge

Add red dot indicator when reward is available:

```dart
Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.card_giftcard),
      onPressed: () => showDialog(...),
    ),
    if (_canClaimDaily)  // Check via API
      Positioned(
        right: 8,
        top: 8,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
  ],
)
```

---

## 🎮 How the System Works

### Daily Reward Calculation

```
Base XP: 10 XP

Streak Bonus:
- Day 1: 0 bonus
- Day 2: 5 XP bonus
- Day 3: 10 XP bonus
- Day 7: 30 XP bonus (max)

Milestone Bonuses:
- 7-day streak: +100 XP
- 14-day streak: +50 XP
- 21-day streak: +50 XP
- 30-day streak: +500 XP

Example:
- Day 1: 10 XP
- Day 7: 10 + 30 (streak) + 100 (milestone) = 140 XP
- Day 30: 10 + 50 (max streak) + 500 (milestone) = 560 XP
```

### Streak Protection

Users can earn "streak freeze" by:

- Completing achievements
- Reaching milestones
- Admin grants

Use case: User misses a day but has freeze available → streak protected!

---

## 📸 Expected UI

### Daily Check-in Dialog

```
┌─────────────────────────────────┐
│  🎁 Daily Check-In             │  ← Gradient header
│  Claim your daily reward!       │
├─────────────────────────────────┤
│                                 │
│  🔥     Current Streak     🏆   │
│  7      Current: 7 Days    12   │  ← Streak display
│  Days   Best: 12 Days   Days    │
│                                 │
│         This Week                │
│  M  T  W  T  F  S  S            │  ← 7-day calendar
│  ✓  ✓  ✓  ✓  ✓  ✓  [26]        │  ← Green checks + today
│                                 │
│     [🎁 Claim Reward]           │  ← Big green button
│          Close                   │
└─────────────────────────────────┘
```

### Success Dialog (After Claim)

```
┌─────────────────────────────────┐
│         🎉                       │  ← Animated check
│                                 │
│  🎉 Daily Reward Claimed!       │
│                                 │
│  ┌───────────────────────┐     │
│  │   ⭐ +40 XP           │     │  ← XP earned
│  │   🎊 7-Day Streak!    │     │  ← Milestone
│  └───────────────────────┘     │
│                                 │
│  🔥 7 Days    💰 540 XP        │  ← Stats
│  Streak       Total XP          │
│                                 │
│     [   Awesome!   ]            │
└─────────────────────────────────┘
```

### XP Progress Bar (Full)

```
┌──────────────────────────────────┐
│  [5]  Level            Total XP  │
│       Level 5        ⭐ 450 XP   │
│                                  │
│  Progress to Level 6             │
│  ░░░░░░░░█████░░░░░░  50/100 XP │  ← Gradient bar
│  50% complete                    │
└──────────────────────────────────┘
```

### XP Progress Bar (Compact)

```
┌─────────────┐
│ [5] ████░░  │  ← Mini bar for app bar
│     450 XP  │
└─────────────┘
```

---

## 🧪 Testing Checklist

- [ ] Backend running on http://localhost:8000
- [ ] Database migration applied successfully
- [ ] `/daily/status` returns user status
- [ ] Daily check-in dialog opens
- [ ] Calendar shows last 7 days
- [ ] Claim button works (awards XP)
- [ ] Success dialog animates
- [ ] Can't claim twice same day
- [ ] Streak increments on consecutive days
- [ ] XP bar shows correct level & progress
- [ ] Compact XP bar fits in app bar

---

## 🐛 Troubleshooting

### Issue: "Column does not exist"

**Fix:** Run the migration SQL again, ensure connected to correct database

### Issue: Dialog doesn't show

**Fix:** Check imports, ensure `intl` package installed: `flutter pub get`

### Issue: API returns 404

**Fix:** Restart backend, check `main.py` includes `daily_routes.router`

### Issue: XP bar shows 0

**Fix:** Ensure user has XP in database, check API response in DevTools

---

## 🎯 Next Steps

Once daily check-in is working, we'll add:

1. **Level-up Celebrations** - Full-screen animation when leveling up
2. **Quest System** - Daily/weekly quests with progress bars
3. **Pet Companions** - Icon-based pets that follow you
4. **Mystery Boxes** - Random rewards with shake animation
5. **Comeback Rewards** - Bonuses for returning users

Want me to implement the next feature? Just say "add level-up celebrations" or "add quest system"! 🚀

---

## 📝 Files Created/Modified

### Backend

- ✅ `app/CRUD/daily_rewards.py` - Daily check-in logic
- ✅ `app/routers/daily_routes.py` - API endpoints
- ✅ `app/models.py` - Added streak columns
- ✅ `main.py` - Registered daily router
- ✅ `migrations/add_daily_rewards.sql` - Database migration

### Frontend

- ✅ `lib/presentation/widgets/daily_checkin_dialog.dart` - Check-in UI
- ✅ `lib/presentation/widgets/xp_progress_bar.dart` - XP display
- ✅ `lib/core/constants/api_constants.dart` - Added daily endpoints
- ✅ `lib/data/services/api_service.dart` - Added daily methods

---

## 🌟 For Pet System

Since you asked about pets, here's where to get free animated pets:

### Option 1: LottieFiles (Recommended)

1. Visit https://lottiefiles.com
2. Search "cute pet", "dragon", "cat", "dog", "fox"
3. Download as `.json` file
4. Place in `assets/animations/pets/`
5. Use with `lottie` package:

```dart
Lottie.asset('assets/animations/pets/dragon.json', height: 80)
```

### Option 2: Icon-Based Pets (Quick & Easy)

We can create cute pets using emoji + styling:

```dart
Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
    color: Colors.purple.withValues(alpha: 0.2),
    shape: BoxShape.circle,
  ),
  child: const Text('🐉', style: TextStyle(fontSize: 40)),  // Dragon pet
)
```

Available emoji pets: 🐉🦊🐱🐶🐼🦋🐝🐸🦄🐣

Let me know if you want me to implement the icon-based pet system right now! 🐾
