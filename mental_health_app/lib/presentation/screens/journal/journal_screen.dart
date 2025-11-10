import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _apiService = ApiService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingJournals = true;
  bool _showNewEntry = false;
  int? _editingJournalId;
  List<dynamic> _journals = [];
  Map<String, dynamic>? _dailyPrompt;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadJournals(),
      _loadDailyPrompt(),
    ]);
  }

  Future<void> _loadJournals() async {
    try {
      final journals = await _apiService.getJournals(limit: 50);
      setState(() {
        _journals = journals;
        _isLoadingJournals = false;
      });
    } catch (e) {
      setState(() => _isLoadingJournals = false);
    }
  }

  Future<void> _loadDailyPrompt() async {
    try {
      final prompt = await _apiService.getDailyPrompt();
      setState(() => _dailyPrompt = prompt);
    } catch (e) {
      print('Error loading prompt: $e');
    }
  }

  Future<void> _saveJournal() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if we're editing an existing journal or creating a new one
      if (_editingJournalId != null) {
        // Update existing journal
        await _apiService.updateJournal(_editingJournalId!, {
          'title': _titleController.text.trim().isEmpty
              ? 'Journal Entry'
              : _titleController.text.trim(),
          'content': _contentController.text.trim(),
        });
      } else {
        // Create new journal
        await _apiService.createJournal({
          'title': _titleController.text.trim().isEmpty
              ? 'Journal Entry'
              : _titleController.text.trim(),
          'content': _contentController.text.trim(),
        });
      }

      if (!mounted) return;

      // Check for achievements silently
      _apiService.checkAchievements();

      // Clear data and reset state
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _showNewEntry = false;
        _editingJournalId = null; // Reset editing ID
      });

      await _loadJournals();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save journal: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF9C27B0),
                    Color(0xFF7B1FA2),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 24, 24),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => context.go('/home'),
                          tooltip: 'Back to Home',
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_stories,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'My Journal',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Express your thoughts freely',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_showNewEntry)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon:
                                const Icon(Icons.add, color: Color(0xFF9C27B0)),
                            onPressed: () {
                              setState(() => _showNewEntry = true);
                            },
                            tooltip: 'New Entry',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _showNewEntry ? _buildNewEntryView() : _buildJournalList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewEntryView() {
    // Add a title that changes based on whether we're editing or creating
    final isEditing = _editingJournalId != null;
    final actionTitle = isEditing ? 'Edit Journal Entry' : 'New Journal Entry';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action title
          if (isEditing)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CACEE).withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF5CACEE),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18, color: Color(0xFF5CACEE)),
                    const SizedBox(width: 8),
                    Text(
                      actionTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5CACEE),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Daily Prompt Card
          if (_dailyPrompt != null && !isEditing)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF5CACEE).withAlpha(100),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF5CACEE),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Prompt',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5CACEE),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dailyPrompt!['prompt_text'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0A4B80),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Title Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Color(0xFF0A4B80), // Darker for better contrast
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A4B80),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Content Input - LARGER TEXT AREA
          Container(
            padding: const EdgeInsets.all(16),
            constraints: const BoxConstraints(
                minHeight: 350), // Increased from 300 to 350
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Write your thoughts here...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: Color(0xFF0A4B80), // Darker for better contrast
                  fontSize: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0A4B80),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _titleController.clear();
                    _contentController.clear();
                    setState(() {
                      _showNewEntry = false;
                      _editingJournalId = null; // Reset editing ID
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5CACEE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF5CACEE),
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Entry' : 'Save Entry',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildJournalList() {
    if (_isLoadingJournals) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ));
    }

    if (_journals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: Colors.white.withAlpha(150),
            ),
            const SizedBox(height: 16),
            const Text(
              'No journal entries yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Color(0x55000000),
                    offset: Offset(1, 1),
                  )
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start writing your thoughts!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2.0,
                    color: Color(0x55000000),
                    offset: Offset(1, 1),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJournals,
      color: const Color(0xFF5CACEE),
      backgroundColor: Colors.white,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _journals.length,
        itemBuilder: (context, index) {
          final journal = _journals[index];
          final title = journal['title'] ?? 'Untitled';
          final content = journal['content'] ?? '';
          final createdAt = DateTime.parse(journal['created_at']);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(220),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  _showJournalDetail(journal);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A4B80),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0A4B80),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          content,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0A4B80),
                            height: 1.4,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showJournalDetail(Map<String, dynamic> journal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF0A4B80), // Darker for better contrast
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header with actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF5CACEE)),
                        onPressed: () {
                          Navigator.pop(context);
                          _editJournal(journal);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteJournal(journal['id']);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journal['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A4B80),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(DateTime.parse(journal['created_at'])),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0A4B80), // Darker for better contrast
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      journal['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Color(0xFF0A4B80),
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editJournal(Map<String, dynamic> journal) {
    _titleController.text = journal['title'] ?? '';
    _contentController.text = journal['content'] ?? '';
    setState(() {
      _showNewEntry = true;
      _editingJournalId = journal['id']; // Set the ID of the journal to edit
    });
  }

  Future<void> _deleteJournal(int journalId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journal'),
        content:
            const Text('Are you sure you want to delete this journal entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.deleteJournal(journalId);
        await _loadJournals();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
