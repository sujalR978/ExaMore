import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/allExamScreen.dart';
import 'package:prep_mate/features/User/screen/examDetail.dart';
import 'package:prep_mate/features/User/screen/settingScreen.dart';
import 'package:prep_mate/features/User/widget/showExams.dart';


class Showexam extends StatefulWidget {
  const Showexam({super.key});

  @override
  State<Showexam> createState() => _ShowexamState();
}

class _ShowexamState extends State<Showexam> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All Subjects',
    'Science',
    'Mathematics',
    'History',
    'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleViewAll() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AllExamsScreen()),
    );
  }

  void _handleStartExam(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExamdetailPage(exam: exam),
      ),
    );
  }

  Future<void> _handleBookmarkToggle(ExamModel exam) async {
    final userId = _currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save exams.')),
      );
      return;
    }

    try {
      await _examService.toggleSaveExam(userId: userId, exam: exam);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update bookmark: $e')),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science_outlined;
      case 'mathematics':
      case 'math':
      case 'calculus':
        return Icons.calculate_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      case 'computer science':
        return Icons.computer_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final selectedCategory = _selectedCategoryIndex == 0
        ? null
        : _categories[_selectedCategoryIndex];

    final userId = _currentUser?.uid ?? '';

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
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        _currentUser?.photoURL ??
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                      ),
                    ),
                  ),
                  title: Text(
                    'Examora',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: textColor),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Settingscreen(),
                          ),
                        );
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
            const SizedBox(height: 8),
            Text(
              'Explore Exams',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find practice tests and assessments across all subjects.',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Search Bar with Clear Icon
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for 'Calculus' or 'Biology'...",
                      hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: subtitleColor),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: subtitleColor, size: 18),
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
                ),
                const SizedBox(width: 12),
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.tune, color: textColor, size: 20),
                    onPressed: () {
                      // Reset category chips
                      setState(() => _selectedCategoryIndex = 0);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Category Filter Chips
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

            // Section Header: Recommended for You
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended for You',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _handleViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stream of Published Exams combined with user saved bookmarks
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _examService.getSavedExamsStream(userId),
              builder: (context, savedSnapshot) {
                final savedIds = (savedSnapshot.data ?? [])
                    .map((item) => (item['exam'] as ExamModel).id)
                    .toSet();

                return StreamBuilder<List<ExamModel>>(
                  stream: _examService.getPublishedExamsStream(
                    category: selectedCategory,
                  ),
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
                            'Error loading exams: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final allExams = snapshot.data ?? [];

                    final filteredExams = allExams.where((exam) {
                      return exam.title.toLowerCase().contains(_searchQuery) ||
                          exam.category.toLowerCase().contains(_searchQuery) ||
                          exam.examCode.toLowerCase().contains(_searchQuery);
                    }).toList();

                    if (filteredExams.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No exams found matching "$_searchQuery"'
                                : 'No published assessments available under this category.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: subtitleColor, fontSize: 14),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredExams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final exam = filteredExams[index];
                        final isBookmarked = savedIds.contains(exam.id);

                        final isMath = exam.category
                            .toLowerCase()
                            .contains('math') ||
                            exam.category.toLowerCase().contains('calc');

                        final badgeBg = isMath
                            ? (isDarkMode
                                ? const Color(0xFF312E81)
                                : const Color(0xFFDBEAFE))
                            : (isDarkMode
                                ? const Color(0xFF2E2A72)
                                : const Color(0xFFDBEAFE));

                        final badgeText = isMath
                            ? (isDarkMode
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8))
                            : (isDarkMode
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8));

                        return ExamCardWidget(
                          badgeText: exam.category.toUpperCase(),
                          badgeColor: badgeBg,
                          badgeTextColor: badgeText,
                          title: exam.title,
                          description:
                              'Comprehensive test with ${exam.questions.length} questions. Total marks: ${exam.totalMarks.toInt()} pts. Passing requirement: ${exam.passingScorePercentage.toInt()}%.',
                          time: '${exam.durationMinutes} mins',
                          mcqs: '${exam.questions.length} MCQs',
                          icon: _getCategoryIcon(exam.category),
                          isBookmarked: isBookmarked,
                          buttonText: index % 2 == 0 ? 'Start Exam' : 'View Details',
                          buttonBgColor: index % 2 == 0
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF5B21B6),
                          buttonTextColor: index % 2 == 0
                              ? const Color(0xFF1E1B4B)
                              : Colors.white,
                          onButtonPressed: () => _handleStartExam(exam),
                          onBookmarkToggle: () => _handleBookmarkToggle(exam),
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}