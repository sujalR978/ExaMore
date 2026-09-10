import 'package:flutter/material.dart';
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
  int _selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = ['All Subjects', 'Science', 'Mathematics'];

  void _handleViewAll() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => AllExamsScreen()));
  }

  void _handleStartExam(String title) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundImage: const NetworkImage(
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
                            builder: (context) => Settingscreen(),
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

            // Search Bar with Filter Icon
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search for 'Calculus' or 'Biology'...",
                      hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                      prefixIcon: Icon(Icons.search, color: subtitleColor),
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
                      print('Filter clicked');
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

            // Exam Card 1: Advanced Calculus
            ExamCardWidget(
              badgeText: 'MATHEMATICS',
              badgeColor: isDarkMode
                  ? const Color(0xFF312E81)
                  : const Color(0xFFDBEAFE),
              badgeTextColor: isDarkMode
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1D4ED8),
              title: 'Advanced Calculus Midterm Prep',
              description:
                  'Comprehensive review of derivatives, integrals, and limits with detailed...',
              time: '90 mins',
              mcqs: '40 MCQs',
              icon: Icons.calculate_outlined,
              isBookmarked: true,
              buttonText: 'Start Exam',
              buttonBgColor: const Color(0xFFFBBF24),
              buttonTextColor: const Color(0xFF1E1B4B),
              onButtonPressed: () =>
                  _handleStartExam('Advanced Calculus Midterm Prep'),
            ),
            const SizedBox(height: 16),

            // Exam Card 2: Organic Chemistry Fundamentals
            ExamCardWidget(
              badgeText: 'SCIENCE',
              badgeColor: isDarkMode
                  ? const Color(0xFF2E2A72)
                  : const Color(0xFFDBEAFE),
              badgeTextColor: isDarkMode
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1D4ED8),
              title: 'Organic Chemistry Fundamentals',
              description:
                  'Test your knowledge on reaction mechanisms, functional groups, and...',
              time: '60 mins',
              mcqs: '30 MCQs',
              icon: Icons.science_outlined,
              isBookmarked: true,
              buttonText: 'View Details',
              buttonBgColor: const Color(0xFF5B21B6),
              buttonTextColor: Colors.white,
              onButtonPressed: () =>
                  _handleStartExam('Organic Chemistry Fundamentals'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
