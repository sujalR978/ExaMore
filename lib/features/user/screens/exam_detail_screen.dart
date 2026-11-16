import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/user/screens/active_exam_screen.dart';

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

    // 3-Tier Access Verification: Check user's assigned admin vs Exam's admin
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

      // Check Allowed Attempts limit
      final int maxAttempts = _exam.allowedAttempts > 0 ? _exam.allowedAttempts : 1;
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
              fontSize: 20,
            ),
          ),
          content: Text(
            'Do you really want to start "${_exam.title}" now? Your timer (${_exam.durationMinutes} mins) will begin immediately.',
            style: TextStyle(
              color: isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600],
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDarkMode
                      ? const Color(0xFF94A3B8)
                      : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ActiveExamScreen(exam: _exam.sanitizeForStudent()),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, Start',
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

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final isPublished = _exam.status.toLowerCase() == 'published';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF7C3AED),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Assessment Details',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _exam.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _exam.examCode.isNotEmpty
                              ? _exam.examCode
                              : _exam.category.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? (isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                          : (isDarkMode
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPublished
                              ? Icons.check_circle_outline
                              : Icons.mail_outline,
                          size: 14,
                          color: isPublished
                              ? (isDarkMode
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFF065F46))
                              : (isDarkMode
                                    ? const Color(0xFFFCD34D)
                                    : const Color(0xFFB45309)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPublished
                              ? 'Live & Published'
                              : 'Draft / Not Published',
                          style: TextStyle(
                            color: isPublished
                                ? (isDarkMode
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF065F46))
                                : (isDarkMode
                                      ? const Color(0xFFFCD34D)
                                      : const Color(0xFFB45309)),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3-line specifications (Subject, Passing requirements, Negative marking)
                  _buildDetailRow(
                    'Subject:',
                    _exam.category.isNotEmpty ? _exam.category : 'General',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Passing requirements:',
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
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Allowed attempts:',
                    '${_exam.allowedAttempts} ${_exam.allowedAttempts == 1 ? 'attempt' : 'attempts'} (Highest score counts)',
                    textColor,
                    subtitleColor,
                  ),

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
                          'MCQS',
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
                          '${_exam.totalMarks.toInt()}',
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
            const SizedBox(height: 32),

            // Start Exam button with adaptive width
            Center(
              child: ElevatedButton.icon(
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
                label: const Text(
                  'Start Exam',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
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
