# 🚀 Quick Reference - Copy-Paste Examples

## 1. Add Skeleton Loader to ANY Screen (30 seconds)

### **Step 1: Import**

```dart
import '../../core/widgets/skeleton_loader.dart';
```

### **Step 2: Replace Loading Spinner**

```dart
// OLD ❌
if (_isLoading) {
  return Center(child: CircularProgressIndicator());
}

// NEW ✅
if (_isLoading) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (_, __) => SkeletonLoader.listItem(),
  );
}
```

**That's it! Copy-paste and change `listItem()` to match your screen type.**

---

## 2. All Skeleton Types (Pick One)

```dart
// For friend cards, profile cards, achievement cards
SkeletonLoader.card(height: 120)

// For lists (todos, journals, moods)
SkeletonLoader.listItem()

// For character display
SkeletonLoader.character(size: 200)

// For grid layouts (rewards, characters)
SkeletonLoader.grid(itemCount: 6, crossAxisCount: 2)

// For text only
SkeletonLoader.text(width: 150, height: 14)
```

---

## 3. Add Caching to API Methods (2 minutes)

### **In `api_service.dart`:**

```dart
import '../services/cache_service.dart';

// BEFORE ❌
Future<List<dynamic>> getFriends() async {
  final response = await _dioClient.get('/friends');
  return response.data;
}

// AFTER ✅
Future<List<dynamic>> getFriends() async {
  // Check cache first
  final cached = await CacheService().get<List<dynamic>>(
    CacheKeys.friendsList,
    maxAge: CacheService.shortCache, // 2 minutes
  );
  if (cached != null) return cached;

  // Not cached, fetch from API
  final response = await _dioClient.get('/friends');

  // Save to cache
  await CacheService().set(CacheKeys.friendsList, response.data);
  return response.data;
}
```

### **Cache Durations:**

```dart
CacheService.shortCache   // 2 minutes (for frequently changing data)
CacheService.mediumCache  // 10 minutes (for profile, character)
CacheService.longCache    // 1 hour (for static data like achievements)
```

---

## 4. Add Pagination to Lists (3 minutes)

### **BEFORE (Loads ALL items):**

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemCard(item: items[index]);
  },
)
```

### **AFTER (Loads 20 at a time):**

```dart
import '../../core/widgets/paginated_list.dart';

PaginatedListView<Map<String, dynamic>>(
  fetchData: (skip, limit) async {
    return await _apiService.getMoodLogs(skip: skip, limit: limit);
  },
  itemBuilder: (context, mood, index) {
    return MoodCard(mood: mood);
  },
  emptyWidget: Center(child: Text('No moods yet')),
  skeletonBuilder: () => ListView.builder(
    itemCount: 5,
    itemBuilder: (_, __) => SkeletonLoader.listItem(),
  ),
)
```

---

## 5. Use Cached Images (Instead of Direct Assets)

### **BEFORE:**

```dart
Image.asset('assets/images/Boy_Gif_33FPS/Boy_Happy.gif')
```

### **AFTER:**

```dart
import '../../core/utils/image_cache_manager.dart';

