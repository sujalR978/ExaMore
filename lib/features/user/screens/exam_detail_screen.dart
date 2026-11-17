// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/user/screens/active_exam_screen.dart';
import 'package:prep_mate/features/user/screens/exam_result_screen.dart';

class ExamdetailPage extends StatefulWidget {
  final ExamModel? exam;

  const ExamdetailPage({super.key, this.exam});

  @override
  State<ExamdetailPage> createState() => _ExamdetailPageState();
}

class _ExamdetailPageState extends State<ExamdetailPage> {
  late ExamModel _exam;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _exam =
        widget.exam ??
        ExamModel(
          id: '',
          examCode: 'EXM-2026-001',
          title: 'General Assessment',
          category: 'General',
          adminId: '',
          durationMinutes: 60,
          totalMarks: 100,
          status: 'Published',
        );
  }

  Future<void> _handleStartExam(BuildContext context) async {
    if (_exam.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This exam currently has no questions available.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final uid = _currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before starting an examination.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 1. Verify Timeslot
    final now = DateTime.now();
    if (_exam.startDate != null && now.isBefore(_exam.startDate!)) {
      final dateStr =
          DateFormat('EEE, MMM d, yyyy • h:mm a').format(_exam.startDate!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This exam is scheduled to open on $dateStr.'),
          backgroundColor: const Color(0xFFF59E0B),
        ),
      );
      return;
    }

    if (_exam.endDate != null && now.isAfter(_exam.endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam closed. The deadline for this exam has passed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. 3-Tier Access Verification: Check user's assigned admin vs Exam's admin
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userData = userDoc.data() ?? {};
      final String userRole = (userData['role'] ?? 'student')
          .toString()
          .toLowerCase();
      final String userAdminId = userData['adminId'] ?? '';

      // Super admins bypass restriction. Students must match exam.adminId
      if (userRole != 'super_admin' &&
          _exam.adminId.isNotEmpty &&
          userAdminId != _exam.adminId) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Access Restricted'),
            content: const Text(
              'You are only permitted to access assessments assigned by your designated Admin/Instructor.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // 3. Strict Allowed Attempts limit verification
      final int maxAttempts =
          _exam.allowedAttempts > 0 ? _exam.allowedAttempts : 1;
      final existingAttempts = await FirebaseFirestore.instance
          .collection('exams')
          .doc(_exam.id)
          .collection('submissions')
          .where('userId', isEqualTo: uid)
          .get();

      if (existingAttempts.docs.length >= maxAttempts) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.lock_clock_outlined, color: Color(0xFF7C3AED)),
                SizedBox(width: 10),
                Text('Attempt Limit Reached'),
              ],
            ),
            content: Text(
              'You have already given this exam $maxAttempts out of $maxAttempts allowed time${maxAttempts > 1 ? 's' : ''}.\n\nYour highest score has been saved as your final score.',
              style: const TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Are you sure?',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Once you begin, the timer of ${_exam.durationMinutes} minutes will start. Make sure you have a stable internet connection.',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ActiveExamScreen(exam: _exam),
                  ),
                );
              },
              child: const Text(
                'Start Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? const Color(0xFF0F0E17)
        : const Color(0xFFF8FAFC);
    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final bool isPublished = _exam.status.toLowerCase() == 'published';

    final int maxAttempts =
        _exam.allowedAttempts > 0 ? _exam.allowedAttempts : 1;
    final bool isClosed = _exam.isClosed;
    final bool isScheduled = _exam.isScheduled;

    final uid = _currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Assessment Details',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid.isNotEmpty && _exam.id.isNotEmpty
            ? FirebaseFirestore.instance
                .collection('exams')
                .doc(_exam.id)
                .collection('submissions')
                .where('userId', isEqualTo: uid)
                .snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          final submissionDocs = snapshot.data?.docs ?? [];
          final int attemptsCount = submissionDocs.length;
          final bool hasGivenExam = attemptsCount > 0;
          final bool canAttempt =
              attemptsCount < maxAttempts && !isClosed && !isScheduled;

          // Compute highest attempt score if given
          double highestScore = 0.0;
          StudentSubmissionModel? bestSubmission;
          if (hasGivenExam) {
            for (var doc in submissionDocs) {
              final sub = StudentSubmissionModel.fromFirestore(doc);
              if (bestSubmission == null || sub.marksObtained > highestScore) {
                highestScore = sub.marksObtained;
                bestSubmission = sub;
              }
            }
          }

          final totalMarksStr = (_exam.totalMarks.truncateToDouble() ==
                  _exam.totalMarks)
              ? _exam.totalMarks.toInt().toString()
              : _exam.totalMarks.toStringAsFixed(0);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Main Info Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isDarkMode ? 0.2 : 0.03,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _exam.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Status & Attempt Badge Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isPublished
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPublished
                                      ? Icons.check_circle_rounded
                                      : Icons.edit_note_rounded,
                                  size: 13,
                                  color: isPublished
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPublished ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    color: isPublished
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '$maxAttempts ${maxAttempts == 1 ? 'Attempt Allowed' : 'Attempts Allowed'}',
                              style: const TextStyle(
                                color: Color(0xFF7C3AED),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isClosed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_busy_rounded,
                                    size: 13,
                                    color: Color(0xFFEF4444),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Exam Closed',
                                    style: TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Specifications
                      _buildDetailRow(
                        'Subject:',
                        _exam.category.isNotEmpty ? _exam.category : 'General',
                        textColor,
                        subtitleColor,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Passing requirement:',
                        '${_exam.passingScorePercentage.toInt()}%',
                        textColor,
                        subtitleColor,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Negative marking:',
                        _exam.negativeMarking > 0
                            ? '${_exam.negativeMarking} pts per wrong answer'
                            : 'No negative marking',
                        textColor,
                        subtitleColor,
                      ),
                      if (_exam.startDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Opens on:',
                          DateFormat('EEE, MMM d, yyyy • h:mm a')
                              .format(_exam.startDate!),
                          textColor,
                          subtitleColor,
                        ),
                      ],
                      if (_exam.endDate != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Closes on:',
                          DateFormat('EEE, MMM d, yyyy • h:mm a')
                              .format(_exam.endDate!),
                          isClosed ? const Color(0xFFEF4444) : textColor,
                          subtitleColor,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Metrics Row (Duration, MCQS, Marks)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              Icons.access_time_rounded,
                              '${_exam.durationMinutes}',
                              'MINS',
                              const Color(0xFF7C3AED),
                              isDarkMode,
                              containerColor,
                              borderColor,
                              textColor,
                              subtitleColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatItem(
                              Icons.quiz_outlined,
                              '${_exam.questions.length}',
                              'QUESTIONS',
                              const Color(0xFF10B981),
                              isDarkMode,
                              containerColor,
                              borderColor,
                              textColor,
                              subtitleColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildStatItem(
                              Icons.military_tech_outlined,
                              totalMarksStr,
                              'MARKS',
                              const Color(0xFFF59E0B),
                              isDarkMode,
                              containerColor,
                              borderColor,
                              textColor,
                              subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // -------------------------------------------------------------
                // Attempt Performance or Missed Status Card
                // -------------------------------------------------------------
                if (hasGivenExam) ...[
                  // Case 1: Exam Given -> Show attempted marks and best score
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            isDarkMode ? 0.2 : 0.03,
                          ),
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
                            Text(
                              'YOUR ATTEMPT RESULT',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (bestSubmission?.isPassed ?? false)
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : const Color(0xFFEF4444).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (bestSubmission?.isPassed ?? false)
                                    ? 'PASSED'
                                    : 'FAILED',
                                style: TextStyle(
                                  color: (bestSubmission?.isPassed ?? false)
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              (highestScore.truncateToDouble() == highestScore)
                                  ? highestScore.toInt().toString()
                                  : highestScore.toStringAsFixed(1),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / $totalMarksStr pts',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${bestSubmission?.scorePercentage.toInt() ?? 0}%',
                              style: TextStyle(
                                color: (bestSubmission?.isPassed ?? false)
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Attempts used: $attemptsCount of $maxAttempts allowed${attemptsCount > 1 ? ' (Highest score counts)' : ''}',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12.5,
                          ),
                        ),
                        if (bestSubmission != null) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ExamResultScreen(
                                      exam: _exam,
                                      submission: bestSubmission,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 16,
                              ),
                              label: const Text('Review Your Answers'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF7C3AED),
                                side: const BorderSide(
                                  color: Color(0xFF7C3AED),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else if (isClosed) ...[
                  // Case 2: Exam Closed & Not Given -> mark as 0 / Total marks
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.event_busy_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ASSESSMENT CLOSED (MISSED)',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '0 / $totalMarksStr pts',
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The deadline for this assessment has passed. Since this exam was not attempted within the open window, your recorded score is 0 / $totalMarksStr.',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // -------------------------------------------------------------
                // Start Exam Action Button or Reason Disabled Banner
                // -------------------------------------------------------------
                Center(
                  child: Builder(
                    builder: (context) {
                      if (isClosed) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Exam Closed • Deadline Passed',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (isScheduled) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Opens on ${DateFormat('MMM d, h:mm a').format(_exam.startDate!)}',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!hasAttemptsRemaining(attemptsCount, maxAttempts)) {
                        // Max attempts reached -> Do not show start exam button
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF10B981),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Max Attempts Reached ($attemptsCount / $maxAttempts)',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Allowed to start / retake exam
                      final buttonLabel = attemptsCount == 0
                          ? 'Start Exam'
                          : 'Retake Exam (Attempt ${attemptsCount + 1} of $maxAttempts)';

                      return ElevatedButton.icon(
                        onPressed: () => _handleStartExam(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: Text(
                          buttonLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 36),
              ],
            ),
          );
        },
      ),
    );
  }

  bool hasAttemptsRemaining(int attemptsUsed, int maxAllowed) {
    return attemptsUsed < maxAllowed;
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color textColor,
    Color subtitleColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color iconColor,
    bool isDarkMode,
    Color containerBg,
    Color borderCol,
    Color textCol,
    Color subTextCol,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: textCol,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: subTextCol,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
