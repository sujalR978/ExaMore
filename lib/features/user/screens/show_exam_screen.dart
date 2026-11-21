// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _assignedAdminId = '';
  String _studentClassroomId = '';
  bool _isLoadingUser = true;
  List<String> _enrolledSubjects = [];

  Stream<List<dynamic>>? _savedExamsStream;
  Stream<List<Map<String, dynamic>>>? _userAttemptsStream;
  Stream<List<ExamModel>>? _publishedExamsStream;

  @override
  void initState() {
    super.initState();
    final uid = _currentUser?.uid ?? '';
    _savedExamsStream = _examService.getSavedExamsStream(uid);
    _userAttemptsStream = _examService.getUserExamAttemptsStream(uid);

    _fetchStudentAdminAndInitStream();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  /// Looks up student's linked adminId & classroom from their Firestore profile
  Future<void> _fetchStudentAdminAndInitStream() async {
    final user = _currentUser;
    if (user == null) {
      _updatePublishedExamsStream();
      if (mounted) setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
            _enrolledSubjects = List<String>.from(cData['subjects'] ?? []);
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
  /// without subject/category filters to include all enrolled subjects
  void _updatePublishedExamsStream() {
    _publishedExamsStream = _examService.getPublishedExamsStream(
      category: null, // No category filter - show all subjects
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

  String _formatScheduleDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow =
        dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;

    if (isToday) {
      return 'Today, ${DateFormat('h:mm a').format(dt)}';
    } else if (isTomorrow) {
      return 'Tomorrow, ${DateFormat('h:mm a').format(dt)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dt);
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
              'Upcoming and pending assessments for your classes.',
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
                      hintText: "Search upcoming exams, subjects...",
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
                  const SizedBox(height: 18),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Upcoming & Available Exams',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16.5,
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
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Synchronized Streams: User Attempts (Given) + Bookmarks + Published Exams
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _userAttemptsStream,
                    builder: (context, attemptsSnapshot) {
                      final attempts = attemptsSnapshot.data ?? [];
                      final givenExamIds = attempts
                          .map((a) => (a['examId'] ?? '').toString())
                          .where((id) => id.isNotEmpty)
                          .toSet();

                      return StreamBuilder<List<dynamic>>(
                        stream: _savedExamsStream,
                        builder: (context, savedSnapshot) {
                          final savedIds = (savedSnapshot.data ?? [])
                              .map((item) {
                                if (item is Map && item['exam'] is ExamModel) {
                                  return (item['exam'] as ExamModel).id;
                                }
                                return (item['examId'] ?? '').toString();
                              })
                              .where((id) => id.isNotEmpty)
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
                              final now = DateTime.now();

                              // Show only upcoming and non-given exams
                              final filteredExams = allExams.where((exam) {
                                // 1. Exclude already given/submitted exams
                                if (givenExamIds.contains(exam.id)) {
                                  return false;
                                }

                                // 2. Exclude closed/expired exams
                                if (exam.endDate != null && now.isAfter(exam.endDate!)) {
                                  return false;
                                }

                                // 3. Search query filter
                                if (_searchQuery.isNotEmpty) {
                                  final q = _searchQuery;
                                  final matches = exam.title.toLowerCase().contains(q) ||
                                      exam.category.toLowerCase().contains(q) ||
                                      exam.examCode.toLowerCase().contains(q);
                                  if (!matches) return false;
                                }

                                return true;
                              }).toList();

                              if (filteredExams.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 36,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981)
                                              .withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.assignment_turned_in_rounded,
                                          size: 32,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No matching exams found'
                                            : 'All Caught Up!',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No upcoming or open exams matched "$_searchQuery".'
                                            : (_assignedAdminId.isEmpty
                                                ? 'You are not linked to any instructor yet.'
                                                : 'No upcoming or pending exams are scheduled for you right now.'),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: textSecondary,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredExams.length,
                                itemBuilder: (context, index) {
                                  final exam = filteredExams[index];
                                  final isBookmarked = savedIds.contains(exam.id);

                                  final isUpcoming = exam.startDate != null &&
                                      now.isBefore(exam.startDate!);

                                  final String statusText;
                                  if (isUpcoming) {
                                    statusText =
                                        'Opens ${_formatScheduleDate(exam.startDate!)}';
                                  } else if (exam.endDate != null) {
                                    statusText =
                                        'Closes ${_formatScheduleDate(exam.endDate!)}';
                                  } else {
                                    statusText = 'Available Now';
                                  }

                                  final String buttonText =
                                      isUpcoming ? 'View Details' : 'Start Exam';

                                  return ExamCardWidget(
                                    badgeText: exam.category,
                                    title: exam.title,
                                    time: '${exam.durationMinutes} mins',
                                    mcqs: '${exam.questions.length} MCQs',
                                    marks: '${exam.totalMarks.toInt()} pts',
                                    statusText: statusText,
                                    isUpcoming: isUpcoming,
                                    isBookmarked: isBookmarked,
                                    buttonText: buttonText,
                                    onButtonPressed: () => _handleStartExam(exam),
                                    onBookmarkToggle: () =>
                                        _handleBookmarkToggle(exam, userId),
                                    onTap: () => _handleStartExam(exam),
                                  );
                                },
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
