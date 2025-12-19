# Cache Keys Reference Guide

## Quick Cache Key Lookup

Use this guide when you need to clear specific cache or debug caching issues.

---

## 📋 Cache Keys by Screen

### Home & Profile

```dart
'home_data'           // HomeScreen - user + character state (2 min)
'profile_data'        // ProfileScreen - user + achievements + mood state (2 min)
```

### Mood Tracking

```dart
'mood_history'        // MoodScreen - last 20 mood logs (2 min)
'mood_stats'          // MoodScreen - 7-day statistics (2 min)
```

### Social Features

```dart
'social_data'                    // SocialScreen - friends + requests (2 min)
'friend_profile_{friendId}'      // FriendProfileScreen - per-friend data (2 min)
'notifications_data'             // NotificationsScreen - encouragements + messages (2 min)
```

### Journal

```dart
'journals_data'       // JournalScreen - last 50 entries (2 min)
'daily_prompt'        // JournalScreen - today's writing prompt (10 min)
```

### Todos

```dart
'todos_daily'         // TodoListScreen - daily tasks (2 min)
'todos_weekly'        // WeeklyGoalsScreen - weekly goals (2 min)
'todos_monthly'       // MonthlyGoalsScreen - monthly goals (2 min)
'todos_yearly'        // YearlyGoalsScreen - yearly goals (2 min)
```

### Progress Screen

```dart
'achievements_data'   // AchievementsTab - user + all + user_achievements (10 min)
'rewards_data'        // RewardsTab - xp + all + user_rewards + equipped (10 min)
'statistics_data'     // StatisticsTab - mood distribution + activity stats (10 min)
```

---

## 🗂️ Cache Structure

### Simple Data Cache

```dart
CacheService().set('cache_key', data);
// Stores: { cache_key: data, cache_key_timestamp: timestamp }
```

### Complex Data Cache

```dart
CacheService().set('cache_key', {
  'field1': data1,
  'field2': data2,
});
// Stores nested JSON structure
```

---

## 🔧 Common Cache Operations

### Clear Specific Cache

```dart
// Clear home screen cache
await CacheService().remove('home_data');

// Clear all mood-related cache
await CacheService().remove('mood_history');
await CacheService().remove('mood_stats');

// Clear all todo cache
await CacheService().remove('todos_daily');
await CacheService().remove('todos_weekly');
await CacheService().remove('todos_monthly');
await CacheService().remove('todos_yearly');

// Clear friend profile cache
await CacheService().remove('friend_profile_${friendId}');
```

### Clear All Cache

```dart
// On logout (already handled in DioClient)
await CacheService().clearAll();
```

### Clear Expired Cache

```dart
// Remove entries older than 10 minutes
await CacheService().clearExpired(maxAge: Duration(minutes: 10));
```

---

## 🎯 When to Clear Cache

### User Actions that Should Clear Cache

#### Mood Logging

```dart
// After creating mood log
await _apiService.createMoodLog(data);
await CacheService().remove('mood_history');
await CacheService().remove('mood_stats');
await CacheService().remove('home_data'); // Character state changes
```

#### Todo Operations

```dart
// After creating/completing/deleting todo
await _apiService.createTodo(data);
await CacheService().remove('todos_daily');
await CacheService().remove('home_data'); // XP/streak changes
```

#### Journal Entry

```dart
// After creating journal
await _apiService.createJournal(data);
await CacheService().remove('journals_data');
await CacheService().remove('home_data'); // XP changes
```

#### Achievement Unlocked

```dart
// After unlocking achievement
await CacheService().remove('achievements_data');
await CacheService().remove('profile_data'); // Profile XP changes
```

#### Reward Purchase

```dart
// After buying reward
await _apiService.unlockReward(rewardId);
await CacheService().remove('rewards_data');
await CacheService().remove('profile_data'); // XP deducted
```

#### Social Actions

```dart
// After sending/accepting friend request
await _apiService.acceptFriendRequest(requestId);
await CacheService().remove('social_data');

// After sending message/encouragement
await _apiService.sendMessage(friendId, message);
await CacheService().remove('friend_profile_${friendId}');
await CacheService().remove('notifications_data');
```

---

## 🐛 Debug Cache Issues

### Check if Cache Exists

```dart
final cached = await CacheService().get('cache_key');
if (cached != null) {
  print('✅ Cache hit!');
  print('Data: $cached');
} else {
  print('❌ Cache miss - will fetch from API');
}
```

