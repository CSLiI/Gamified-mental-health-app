# Quest and Todo Fixes

## Overview

This document summarizes the fixes applied to the Quest and Todo features, specifically addressing the issue where the "Add Task" button was not visible on the "My Todos" tab.

## Changes

### 1. Todo List Screen (`lib/presentation/screens/todos/todo_list_screen.dart`)

- **Fixed FAB Visibility**: Added a listener to `_tabController` in `initState` to trigger a rebuild when the tab changes. This ensures the Floating Action Button correctly switches between "AI Generate" (for quests) and "New Task" (for todos).
- **Code Cleanup**: Removed the unused `_getTasksByCategory` function which was causing lint errors.
- **Refactoring**: Ensured `_loadTodos`, `_formatDate`, and `_showAddTaskDialog` are correctly implemented and not duplicated.

### 2. Quest Card (`lib/presentation/widgets/quest_card.dart`)

- **UI Overhaul**: Updated the `QuestCard` design to be more professional and consistent with the app's theme.
- **Visual Improvements**:
  - Added a progress bar with better styling.
  - Improved the header layout with category emojis and difficulty badges.
  - Added a "Time Remaining" indicator.
  - Used `AppColors` for consistent branding.
  - Added shadow and rounded corners for a card-like appearance.

## Verification

- **Todo Tab**: When switching to the "My Todos" tab (index 2), the FAB should now show "New Task" with a plus icon.
- **Quest Tabs**: When on "Daily Quests" or "Weekly Quests", the FAB should show "AI Generate" with a wand icon.
- **Quest Card**: The quest cards should now look more polished and display all relevant information clearly.

## Next Steps

- Verify the changes on a device/emulator.
- Check if the "AI Generate" button works as expected.
- Ensure adding a new task works correctly.
