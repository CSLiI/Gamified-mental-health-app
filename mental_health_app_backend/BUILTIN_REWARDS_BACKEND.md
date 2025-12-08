# Builtin Rewards Backend Implementation

## Overview

Complete backend system for syncing builtin rewards (themes, banners, frames, profile items) across devices. Users' purchases and equipped items are now stored on the server.

---

## Database Changes

### New Tables

#### `builtin_user_rewards`

Tracks which builtin rewards the user has purchased.

- **Columns:**
  - `id` (SERIAL PRIMARY KEY)
  - `user_id` (INTEGER, FK → users.id, ON DELETE CASCADE)
  - `reward_id` (INTEGER, CHECK >= 10000)
  - `category` (VARCHAR(50)) - themes, banners, frames, profile_items
  - `purchased_at` (TIMESTAMP WITH TIME ZONE)
- **Constraints:**
  - UNIQUE(user_id, reward_id) - Can't purchase same item twice
  - CHECK (reward_id >= 10000) - Validates builtin catalog IDs

#### `builtin_equipped_rewards`

Tracks which builtin rewards the user currently has equipped.

- **Columns:**
  - `id` (SERIAL PRIMARY KEY)
  - `user_id` (INTEGER, FK → users.id, ON DELETE CASCADE)
  - `reward_id` (INTEGER, CHECK >= 10000)
  - `category` (VARCHAR(50))
  - `equipped_at` (TIMESTAMP WITH TIME ZONE)
- **Constraints:**
  - UNIQUE(user_id, category) - Only one item equipped per category
  - CHECK (reward_id >= 10000)

### Modified Tables

#### `users`

Added column:

- `builtin_xp_spent` (INTEGER, DEFAULT 0) - Tracks XP spent on builtin rewards

---

## SQL Migration

**File:** `builtin_rewards_migration.sql`

**To Apply in Supabase:**

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the entire contents of `builtin_rewards_migration.sql`
4. Click "Run"
5. Verify with the commented verification queries at the bottom

---

## Backend Files Created/Modified

### 1. **models.py**

Added models:

- `BuiltinUserReward` - Purchase tracking
- `BuiltinEquippedReward` - Equipped items tracking
- Modified `User` model to include `builtin_xp_spent`

### 2. **schemas.py**

Added schemas:

- `BuiltinRewardPurchase` - Purchase request
- `BuiltinRewardEquip` - Equip request
- `BuiltinUserRewardResponse` - Purchase response
- `BuiltinEquippedRewardResponse` - Equipped item response
- `BuiltinRewardsDataResponse` - Complete data response

### 3. **CRUD/builtin_rewards.py** (NEW)

Functions:

- `get_user_purchased_rewards()` - Get all purchased items
- `get_user_equipped_rewards()` - Get all equipped items
- `get_user_xp_spent()` - Get total XP spent
- `purchase_builtin_reward()` - Purchase with XP validation
- `equip_builtin_reward()` - Equip (auto-unequips other items in category)
- `unequip_builtin_reward()` - Unequip specific item
- `sync_builtin_rewards()` - One-time migration helper

### 4. **routers/builtin_rewards_routes.py** (NEW)

Endpoints:

- `GET /builtin-rewards/me/data` - Get all data (purchased + equipped + xp_spent)
- `GET /builtin-rewards/me/purchased` - Get purchased items
- `GET /builtin-rewards/me/equipped` - Get equipped items
- `POST /builtin-rewards/me/purchase` - Purchase reward
- `POST /builtin-rewards/me/equip` - Equip reward
- `DELETE /builtin-rewards/me/unequip/{reward_id}` - Unequip reward
- `POST /builtin-rewards/me/sync` - Sync from frontend storage (migration)

### 5. **main.py**

- Added `builtin_rewards_routes` import
- Added `app.include_router(builtin_rewards_routes.router)`

---

## API Endpoints

### Base URL: `/builtin-rewards`

#### Get All Data

```
GET /builtin-rewards/me/data
Authorization: Bearer {token}

Response:
{
  "purchased": [
    {
      "id": 1,
      "user_id": 31,
      "reward_id": 10000,
      "category": "themes",
      "purchased_at": "2025-12-03T10:30:00Z"
    }
  ],
  "equipped": [
    {
      "id": 1,
      "user_id": 31,
      "reward_id": 10000,
      "category": "themes",
      "equipped_at": "2025-12-03T10:31:00Z"
    }
  ],
  "xp_spent": 100
}
```

#### Purchase Reward

```
POST /builtin-rewards/me/purchase
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "reward_id": 10000,
  "category": "themes",
  "xp_cost": 100
}

Response:
{
  "id": 1,
  "user_id": 31,
  "reward_id": 10000,
  "category": "themes",
  "purchased_at": "2025-12-03T10:30:00Z"
}
```

#### Equip Reward

```
POST /builtin-rewards/me/equip
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "reward_id": 10000,
  "category": "themes"
}

Response:
{
  "id": 1,
  "user_id": 31,
  "reward_id": 10000,
  "category": "themes",
  "equipped_at": "2025-12-03T10:31:00Z"
}
```

#### Unequip Reward

```
DELETE /builtin-rewards/me/unequip/10000
Authorization: Bearer {token}

Response:
{
  "success": true,
  "message": "Reward unequipped"
}
```

#### Sync (One-Time Migration)

```
POST /builtin-rewards/me/sync
Authorization: Bearer {token}
Content-Type: application/json

Body:
{
  "purchased": [
    {"reward_id": 10000, "category": "themes"},
    {"reward_id": 10005, "category": "banners"}
  ],
  "equipped": [
    {"reward_id": 10000, "category": "themes"}
  ],
  "xp_spent": 200
}

Response:
{
  "success": true,
  "message": "Builtin rewards synced successfully"
}
```

---

## Frontend Integration Steps

1. **Run SQL Migration** in Supabase
2. **Restart Backend Server** to load new models
3. **Update Flutter app** to use API endpoints instead of local storage
4. **Migration Flow:**
   - On first launch after update, read local storage
   - Call `/builtin-rewards/me/sync` with local data
   - Delete local storage keys
   - Use API for all future operations

---

## Benefits

✅ **Cross-Device Sync** - Rewards follow user across devices
✅ **Data Integrity** - Server validates ownership before applying themes
✅ **Consistent XP** - XP spent tracked on server
✅ **No Storage Conflicts** - Single source of truth
✅ **Backup** - Data persists even if device is lost

---

## Testing Checklist

1. ✅ Run SQL migration in Supabase
2. ✅ Restart backend server
3. ✅ Test `/builtin-rewards/me/data` endpoint
4. ✅ Test purchase flow
5. ✅ Test equip/unequip flow
6. ✅ Test sync endpoint with frontend data
7. ✅ Verify cross-device sync by logging in on different devices
8. ✅ Verify themes only show when purchased
