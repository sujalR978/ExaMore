import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/examDetail.dart';
import 'package:prep_mate/features/User/widget/examListWidget.dart';


class AllExamsScreen extends StatefulWidget {
  const AllExamsScreen({super.key});

  @override
  State<AllExamsScreen> createState() => _AllExamsScreenState();
}

class _AllExamsScreenState extends State<AllExamsScreen> {
  final ExamService _examService = ExamService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All Subjects',
    'Mathematics',
    'Science',
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

  void _handleExamTap(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExamdetailPage(exam: exam),
      ),
    );
  }

  String _calculateDifficulty(ExamModel exam) {
    if (exam.passingScorePercentage >= 75 || exam.durationMinutes >= 120) {
      return 'Hard';
    } else if (exam.passingScorePercentage >= 50) {
      return 'Medium';
    }
    return 'Easy';
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
                    'All Exams',
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
              'Explore All Assessments',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Browse through our complete repository of standardized tests and quizzes.',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search exams by title or keyword...",
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

            // Filter Category Chips
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

            // Realtime Stream of Published Exams
            StreamBuilder<List<ExamModel>>(
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
                        'Failed to load assessments: ${snapshot.error}',
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
                            : 'No assessments available under this category.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 14),
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
                    return ExamListItemWidget(
                      title: exam.title,
                      category: exam.category,
                      time: '${exam.durationMinutes} mins',
                      mcqs: '${exam.questions.length} MCQs',
                      difficulty: _calculateDifficulty(exam),
                      onTap: () => _handleExamTap(exam),
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