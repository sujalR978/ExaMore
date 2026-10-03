import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/examDetail.dart';

class SavedExamsScreen extends StatefulWidget {
  const SavedExamsScreen({super.key});

  @override
  State<SavedExamsScreen> createState() => _SavedExamsScreenState();
}

class _SavedExamsScreenState extends State<SavedExamsScreen> {
  final ExamService _examService = ExamService();

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Recent', 'In Progress'];

  void _handleStartExam(ExamModel exam) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)));
  }

  Future<void> _handleBookmarkToggle(ExamModel exam, String userId) async {
    if (userId.isEmpty) return;

    try {
      await _examService.toggleSaveExam(userId: userId, exam: exam);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${exam.title}" from saved exams'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFFBBF24),
            onPressed: () =>
                _examService.toggleSaveExam(userId: userId, exam: exam),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating bookmark: $e')));
    }
  }

  String _formatSavedDate(DateTime? date) {
    if (date == null) return 'Recently saved';
    return 'Saved on ${DateFormat('MMM dd').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Saved Exams',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                ),
              ),
            ),
          ),
        ),
      ),
      // Listen to live Auth changes so userId is never stale or empty
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final currentUser = authSnapshot.data;
          final userId = currentUser?.uid ?? '';

          if (userId.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: subtitleColor),
                    const SizedBox(height: 12),
                    Text(
                      'Please log in to view your saved exams.',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Choice Chips Row
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(_categories[index]),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          selectedColor: const Color(0xFF1E1B4B),
                          backgroundColor: containerColor,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode
                                      ? Colors.white70
                                      : const Color(0xFF1E1B4B)),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.transparent
                                  : borderColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Live Stream of Saved Exams
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _examService.getSavedExamsStream(userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final savedItems = snapshot.data ?? [];

                    // Filter based on chips
                    final filteredItems = savedItems.where((item) {
                      final savedAt = item['savedAt'] as DateTime?;

                      if (_selectedCategoryIndex == 1) {
                        // Recent: within the last 7 days
                        if (savedAt == null) return false;
                        return DateTime.now().difference(savedAt).inDays <= 7;
                      } else if (_selectedCategoryIndex == 2) {
                        // In Progress: user has submissions
                        final exam = item['exam'] as ExamModel;
                        return exam.submissionsCount > 0;
                      }
                      return true;
                    }).toList();

                    if (filteredItems.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.bookmark_border_outlined,
                              size: 48,
                              color: subtitleColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              savedItems.isEmpty
                                  ? 'No saved exams yet.'
                                  : 'No exams found for "${_categories[_selectedCategoryIndex]}"',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bookmark exams from the details page or catalog to access them quickly here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final exam = item['exam'] as ExamModel;
                        final savedAt = item['savedAt'] as DateTime?;

                        return _buildSavedExamCard(
                          badgeText: exam.category.toUpperCase(),
                          title: exam.title,
                          mcqs: '${exam.questions.length} MCQs',
                          time: '${exam.durationMinutes} Mins',
                          savedDate: _formatSavedDate(savedAt),
                          containerColor: containerColor,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          isDarkMode: isDarkMode,
                          onStart: () => _handleStartExam(exam),
                          onBookmark: () => _handleBookmarkToggle(exam, userId),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSavedExamCard({
    required String badgeText,
    required String title,
    required String mcqs,
    required String time,
    required String savedDate,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onStart,
    required VoidCallback onBookmark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF312E81)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.bookmark,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                onPressed: onBookmark,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.list_alt, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(mcqs, style: TextStyle(color: subtitleColor, fontSize: 13)),
              const SizedBox(width: 12),
              Text('•', style: TextStyle(color: subtitleColor, fontSize: 13)),
              const SizedBox(width: 12),
              Icon(Icons.access_time, size: 16, color: subtitleColor),
              const SizedBox(width: 4),
              Text(time, style: TextStyle(color: subtitleColor, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: subtitleColor,
              ),
              const SizedBox(width: 6),
              Text(
                savedDate,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF1E1B4B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Start Exam',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
