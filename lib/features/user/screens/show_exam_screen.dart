// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/user/screens/all_exam_screen.dart';
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/user/widgets/show_exams_widget.dart';

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

  String _assignedAdminId = '';
  String _studentClassroomId = '';
  bool _isLoadingUser = true;

  List<String> _categories = [
    'All Subjects',
  ];
  List<String> _enrolledSubjects = [];

  late final Stream<List<dynamic>> _savedExamsStream;
  Stream<List<ExamModel>>? _publishedExamsStream;

  @override
  void initState() {
    super.initState();
    final uid = _currentUser?.uid ?? '';
    _savedExamsStream = _examService.getSavedExamsStream(uid);

    _fetchStudentAdminAndInitStream();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  /// Looks up the student's linked adminId & classroom from their Firestore profile
  Future<void> _fetchStudentAdminAndInitStream() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        _assignedAdminId = (data['adminId'] ?? '').toString().trim();
        _studentClassroomId = (data['classroomId'] ?? '').toString().trim();

        if (_studentClassroomId.isNotEmpty) {
          final classDoc = await FirebaseFirestore.instance
              .collection('classrooms')
              .doc(_studentClassroomId)
              .get();
          if (classDoc.exists) {
            final cData = classDoc.data() ?? {};
            final subs = List<String>.from(cData['subjects'] ?? []);
            _enrolledSubjects = subs;
            if (subs.isNotEmpty) {
              _categories = ['All Subjects', ...subs];
            } else {
              _categories = ['All Subjects', 'General'];
            }
          }
        }
      }
    } catch (_) {}

    _updatePublishedExamsStream();

    if (mounted) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  /// Updates the stream scoped to the student's assigned instructor & classroom
  void _updatePublishedExamsStream() {
    final selectedCategory = _selectedCategoryIndex == 0
        ? null
        : _categories[_selectedCategoryIndex];

    _publishedExamsStream = _examService.getPublishedExamsStream(
      category: selectedCategory,
      adminId: _assignedAdminId,
      classroomId: _studentClassroomId,
      enrolledSubjects: _enrolledSubjects,
      role: 'student',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _updatePublishedExamsStream();
    });
  }

  void _handleViewAll() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AllExamsScreen()));
  }

  void _handleStartExam(ExamModel exam) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)));
  }

  Future<void> _handleBookmarkToggle(ExamModel exam, String userId) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save exams.')),
      );
      return;
    }

    try {
      final isSaved = await _examService.toggleSaveExam(
        userId: userId,
        exam: exam,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'Exam saved to bookmarks!' : 'Removed from bookmarks.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update bookmark: $e')));
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

    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);

    final userId = _currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explore Exams',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Find practice tests and assessments across all subjects.',
              style: TextStyle(
                color: textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textSecondary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Settingscreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingUser || _publishedExamsStream == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar with Clean Styling
                  TextField(
                    controller: _searchController,
                    style: TextStyle(color: textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Search for subjects, topics or exams...",
                      hintStyle: TextStyle(
                        color: textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: textSecondary,
                                size: 18,
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(
                          color: Color(0xFF7C3AED),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedCategoryIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _onCategorySelected(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _categories[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section Header: Recommended for You
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recommended for You',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleViewAll,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF59E0B)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Synchronized Streams: Saved IDs + Scoped Published Exams
                  StreamBuilder<List>(
                    stream: _savedExamsStream,
                    builder: (context, savedSnapshot) {
                      final savedIds = (savedSnapshot.data ?? [])
                          .map((item) => (item['exam'] as ExamModel).id)
                          .toSet();

                      return StreamBuilder<List<ExamModel>>(
                        stream: _publishedExamsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20.0,
                                ),
                                child: Text(
                                  'Error loading exams: ${snapshot.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            );
                          }

                          final allExams = snapshot.data ?? [];

                          final filteredExams = allExams.where((exam) {
                            return exam.title.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                exam.category.toLowerCase().contains(
                                  _searchQuery,
                                ) ||
                                exam.examCode.toLowerCase().contains(
                                  _searchQuery,
                                );
                          }).toList();

                          if (filteredExams.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: borderColor),
                              ),
                              child: Center(
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No exams found matching "$_searchQuery"'
                                      : (_assignedAdminId.isEmpty
                                            ? 'You are not linked to any instructor yet.'
                                            : 'No published assessments available from your instructor under this category.'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredExams.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final exam = filteredExams[index];
                              final isBookmarked = savedIds.contains(exam.id);

                              final isMath =
                                  exam.category.toLowerCase().contains(
                                    'math',
                                  ) ||
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
                                buttonText: index % 2 == 0
                                    ? 'Start Exam'
                                    : 'View Details',
                                buttonBgColor: index % 2 == 0
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF5B21B6),
                                buttonTextColor: index % 2 == 0
                                    ? const Color(0xFF1E1B4B)
                                    : Colors.white,
                                onButtonPressed: () => _handleStartExam(exam),
                                onBookmarkToggle: () =>
                                    _handleBookmarkToggle(exam, userId),
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
