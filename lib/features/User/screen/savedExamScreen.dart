import 'package:flutter/material.dart';

class SavedExamsScreen extends StatefulWidget {
  const SavedExamsScreen({super.key});

  @override
  State<SavedExamsScreen> createState() => _SavedExamsScreenState();
}

class _SavedExamsScreenState extends State<SavedExamsScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Recent', 'In Progress'];

  void _handleStartExam(String title) {
    print('Start Exam clicked for: $title');
  }

  void _handleBookmarkToggle(String title) {
    print('Bookmark toggled for: $title');
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
      // Capsule-shaped Top Bar
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
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search, color: textColor),
                      onPressed: () {
                        print('Search clicked');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                          color: isSelected ? Colors.transparent : borderColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Saved Exam Card 1: Calculus II Midterm Prep
            _buildSavedExamCard(
              badgeText: 'MATHEMATICS',
              title: 'Calculus II Midterm Prep',
              mcqs: '45 MCQs',
              time: '90 Mins',
              savedDate: 'Saved on Oct 12',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              onStart: () => _handleStartExam('Calculus II Midterm Prep'),
              onBookmark: () =>
                  _handleBookmarkToggle('Calculus II Midterm Prep'),
            ),
            const SizedBox(height: 16),

            // Saved Exam Card 2: European History 101
            _buildSavedExamCard(
              badgeText: 'HISTORY',
              title: 'European History 101',
              mcqs: '30 MCQs',
              time: '60 Mins',
              savedDate: 'Saved on Oct 10',
              containerColor: containerColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              borderColor: borderColor,
              isDarkMode: isDarkMode,
              onStart: () => _handleStartExam('European History 101'),
              onBookmark: () => _handleBookmarkToggle('European History 101'),
            ),
            const SizedBox(height: 30),
          ],
        ),
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
                backgroundColor: const Color(
                  0xFFFBBF24,
                ), // Amber CTA button style
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
