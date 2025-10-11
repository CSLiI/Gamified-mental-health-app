// lib/presentation/screens/journal/journal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Write'),
            Tab(text: 'Entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _WriteTab(),
          _EntriesTab(),
        ],
      ),
    );
  }
}

// WRITE TAB - For creating new journal entries
class _WriteTab extends StatefulWidget {
  const _WriteTab();

  @override
  State<_WriteTab> createState() => _WriteTabState();
}

class _WriteTabState extends State<_WriteTab> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedPrompt;
  bool _isSubmitting = false;

  final List<String> _prompts = [
    "What made you smile today?",
    "What are you grateful for right now?",
    "What's on your mind?",
    "Describe your day in three words",
    "What challenge did you overcome today?",
    "What would make tomorrow better?",
    "How are you really feeling?",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something first'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // TODO: Save to API
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isSubmitting = false);

    if (mounted) {
      _titleController.clear();
      _contentController.clear();
      setState(() => _selectedPrompt = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry saved! 📝'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _formatDate(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Prompt Selector
            Text(
              'Need inspiration? Pick a prompt',
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _prompts.length,
                itemBuilder: (context, index) {
                  final prompt = _prompts[index];
                  final isSelected = _selectedPrompt == prompt;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPrompt = prompt);
                      _contentController.text = '$prompt\n\n';
                    },
                    child: Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: isSelected 
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prompt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected 
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (index * 50).ms).slideX();
                },
              ),
            ),

            const SizedBox(height: 24),

            // Title Field (Optional)
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Give your entry a title',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ).animate().slideX(delay: 200.ms),

            const SizedBox(height: 16),

            // Content Field
            TextField(
              controller: _contentController,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: 'Your thoughts',
                hintText: 'Start writing...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ).animate().slideX(delay: 300.ms),

            const SizedBox(height: 24),

            // Character Count
            Text(
              '${_contentController.text.length} characters',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _saveEntry,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Entry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  String _formatDate() {
    final now = DateTime.now();
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// ENTRIES TAB - List of past journal entries
class _EntriesTab extends StatelessWidget {
  const _EntriesTab();

  // Mock data - Replace with API call
  final List<JournalEntry> _entries = const [
    JournalEntry(
      id: '1',
      title: 'Great Day at Work',
      content: 'Today was amazing! I completed my project and got praised by my manager...',
      date: '2025-10-10',
      mood: 'happy',
    ),
    JournalEntry(
      id: '2',
      title: 'Feeling Anxious',
      content: 'Had a rough day with lots of deadlines. Need to practice breathing exercises...',
      date: '2025-10-09',
      mood: 'anxious',
    ),
    JournalEntry(
      id: '3',
      title: 'Peaceful Evening',
      content: 'Spent time meditating and reading. Felt so calm and centered...',
      date: '2025-10-08',
      mood: 'calm',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 80,
                    color: AppColors.textTertiary,
                  ).animate().scale(),
                  const SizedBox(height: 16),
                  const Text(
                    'No journal entries yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start writing to see your entries here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                return _JournalEntryCard(entry: _entries[index])
                    .animate(delay: (index * 100).ms)
                    .slideX()
                    .fadeIn();
              },
            ),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;

  const _JournalEntryCard({required this.entry});

  Color _getMoodColor() {
    switch (entry.mood) {
      case 'happy':
        return AppColors.moodHappy;
      case 'sad':
        return AppColors.moodSad;
      case 'anxious':
        return AppColors.moodAnxious;
      case 'calm':
        return AppColors.moodCalm;
      default:
        return AppColors.primary;
    }
  }

  IconData _getMoodIcon() {
    switch (entry.mood) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'anxious':
        return Icons.psychology;
      case 'calm':
        return Icons.spa;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Navigate to detail screen
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getMoodColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getMoodIcon(),
                        color: _getMoodColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (entry.title.isNotEmpty)
                            Text(
                              entry.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            entry.date,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // TODO: Show options (edit, delete)
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Content Preview
                Text(
                  entry.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Read More
                Text(
                  'Read more →',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getMoodColor(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Data Model
class JournalEntry {
  final String id;
  final String title;
  final String content;
  final String date;
  final String mood;

  const JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.mood,
  });
}