### Measure Cache Performance

```dart
final stopwatch = Stopwatch()..start();
final data = await CacheService().get('cache_key');
stopwatch.stop();
print('Cache read time: ${stopwatch.elapsedMilliseconds}ms');
// Should be <5ms for memory cache, <20ms for disk cache
```

### Force Cache Refresh

```dart
// Bypass cache and fetch fresh data
await CacheService().remove('cache_key');
await _loadData(); // Will fetch from API and update cache
```

---

## 📊 Cache Expiration Times

| Duration                     | Use Case                                    | Cache Keys                                                                                                                     |
| ---------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| **2 minutes** (shortCache)   | User-generated data that changes frequently | `home_data`, `mood_history`, `mood_stats`, `social_data`, `friend_profile_*`, `notifications_data`, `journals_data`, `todos_*` |
| **10 minutes** (mediumCache) | Semi-static data that updates occasionally  | `achievements_data`, `rewards_data`, `statistics_data`, `daily_prompt`, `profile_data`                                         |
| **1 hour** (longCache)       | Static data that rarely changes             | Not currently used (future: character list, prompts list)                                                                      |

---

## 💡 Pro Tips

### 1. Cache Invalidation Pattern

```dart
// Good: Clear specific cache after mutation
await _apiService.updateData(data);
await CacheService().remove('specific_cache_key');
await _loadData(); // Refresh with new data

// Bad: Clear all cache (loses performance benefit)
await _apiService.updateData(data);
await CacheService().clearAll(); // Don't do this!
```

### 2. Conditional Cache Clearing

```dart
// Only clear if mutation succeeded
try {
  await _apiService.createMoodLog(data);
  await CacheService().remove('mood_history');
  await CacheService().remove('mood_stats');
} catch (e) {
  // Keep cache if API fails
  print('Error: $e');
}
```

### 3. Batch Cache Operations

```dart
// Clear multiple related caches at once
Future<void> clearMoodCache() async {
  await Future.wait([
    CacheService().remove('mood_history'),
    CacheService().remove('mood_stats'),
    CacheService().remove('home_data'),
  ]);
}
```

### 4. Cache Preloading

```dart
// Preload cache in background for faster next load
if (mounted && !_isVisible) {
  _loadData(silent: true); // Update cache without UI changes
}
```

---

## 🚨 Common Issues & Solutions

### Issue: Cache Not Working

**Symptoms**: Data still loads slowly on repeat visits  
**Solution**:

```dart
// 1. Check if CacheService is initialized
await CacheService().initialize(); // Called in main.dart

// 2. Verify cache is being set
await CacheService().set('cache_key', data);
print('Cache set for: cache_key');

// 3. Verify cache is being checked
final cached = await CacheService().get('cache_key');
print('Cache found: ${cached != null}');
```

### Issue: Stale Data Displayed

**Symptoms**: Old data shows even after updates  
**Solution**:

```dart
// Clear cache after mutations
await _apiService.updateData(data);
await CacheService().remove('cache_key');
await _loadData();
```

### Issue: Cache Too Large

**Symptoms**: App slows down over time  
**Solution**:

```dart
// Periodic cache cleanup
await CacheService().clearExpired(maxAge: Duration(minutes: 10));
```

---

## 📝 Quick Copy-Paste Snippets

### Standard Cache-First Load

```dart
Future<void> _loadData() async {
  try {
    // Check cache
    final cached = await CacheService().get<DataType>(
      'my_cache_key',
      maxAge: CacheService.shortCache,
    );

    if (cached != null && mounted) {
      setState(() {
        _data = cached;
        _isLoading = false;
      });
    }

    // Fetch fresh
    final fresh = await _apiService.getData();
    await CacheService().set('my_cache_key', fresh);

    if (mounted) {
      setState(() {
        _data = fresh;
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error: $e');
    if (mounted) setState(() => _isLoading = false);
  }
}
```

### Clear Cache After Mutation

```dart
Future<void> _createData() async {
  try {
    await _apiService.createData(newData);
    await CacheService().remove('data_cache_key');
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success!')),
      );
    }
  } catch (e) {
    // Error handling
  }
}
```

---

**Last Updated**: November 24, 2025  
**Total Cache Keys**: 14+ unique keys  
**Screens Cached**: 11+ screens with intelligent caching