ImageCacheManager().buildCachedImage(
  assetPath: 'assets/images/Boy_Gif_33FPS/Boy_Happy.gif',
  width: 200,
  height: 200,
)
```

**Note:** All character GIFs are auto-preloaded in `main.dart` already!

---

## 6. Clear Cache on Important Actions

### **On Logout:**

```dart
await CacheService().clearAll();
```

### **After Posting New Data:**

```dart
// After posting mood, clear mood cache to force refresh
await CacheService().remove(CacheKeys.recentMoods);
```

### **After Accepting Friend Request:**

```dart
// Clear friends cache to show updated list
await CacheService().remove(CacheKeys.friendsList);
```

---

## 7. Common Screen Patterns

### **Home Screen Loading:**

```dart
if (_isLoading) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SkeletonLoader.character(size: 250),
      SizedBox(height: 20),
      SkeletonLoader.text(width: 200, height: 18),
      SizedBox(height: 10),
      SkeletonLoader.text(width: 150, height: 16),
    ],
  );
}
```

### **Profile Screen Loading:**

```dart
if (_isLoading) {
  return Column(
    children: [
      SkeletonLoader.character(size: 150),
      SizedBox(height: 20),
      SkeletonLoader.card(height: 100),
      SizedBox(height: 16),
      SkeletonLoader.card(height: 80),
    ],
  );
}
```

### **List Screen Loading:**

```dart
if (_isLoading) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (_, __) => Padding(
      padding: EdgeInsets.all(16),
      child: SkeletonLoader.card(height: 120),
    ),
  );
}
```

### **Grid Screen Loading:**

```dart
if (_isLoading) {
  return SkeletonLoader.grid(
    itemCount: 6,
    crossAxisCount: 2,
    childAspectRatio: 0.8,
  );
}
```

---

## 8. Backend Pagination Support

### **Add to Backend Routes (Python):**

```python
@router.get("/moods/")
async def get_moods(
    skip: int = 0,      # ← Add this
    limit: int = 20,    # ← Add this
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    moods = db.query(MoodLog).filter(
        MoodLog.user_id == current_user.id
    ).order_by(
        MoodLog.logged_at.desc()
    ).offset(skip).limit(limit).all()  # ← Use skip and limit

    return moods
```

**Apply to:**

- ✅ GET `/moods/` (mood logs)
- ✅ GET `/todos/` (todos)
- ✅ GET `/journals/` (journals)
- ✅ GET `/notifications/` (notifications)

---

## 9. Testing Your Changes

### **Test Skeleton Loaders:**

1. Add artificial delay to see skeleton:

```dart
await Future.delayed(Duration(seconds: 2)); // Add before loading
```

2. Remove delay after testing

### **Test Caching:**

1. First load → See network request in logs (slow)
2. Second load → See instant load (fast!)
3. Wait cache duration → See network request again

### **Test Pagination:**

1. Scroll to bottom → See loading indicator
2. More items load automatically
3. Pull to refresh → Reload first 20 items

---

## 10. Common Mistakes to Avoid

❌ **Don't do this:**

```dart
SkeletonLoader.card() // Missing required height parameter
```

✅ **Do this:**

```dart
SkeletonLoader.card(height: 120)
```

---

❌ **Don't do this:**

```dart
// Caching without checking cache first
final data = await apiService.getData();
await CacheService().set('key', data);
```

✅ **Do this:**

```dart
// Check cache FIRST, then fetch if needed
final cached = await CacheService().get('key');
if (cached != null) return cached;

final data = await apiService.getData();
await CacheService().set('key', data);
return data;
```

---

❌ **Don't do this:**

```dart
// Using wrong cache duration
await CacheService().get('friends', maxAge: CacheService.longCache);
// Friends change frequently, should use shortCache!
```

✅ **Do this:**

```dart
await CacheService().get('friends', maxAge: CacheService.shortCache);
```

---

## 🎯 5-Minute Implementation Checklist

For each screen, follow this checklist:

1. **[ ]** Import skeleton loader
2. **[ ]** Replace loading spinner with skeleton
3. **[ ]** Pick correct skeleton type (card/list/grid/character)
4. **[ ]** Test with artificial delay
5. **[ ]** Remove delay
6. **[ ]** Done! ✅

**Average time per screen: 2-5 minutes**

---

## 📖 Full Documentation

- **Comprehensive Guide:** `PERFORMANCE_OPTIMIZATION_GUIDE.md`
- **Implementation Summary:** `PERFORMANCE_IMPLEMENTATION_SUMMARY.md`
- **Visual Examples:** `VISUAL_EXAMPLES_BEFORE_AFTER.md`

---

## 🆘 Need Help?

**Common issues:**

**Q: Skeleton loader not showing?**  
A: Check if `_isLoading` is set to `true` initially

**Q: Cache not working?**  
A: Make sure `CacheService().initialize()` is called in `main.dart` (already done!)

**Q: Pagination not loading more?**  
A: Backend must support `skip` and `limit` query parameters

**Q: Character GIFs still slow?**  
A: Preloading happens in `main.dart` (already done!), give it 1-2 seconds on app start

---

**That's it! Copy-paste these patterns to ANY screen in your app.** 🚀
