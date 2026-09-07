import 'package:flutter/material.dart';

class ExamAttemptsHistoryScreen extends StatefulWidget {
  const ExamAttemptsHistoryScreen({super.key});

  @override
  State<ExamAttemptsHistoryScreen> createState() =>
      _ExamAttemptsHistoryScreenState();
}

class _ExamAttemptsHistoryScreenState extends State<ExamAttemptsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data model for list grouping
  final List<_ExamGroupData> _allExams = [
    _ExamGroupData(
      examTitle: 'Advanced Calculus Midterm Prep',
      category: 'Mathematics',
      attempts: [
        _AttemptData(
          attemptNumber: 'Attempt 2',
          date: 'Sep 05, 2026',
          score: '42/50',
          percentage: '84%',
          status: 'PASS',
          isPass: true,
        ),
        _AttemptData(
          attemptNumber: 'Attempt 1',
          date: 'Aug 28, 2026',
          score: '30/50',
          percentage: '60%',
          status: 'FAIL',
          isPass: false,
        ),
      ],
    ),
    _ExamGroupData(
      examTitle: 'Organic Chemistry Fundamentals',
      category: 'Science',
      attempts: [
        _AttemptData(
          attemptNumber: 'Attempt 1',
          date: 'Sep 02, 2026',
          score: '45/50',
          percentage: '90%',
          status: 'PASS',
          isPass: true,
        ),
      ],
    ),
    _ExamGroupData(
      examTitle: 'World History: The Cold War Era',
      category: 'History',
      attempts: [
        _AttemptData(
          attemptNumber: 'Attempt 1',
          date: 'Aug 20, 2026',
          score: '22/30',
          percentage: '73%',
          status: 'PASS',
          isPass: true,
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAttemptTap(String examTitle, String attemptNumber) {
    print('Tapped $examTitle - $attemptNumber');
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

    // Filter exams based on search query
    final filteredExams = _allExams.where((exam) {
      final matchesTitle = exam.examTitle.toLowerCase().contains(_searchQuery);
      final matchesCategory = exam.category.toLowerCase().contains(
        _searchQuery,
      );
      return matchesTitle || matchesCategory;
    }).toList();

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

                  title: Text(
                    'Exam Attempts History',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Past Performance',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review your scores and breakdown across all exam attempts.',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Search Bar Widget
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search exam or subject...",
                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: subtitleColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: containerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Conditional view for empty filter results
            if (filteredExams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No exams found matching "$_searchQuery"',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExams.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final exam = filteredExams[index];
                  return _buildExamGroupCard(
                    examTitle: exam.examTitle,
                    category: exam.category,
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                    attempts: exam.attempts,
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExamGroupCard({
    required String examTitle,
    required String category,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required List<_AttemptData> attempts,
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
                  category.toUpperCase(),
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF1D4ED8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${attempts.length} ${attempts.length == 1 ? 'Attempt' : 'Attempts'}',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            examTitle,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // List of individual attempts
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attempts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              return InkWell(
                onTap: () =>
                    _handleAttemptTap(examTitle, attempt.attemptNumber),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                attempt.attemptNumber,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: attempt.isPass
                                      ? (isDarkMode
                                            ? const Color(0xFF064E3B)
                                            : const Color(0xFFD1FAE5))
                                      : (isDarkMode
                                            ? const Color(0xFF451A03)
                                            : const Color(0xFFFEF2F2)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  attempt.status,
                                  style: TextStyle(
                                    color: attempt.isPass
                                        ? (isDarkMode
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFF065F46))
                                        : const Color(0xFFDC2626),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            attempt.date,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                attempt.score,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                attempt.percentage,
                                style: TextStyle(
                                  color: isDarkMode
                                      ? const Color(0xFFFBBF24)
                                      : const Color(0xFFB45309),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            color: subtitleColor,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ExamGroupData {
  final String examTitle;
  final String category;
  final List<_AttemptData> attempts;

  _ExamGroupData({
    required this.examTitle,
    required this.category,
    required this.attempts,
  });
}

class _AttemptData {
  final String attemptNumber;
  final String date;
  final String score;
  final String percentage;
  final String status;
  final bool isPass;

  _AttemptData({
    required this.attemptNumber,
    required this.date,
    required this.score,
    required this.percentage,
    required this.status,
    required this.isPass,
  });
}
