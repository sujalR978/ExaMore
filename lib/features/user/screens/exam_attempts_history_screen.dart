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
  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTimeFilter = 'All Time';

  String _assignedAdminId = '';
  bool _isLoadingUser = true;
  Stream<List<Map<String, dynamic>>>? _attemptsStream;

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
    final user = _currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _attemptsStream = Stream.value(<Map<String, dynamic>>[]);
          _isLoadingUser = false;
        });
      }
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
      }
    } catch (_) {}

    _attemptsStream = _examService.getUserExamAttemptsStream(user.uid);

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
        fullExam = await _examService.getExamById(examId);
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

  /// Returns chat-style relative date header label
  String _getChatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(itemDate).inDays < 7 &&
        itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE, MMM d').format(date); // e.g. "Monday, Nov 17"
    } else if (itemDate.year == now.year) {
      return DateFormat('MMMM d, yyyy').format(date); // e.g. "November 14, 2026"
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  /// Returns 12-hour formatted time with AM/PM (e.g. "10:30 AM")
  String _formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                    'Track your scores, answers, and progress over time',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoadingUser || _attemptsStream == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
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

                // Filter by assigned adminId and time filter
                final List<Map<String, dynamic>> filteredAttempts = [];
                final now = DateTime.now();

                int totalPassed = 0;
                double totalScoreSum = 0;

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

                  final subject = (item['category'] ?? item['subject'] ?? '')
                      .toString()
                      .trim();
                  final examTitle = submission.examTitle.trim();
                  final dateHeader = _getChatDateLabel(submission.submittedAt);

                  // Search query filter
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery;
                    final matches = examTitle.toLowerCase().contains(q) ||
                        subject.toLowerCase().contains(q) ||
                        dateHeader.toLowerCase().contains(q);
                    if (!matches) continue;
                  }

                  filteredAttempts.add(item);

                  if (submission.isPassed || submission.scorePercentage >= 50) {
                    totalPassed++;
                  }
                  totalScoreSum += submission.scorePercentage;
                }

                // Sort descending (newest attempt first)
                filteredAttempts.sort((a, b) {
                  final subA = a['submission'] as StudentSubmissionModel;
                  final subB = b['submission'] as StudentSubmissionModel;
                  return subB.submittedAt.compareTo(subA.submittedAt);
                });

                // Group chronologically by date like a chat log
                final Map<String, List<Map<String, dynamic>>> chatDateGroups = {};
                for (var item in filteredAttempts) {
                  final sub = item['submission'] as StudentSubmissionModel;
                  final label = _getChatDateLabel(sub.submittedAt);
                  chatDateGroups.putIfAbsent(label, () => []).add(item);
                }

                final double avgScore = filteredAttempts.isNotEmpty
                    ? (totalScoreSum / filteredAttempts.length)
                    : 0.0;
                final double passRate = filteredAttempts.isNotEmpty
                    ? ((totalPassed / filteredAttempts.length) * 100)
                    : 0.0;

                return RefreshIndicator(
                  onRefresh: () async {
                    await _fetchStudentAdminAndInitStream();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      // Overview Metric Cards
                      if (rawAttempts.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total Attempts',
                                value: '${filteredAttempts.length}',
                                icon: Icons.assignment_turned_in_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pass Rate',
                                value: '${passRate.toInt()}%',
                                icon: Icons.verified_rounded,
                                iconColor: const Color(0xFF10B981),
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Average Score',
                                value: '${avgScore.toInt()}%',
                                icon: Icons.trending_up_rounded,
                                iconColor: const Color(0xFFF59E0B),
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Search and Filter Controls
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: textPrimary, fontSize: 13.5),
                              decoration: InputDecoration(
                                hintText: "Search exam, subject, or date...",
                                hintStyle: TextStyle(color: textMuted, fontSize: 13),
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
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<String>(
                            tooltip: 'Filter by Time Period',
                            color: cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                            ].map((filter) {
                              final isSel = filter == _selectedTimeFilter;
                              return PopupMenuItem<String>(
                                value: filter,
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSel
                                        ? const Color(0xFF7C3AED)
                                        : textPrimary,
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list_rounded,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedTimeFilter,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Empty State
                      if (chatDateGroups.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 40),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long_rounded,
                                  color: Color(0xFF7C3AED),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                rawAttempts.isEmpty
                                    ? 'No Exam Attempts Yet'
                                    : 'No Matching Attempts Found',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                rawAttempts.isEmpty
                                    ? 'Take your first test to see your history, scores, and answer reviews here.'
                                    : 'Try searching for a different keyword or change your time filter.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        // Chat-Style Chronological Grouping
                        ...chatDateGroups.entries.map((entry) {
                          final dateLabel = entry.key;
                          final attemptsInDay = entry.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Chat-style floating date separator bubble
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Divider(
                                        color: borderColor.withValues(alpha: 0.6),
                                        thickness: 1,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 12),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? const Color(0xFF1E293B)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: borderColor.withValues(alpha: 0.8),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_rounded,
                                            size: 11,
                                            color: textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            dateLabel,
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Divider(
                                        color: borderColor.withValues(alpha: 0.6),
                                        thickness: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Attempt Cards for this date
                              ...attemptsInDay.map((attempt) {
                                final examId = (attempt['examId'] ?? '').toString();
                                final submission =
                                    attempt['submission'] as StudentSubmissionModel;
                                final subjectName =
                                    (attempt['category'] ?? attempt['subject'] ?? '')
                                        .toString()
                                        .trim();

                                return _buildAttemptCard(
                                  examId: examId,
                                  submission: submission,
                                  subjectName: subjectName.isNotEmpty
                                      ? subjectName
                                      : 'General Assessment',
                                  cardColor: cardColor,
                                  surfaceSec: surfaceSec,
                                  borderColor: borderColor,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  isDarkMode: isDarkMode,
                                );
                              }),
                            ],
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Overview Metric Micro-Card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: iconColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Modern Exam Attempt Card
  Widget _buildAttemptCard({
    required String examId,
    required StudentSubmissionModel submission,
    required String subjectName,
    required Color cardColor,
    required Color surfaceSec,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required bool isDarkMode,
  }) {
    final bool isPassed = submission.isPassed || submission.scorePercentage >= 50;
    final timeStr = _formatTime(submission.submittedAt);
    final examTitle = submission.examTitle.trim().isNotEmpty
        ? submission.examTitle.trim()
        : 'Assessment';

    final scorePercent = submission.scorePercentage;
    final scoreStr = (scorePercent == scorePercent.roundToDouble())
        ? '${scorePercent.toInt()}%'
        : '${scorePercent.toStringAsFixed(1)}%';

    final marksStr =
        '${submission.marksObtained.toInt()} / ${submission.totalMarks.toInt()} Marks';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : const Color(0xFFEF4444).withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleAttemptTap(
            examId: examId,
            submission: submission,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Subject Badge (Left) + Chat Time Stamp (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Subject Name Badge
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 13,
                              color: Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                subjectName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Submission Time (Chat Style)
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Exam Name
                Text(
                  examTitle,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),

                // Score Banner & Pass/Fail Status Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceSec,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.6),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              scoreStr,
                              style: TextStyle(
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            marksStr,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPassed
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : const Color(0xFFEF4444).withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPassed
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 13,
                              color: isPassed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPassed ? 'Passed' : 'Needs Retake',
                              style: TextStyle(
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Answer Breakdown Chips & Action Link
                Row(
                  children: [
                    // Correct Answers Chip
                    _buildStatPill(
                      label: '${submission.correctAnswers} Correct',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_rounded,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 8),

                    // Incorrect Answers Chip
                    _buildStatPill(
                      label: '${submission.incorrectAnswers} Incorrect',
                      color: const Color(0xFFEF4444),
                      icon: Icons.close_rounded,
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(width: 8),

                    // Unattempted Chip
                    if (submission.unattemptedAnswers > 0)
                      _buildStatPill(
                        label: '${submission.unattemptedAnswers} Skipped',
                        color: const Color(0xFF94A3B8),
                        icon: Icons.remove_rounded,
                        isDarkMode: isDarkMode,
                      ),

                    const Spacer(),

                    // Review chevron link
                    Row(
                      children: [
                        Text(
                          'Review',
                          style: TextStyle(
                            color: const Color(0xFF8B5CF6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact Question Stat Pill
  Widget _buildStatPill({
    required String label,
    required Color color,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDarkMode ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
