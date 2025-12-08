-- SQL script to add new achievements (Alternative to Python script)
-- Run this in your Supabase SQL Editor if you prefer manual SQL

-- Streak Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Two Week Streak', 'Maintain a 14-day streak', 'consistency', 75, 14, '/assets/achievements/fourteen_streak.png'),
('Unstoppable', 'Maintain a 60-day streak', 'consistency', 250, 60, '/assets/achievements/sixty_streak.png'),
('Century Club', 'Maintain a 100-day streak', 'consistency', 500, 100, '/assets/achievements/hundred_streak.png');

-- Todo Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Task Master', 'Complete 50 todos', 'todos', 80, 50, '/assets/achievements/fifty_todos.png'),
('Completion King', 'Complete 100 todos', 'todos', 150, 100, '/assets/achievements/hundred_todos.png'),
('Perfect Day', 'Complete all daily todos in one day', 'todos', 30, 1, '/assets/achievements/perfect_day.png');

-- Social Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('First Challenge', 'Complete your first friend challenge', 'social', 15, 1, '/assets/achievements/first_challenge.png'),
('Team Player', 'Complete 10 friend challenges', 'social', 50, 10, '/assets/achievements/team_player.png'),
('Challenge Champion', 'Complete 50 friend challenges', 'social', 150, 50, '/assets/achievements/challenge_champion.png'),
('Social Butterfly', 'Add 5 friends', 'social', 25, 5, '/assets/achievements/five_friends.png'),
('Squad Goals', 'Add 10 friends', 'social', 50, 10, '/assets/achievements/ten_friends.png'),
('Support Network', 'Add 20 friends', 'social', 100, 20, '/assets/achievements/twenty_friends.png'),
('Motivator', 'Send 10 challenge invites', 'social', 30, 10, '/assets/achievements/motivator.png');

-- Journaling Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Chronicler', 'Write 100 journal entries', 'journaling', 150, 100, '/assets/achievements/hundred_journals.png'),
('Deep Thinker', 'Write a journal entry over 500 words', 'journaling', 25, 1, '/assets/achievements/long_entry.png');

-- Mood Tracking Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Positive Vibes', 'Log 7 positive moods in a row', 'mood_tracking', 40, 7, '/assets/achievements/positive_streak.png'),
('Emotion Expert', 'Log 250 moods', 'mood_tracking', 200, 250, '/assets/achievements/twofifty_moods.png');

-- Special Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Early Bird', 'Log a mood before 8 AM for 7 days', 'special', 35, 7, '/assets/achievements/early_bird.png'),
('Night Owl', 'Log a mood after 10 PM for 7 days', 'special', 35, 7, '/assets/achievements/night_owl.png'),
('Weekend Warrior', 'Complete all weekend todos for 4 weekends', 'special', 60, 4, '/assets/achievements/weekend_warrior.png'),
('Consistency Champion', 'Log at least one activity every day for 14 days', 'special', 100, 14, '/assets/achievements/consistency_champ.png'),
('Wellness Warrior', 'Complete at least 3 different activity types in one day', 'special', 45, 1, '/assets/achievements/wellness_warrior.png');

-- Ultra Achievements
INSERT INTO achievements (name, description, category, xp_reward, requirement_count, icon_url) VALUES
('Mindful Master', 'Log 500 moods', 'mood_tracking', 500, 500, '/assets/achievements/fivehundred_moods.png'),
('Quest Conqueror', 'Complete 500 todos', 'todos', 500, 500, '/assets/achievements/fivehundred_todos.png'),
('Social Star', 'Add 50 friends', 'social', 300, 50, '/assets/achievements/fifty_friends.png');
