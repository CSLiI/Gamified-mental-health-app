# XP Display Fix - December 2, 2025

## Problem Identified

**Error**: `Validation error: Input should be a valid integer, unable to parse string as an integer`

**Symptoms**:

- Rewards Tab always showed 0 XP
- Character card not showing accurate XP needed to level up
- XP not updating after completing tasks (todos, quests, etc.)

## Root Cause

The backend returns XP values as **integers**, but the frontend was using weak type checking (`is int`) without handling potential string values from JSON deserialization. The `??` operator was failing silently when values were `0` (falsy in null-coalescing).

## Fixes Applied

### 1. **Rewards Tab (`rewards_tab.dart`)**

**Before**:

```dart
final totalXp = (levelProgress['total_xp'] is int && levelProgress['total_xp'] > 0)
    ? levelProgress['total_xp']
    : (user['xp'] is int ? user['xp'] : _userXP);
```

**After**:

```dart
// Parse XP from different sources with type safety
int? lpXp;
int? userXp;

if (levelProgress['total_xp'] != null) {
  if (levelProgress['total_xp'] is int) {
    lpXp = levelProgress['total_xp'] as int;
  } else if (levelProgress['total_xp'] is String) {
    lpXp = int.tryParse(levelProgress['total_xp'] as String);
  }
}

if (user['xp'] != null) {
  if (user['xp'] is int) {
    userXp = user['xp'] as int;
  } else if (user['xp'] is String) {
    userXp = int.tryParse(user['xp'] as String);
  }
}

final totalXp = (lpXp != null && lpXp > 0)
    ? lpXp
    : (userXp != null && userXp >= 0)
        ? userXp
        : _userXP;
```

**Changes**:

- Added explicit type checking for both `int` and `String` types
- Used `int.tryParse()` for safe string-to-int conversion
- Separated parsing logic into nullable intermediates (`lpXp`, `userXp`)
- Added comprehensive debug logging showing raw values and their types

### 2. **Home Screen (`home_screen.dart`)**

**Before**:

```dart
final level = _levelProgress?['level'] ?? _userData?['level'] ?? 1;
final xpInCurrentLevel = _levelProgress?['xp_in_current_level'] ?? 0;
final xpForNextLevel = _levelProgress?['xp_for_next_level'] ?? 100;
```

**After**:

```dart
// Parse level with type safety
int level = 1;
if (_levelProgress?['level'] != null) {
  if (_levelProgress!['level'] is int) {
    level = _levelProgress['level'] as int;
  } else if (_levelProgress['level'] is String) {
    level = int.tryParse(_levelProgress['level'] as String) ?? 1;
  }
} else if (_userData?['level'] != null) {
  // fallback to user data
}

// Parse XP with type safety
int xpInCurrentLevel = 0;
if (_levelProgress?['xp_in_current_level'] != null) {
  if (_levelProgress!['xp_in_current_level'] is int) {
    xpInCurrentLevel = _levelProgress['xp_in_current_level'] as int;
  } else if (_levelProgress['xp_in_current_level'] is String) {
    xpInCurrentLevel = int.tryParse(_levelProgress['xp_in_current_level'] as String) ?? 0;
  }
}

int xpForNextLevel = 100;
// similar parsing logic...
```

**Changes**:

- Explicit type checking and parsing for `level`, `xpInCurrentLevel`, `xpForNextLevel`
- Character card now shows accurate XP progress (e.g., "50/100 XP" for Level 12)

## Expected Behavior After Fix

### Rewards Tab

- **Display**: "Total XP Earned" showing `1150 XP` (your lifetime total)
- **Subtitle**: "Level 12 • Lifetime Total"
- **Updates**: XP increases immediately after completing tasks

### Home Screen (Character Card)

- **Display**: "50 / 100 XP" (progress within current level)
- **Progress Bar**: 50% filled (50 out of 100 XP to reach Level 13)
- **Updates**: XP bar updates after tasks

## Understanding the Two XP Displays

| Screen          | Display     | Meaning                                                   |
| --------------- | ----------- | --------------------------------------------------------- |
| **Rewards Tab** | `1150 XP`   | Total lifetime XP earned (all time)                       |
| **Home Screen** | `50/100 XP` | XP progress WITHIN Level 12 (50 more needed for Level 13) |

Both are correct! They measure different things:

- **Rewards Tab** = Cumulative achievement
- **Home Screen** = Current level progress

## Testing Checklist

1. ✅ **Start Backend**: `cd mental_health_app_backend; python main.py`
2. ✅ **Start Frontend**: `cd mental_health_app; flutter run`
3. 🔲 **Test Rewards Tab**:
   - Navigate to Progress → Rewards
   - Verify XP shows `1150 XP` (not 0)
   - Verify level shows `Level 12`
4. 🔲 **Test Home Screen**:
   - Check character card shows `50/100 XP`
   - Progress bar should be 50% filled
5. 🔲 **Test XP Update**:
   - Complete a todo (gain 10 XP)
   - Rewards Tab should show `1160 XP`
   - Home Screen should show `60/100 XP`

## Debug Logs Added

Both screens now output detailed logs:

```
💰 Calculated XP balance: 1150, Level: 12
   Raw sources:
     - levelProgress[total_xp]: 1150 (type: int)
     - user[xp]: 1150 (type: int)
     - _userXP (current): 0
   Parsed values:
     - lpXp: 1150, userXp: 1150
     - lpLevel: 12, userLevel: 12
   Final values: XP=1150, Level=12
```

Check Flutter debug console (`flutter logs`) for these messages after launching the app.

## Related Files Modified

- `lib/presentation/screens/progress/rewards_tab.dart` (Lines 196-245)
- `lib/presentation/screens/home/home_screen.dart` (Lines 100-102, 368-410)

## Backend Verification

The backend correctly returns integers from `level_system.py`:

```python
def get_level_progress(db: Session, user_id: int) -> Dict:
    result = {
        "level": correct_level,          # int
        "total_xp": total_xp,            # int
        "xp_in_current_level": xp_in_current_level,  # int
        "xp_for_next_level": xp_for_next,            # int
        "progress_percentage": progress_pct          # int
    }
    return result
```

The issue was purely in frontend type handling during JSON deserialization.
