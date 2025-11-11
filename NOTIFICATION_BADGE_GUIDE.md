# Adding Unread Count Badge to Notifications Icon

## Overview

This guide shows how to add a notification count badge to the bell icon on the home screen.

## Implementation Steps

### Step 1: Add State Variable in `home_screen.dart`

Add to `_HomeScreenState` class:

```dart
int _unreadCount = 0;
```

### Step 2: Load Unread Count in `_loadData()` Method

Update the `_loadData()` method to fetch unread encouragements:

```dart
Future<void> _loadData() async {
  try {
    final user = await _apiService.getCurrentUser();
    Map<String, dynamic>? characterState;

    try {
      characterState = await _apiService.getCharacterMoodState();
    } catch (e) {
      print('Character state error: $e');
    }

    // NEW: Load unread encouragements count
    int unreadCount = 0;
    try {
      final encouragements = await _apiService.getEncouragements(unreadOnly: true);
      unreadCount = encouragements.length;
    } catch (e) {
      print('Error loading unread count: $e');
    }

    if (mounted) {
      setState(() {
        _userData = user;
        _characterState = characterState;
        _unreadCount = unreadCount;  // NEW
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error loading data: $e');
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

### Step 3: Update Notifications Icon in `_buildHeader()` Method

Replace the existing IconButton with this code:

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.notifications,
          color: Colors.white,
          size: 24,
        ),
      ),
      onPressed: () => context.go('/notifications'),
    ),
    if (_unreadCount > 0)
      Positioned(
        right: 8,
        top: 8,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          constraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
          child: Center(
            child: Text(
              _unreadCount > 99 ? '99+' : _unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
  ],
)
```

### Step 4: Refresh Count After Viewing Notifications

To automatically refresh the count when user returns from notifications screen, you can:

**Option A**: Use `WidgetsBindingObserver` to detect app resume:

```dart
class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData(); // Refresh when app becomes active
    }
  }
}
```

**Option B**: Pass a callback to notifications screen:

```dart
// In app_router.dart
GoRoute(
  path: '/notifications',
  builder: (context, state) {
    final onReturn = state.extra as VoidCallback?;
    return NotificationsScreen(onReturn: onReturn);
  },
),

// In home_screen.dart
onPressed: () {
  context.go('/notifications', extra: () {
    _loadData(); // Refresh when returning
  });
}
```

## Visual Example

Before:

```
🔔  (plain bell icon)
```

After (with 3 unread):

```
🔔  (bell icon with red badge showing "3")
 ³
```

## Design Specifications

### Badge Style

- **Background**: `AppColors.error` (red)
- **Border**: 2px white border
- **Shape**: Circle
- **Min Size**: 20x20 pixels
- **Text Color**: White
- **Text Size**: 10px, bold
- **Position**: Top right corner of bell icon

### Badge Number Display

- **1-99**: Show exact number
- **100+**: Show "99+"

### Badge Visibility

- **Show when**: `_unreadCount > 0`
- **Hide when**: `_unreadCount == 0`

## API Endpoint Used

```http
GET /encouragements/?unread_only=true
```

Returns only unread encouragements. The count is the length of the returned array.

## Testing Checklist

- [ ] Badge appears when there are unread messages
- [ ] Badge shows correct count (1-99)
- [ ] Badge shows "99+" when count exceeds 99
- [ ] Badge disappears when all messages are read
- [ ] Badge updates after marking messages as read
- [ ] Badge doesn't break the icon layout
- [ ] Badge is visible on light and dark backgrounds

## Alternative: Simple Dot Indicator

If you prefer a simpler design without numbers, use this instead:

```dart
if (_unreadCount > 0)
  Positioned(
    right: 10,
    top: 10,
    child: Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.error,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
    ),
  ),
```

This shows a simple red dot instead of a number.

## Performance Considerations

1. **Caching**: Consider caching the unread count to avoid repeated API calls
2. **Debouncing**: If using auto-refresh, debounce the API calls
3. **Loading State**: Don't block UI while loading unread count (load it asynchronously after main data)

## Future Enhancements

1. **Animated Badge**: Add pulse animation when new notification arrives
2. **Sound/Vibration**: Play sound when count increases
3. **Push Notifications**: Real-time updates via Firebase Cloud Messaging
4. **Badge Color**: Different colors for different notification types (green for encouragement, yellow for challenges)

---

**Status**: 📝 Guide Only (Not Implemented)  
**Difficulty**: Easy  
**Estimated Time**: 15 minutes
