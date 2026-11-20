// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/user/screens/exam_result_screen.dart';

class ExamAttemptsHistoryScreen extends StatefulWidget {
  const ExamAttemptsHistoryScreen({super.key});

  @override
  State<ExamAttemptsHistoryScreen> createState() =>
      _ExamAttemptsHistoryScreenState();
}

class _ExamAttemptsHistoryScreenState extends State<ExamAttemptsHistoryScreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTimeFilter = 'All Time';

  String _assignedAdminId = '';
  bool _isLoadingUser = true;
  Stream<List>? _attemptsStream;

  @override
  void initState() {
    super.initState();
    _fetchStudentAdminAndInitStream();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase().trim();
        });
      }
    });
  }

  /// Looks up the student's linked adminId from their Firestore profile
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
      }
    } catch (_) {}

    _attemptsStream = _examService.getUserExamAttemptsStream(_currentUser.uid);

    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAttemptTap({
    required String examId,
    required StudentSubmissionModel submission,
  }) async {
    ExamModel? fullExam;
    try {
      if (examId.isNotEmpty) {
        fullExam = await _examService.getExamStream(examId).first;
      }
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExamResultScreen(exam: fullExam, submission: submission),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final surfaceSec = AppColors.surfaceSecondary(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exam Attempts History',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review your scores and performance across all exam attempts.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoadingUser || _attemptsStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List>(
              stream: _attemptsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
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
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'Error loading attempts history: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final rawAttempts = snapshot.data ?? [];

                // Filter by assigned adminId if available, then group by exam title
                final Map<String, List<dynamic>> groupedData = {};

                final now = DateTime.now();
                for (var item in rawAttempts) {
                  final submission =
                      item['submission'] as StudentSubmissionModel;
                  final examAdminId = (item['adminId'] ?? '').toString().trim();

                  // Cohort isolation
                  if (_assignedAdminId.isNotEmpty &&
                      examAdminId.isNotEmpty &&
                      examAdminId != _assignedAdminId) {
                    continue;
                  }

                  // Time filter
                  if (_selectedTimeFilter == 'Past 7 Days') {
                    if (now.difference(submission.submittedAt).inDays > 7) {
                      continue;
                    }
                  } else if (_selectedTimeFilter == 'Past 30 Days') {
                    if (now.difference(submission.submittedAt).inDays > 30) {
                      continue;
                    }
                  } else if (_selectedTimeFilter == 'This Year') {
                    if (submission.submittedAt.year != now.year) {
                      continue;
                    }
                  }

                  final key = submission.examTitle.isNotEmpty
                      ? submission.examTitle
                      : 'Standardized Assessment';

                  groupedData.putIfAbsent(key, () => []).add(item);
                }

                // Filter by search query
                final filteredEntries = groupedData.entries.where((entry) {
                  final title = entry.key.toLowerCase();
                  return title.contains(_searchQuery);
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search and Filter Header
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 14),
                              decoration: InputDecoration(
                                hintText: "Search exam, subject or date...",
                                hintStyle: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(Icons.search_rounded, color: textMuted, size: 20),
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
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          PopupMenuButton<String>(
                            tooltip: 'Filter by Time',
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: borderColor),
                            ),
                            initialValue: _selectedTimeFilter,
                            onSelected: (val) {
                              setState(() {
                                _selectedTimeFilter = val;
                              });
                            },
                            itemBuilder: (context) => [
                              'All Time',
                              'Past 7 Days',
                              'Past 30 Days',
                              'This Year',
                            ].map((f) {
                              final isSel = f == _selectedTimeFilter;
                              return PopupMenuItem<String>(
                                value: f,
                                child: Text(
                                  f,
                                  style: TextStyle(
                                    color: isSel ? const Color(0xFF7C3AED) : textPrimary,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded, size: 15, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedTimeFilter,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textSecondary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (filteredEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Center(
                            child: Text(
                              rawAttempts.isEmpty
                                  ? 'No exam attempts recorded yet.'
                                  : 'No exams found matching "$_searchQuery"',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            const minTableWidth = 560.0;
                            final tableWidth = constraints.maxWidth < minTableWidth
                                ? minTableWidth
                                : constraints.maxWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Table Columns Header
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: surfaceSec,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderColor, width: 0.8),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 7,
                                            child: Text(
                                              'Exam / Subject',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              'Date',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              'Score',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 85,
                                            child: Text(
                                              'Result',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // List of Exam Attempts
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: filteredEntries.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final entry = filteredEntries[index];
                                        final attemptsList = entry.value;

                                        return Column(
                                          children: List.generate(attemptsList.length, (attemptIdx) {
                                            final item = attemptsList[attemptIdx];
                                            final examId = (item['examId'] ?? '').toString();
                                            final submission = item['submission'] as StudentSubmissionModel;

                                            final isPass = submission.isPassed || submission.scorePercentage >= 50;
                                            final scoreText =
                                                '${submission.marksObtained.toInt()} / ${submission.totalMarks.toInt()} (${submission.scorePercentage.toInt()}%)';

                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                              decoration: BoxDecoration(
                                                color: cardColor,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: borderColor, width: 0.8),
                                              ),
                                              child: InkWell(
                                                onTap: () => _handleAttemptTap(examId: examId, submission: submission),
                                                child: Row(
                                                  children: [
                                                    // Left Icon + Exam Title & Subject
                                                    Expanded(
                                                      flex: 7,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 38,
                                                            height: 38,
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF7C3AED).withOpacity(0.15),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: const Icon(
                                                              Icons.assignment_rounded,
                                                              color: Color(0xFF7C3AED),
                                                              size: 18,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  submission.examTitle.isNotEmpty
                                                                      ? submission.examTitle
                                                                      : 'Calculus Basics',
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    color: textPrimary,
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 13.5,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 2),
                                                                Text(
                                                                  'Completed Assessment',
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: TextStyle(
                                                                    color: textMuted,
                                                                    fontSize: 11.5,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Date
                                                    Expanded(
                                                      flex: 5,
                                                      child: Row(
                                                        children: [
                                                          Icon(Icons.calendar_today_outlined, size: 13, color: textMuted),
                                                          const SizedBox(width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              _formatDate(submission.submittedAt),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                color: textSecondary,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Score
                                                    Expanded(
                                                      flex: 5,
                                                      child: Text(
                                                        scoreText,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: textPrimary,
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 12.5,
                                                        ),
                                                      ),
                                                    ),
                                                    // Result Badge + Arrow
                                                    SizedBox(
                                                      width: 85,
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.end,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isPass
                                                                  ? const Color(0xFF10B981).withOpacity(0.18)
                                                                  : const Color(0xFFEF4444).withOpacity(0.18),
                                                              borderRadius: BorderRadius.circular(20),
                                                            ),
                                                            child: Text(
                                                              isPass ? 'Passed' : 'Failed',
                                                              style: TextStyle(
                                                                color: isPass
                                                                    ? const Color(0xFF10B981)
                                                                    : const Color(0xFFEF4444),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Icon(Icons.chevron_right_rounded, size: 16, color: textMuted),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
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

  Widget _buildExamGroupCard({
    required String examTitle,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required List<dynamic> attempts,
  }) {
    final totalAttempts = attempts.length;

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
                  'EXAM EVALUATION',
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
                '$totalAttempts ${totalAttempts == 1 ? 'Attempt' : 'Attempts'}',
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

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = attempts[index];
              final examId = item['examId'] as String;
              final submission = item['submission'] as StudentSubmissionModel;

              final attemptNumber = 'Attempt ${totalAttempts - index}';
              final isPass = submission.isPassed;
              final scoreText =
                  '${submission.marksObtained.toInt()}/${submission.totalMarks.toInt()}';
              final percentageText = '${submission.scorePercentage.toInt()}%';

              return InkWell(
                onTap: () =>
                    _handleAttemptTap(examId: examId, submission: submission),
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
                                attemptNumber,
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
                                  color: isPass
                                      ? (isDarkMode
                                            ? const Color(0xFF064E3B)
                                            : const Color(0xFFD1FAE5))
                                      : (isDarkMode
                                            ? const Color(0xFF451A03)
                                            : const Color(0xFFFEF2F2)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPass ? 'PASS' : 'FAIL',
                                  style: TextStyle(
                                    color: isPass
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
                            _formatDate(submission.submittedAt),
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
                                scoreText,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                percentageText,
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
