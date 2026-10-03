import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/User/screen/activeExamScreen.dart';

class ExamdetailPage extends StatefulWidget {
  final ExamModel? exam;

  const ExamdetailPage({super.key, this.exam});

  @override
  State<ExamdetailPage> createState() => _ExamdetailPageState();
}

class _ExamdetailPageState extends State<ExamdetailPage> {
  final ExamService _examService = ExamService();
  late ExamModel _exam;
  bool _isSaved = false;
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
          durationMinutes: 60,
          totalMarks: 100,
          status: 'Published',
        );

    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final uid = _currentUser?.uid;
    if (uid == null || _exam.id.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_exams')
          .doc(_exam.id)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleToggleBookmark() async {
    final uid = _currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save exams.')),
      );
      return;
    }

    // Safety check: Ensure the exam ID exists
    if (_exam.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save: Invalid Exam ID.')),
      );
      return;
    }

    try {
      final savedNow = await _examService.toggleSaveExam(
        userId: uid,
        exam: _exam,
      );

      if (!mounted) return;
      setState(() => _isSaved = savedNow);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedNow ? 'Exam saved to bookmarks!' : 'Removed from saved exams.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update bookmark: $e')));
    }
  }

  String _formatScheduleDate(DateTime? date) {
    if (date == null) return 'Available anytime on demand';
    return 'Scheduled for: ${DateFormat('MMM dd, yyyy • hh:mm a').format(date)}';
  }

  void _handleStartExam(BuildContext context) {
    if (_exam.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This exam currently has no questions available.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

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
                    builder: (context) => ActiveExamScreen(exam: _exam),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF1E1B4B),
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
                    'Exam Details',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved ? const Color(0xFFFBBF24) : textColor,
                          size: 24,
                        ),
                        onPressed: _handleToggleBookmark,
                      ),
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
            // Main Header Card
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
                          color: isDarkMode
                              ? const Color(0xFF2E2A72)
                              : const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _exam.examCode.isNotEmpty
                              ? _exam.examCode
                              : _exam.category.toUpperCase(),
                          style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF1D4ED8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
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
                  const SizedBox(height: 16),
                  // Schedule Info Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: isDarkMode
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatScheduleDate(_exam.startDate),
                            style: TextStyle(
                              color: isDarkMode
                                  ? const Color(0xFF93C5FD)
                                  : const Color(0xFF1D4ED8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Subject: ${_exam.category}. Passing requirement is ${_exam.passingScorePercentage.toInt()}%. Negative marking penalty: ${_exam.negativeMarking} pts per wrong answer.',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stats Row (Mins, MCQs, Marks)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.access_time,
                          '${_exam.durationMinutes}',
                          'MINS',
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
                          Icons.list_alt,
                          '${_exam.questions.length}',
                          'MCQS',
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

            // Instructions Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rule,
                        color: isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF1E1B4B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInstructionItem(
                    Icons.do_not_disturb_on_outlined,
                    'No external aids, calculators, or reference materials are permitted during this examination.',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    Icons.timer_outlined,
                    'The exam will automatically submit when the timer reaches zero.',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    Icons.visibility_off_outlined,
                    'Ensure your testing environment is quiet and free from distractions. Proctoring is active.',
                    textColor,
                    subtitleColor,
                  ),
                  const SizedBox(height: 12),
                  _buildInstructionItem(
                    Icons.check_circle_outline,
                    'You may review and change your answers before final submission.',
                    textColor,
                    subtitleColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Performers Card (Live Stream from Submissions)
            StreamBuilder<List<StudentSubmissionModel>>(
              stream: _examService.getExamSubmissionsStream(_exam.id),
              builder: (context, snapshot) {
                final submissions = snapshot.data ?? [];
                final topPerformers = submissions.take(3).toList();

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            color: isDarkMode
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFF1E1B4B),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Top Performers',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (topPerformers.isEmpty)
                        Text(
                          'No candidates have completed this assessment yet. Be the first!',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topPerformers.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 24),
                          itemBuilder: (context, idx) {
                            final p = topPerformers[idx];
                            final rank = idx == 0
                                ? '1st'
                                : idx == 1
                                ? '2nd'
                                : '3rd';
                            return _buildPerformerRow(
                              rank,
                              p.studentName,
                              '${p.marksObtained.toInt()} /${p.totalMarks.toInt()}',
                              isDarkMode,
                              textColor,
                              subtitleColor,
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Topics Covered Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        color: isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF1E1B4B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Topics Covered',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTopicChip(_exam.category, isDarkMode),
                      _buildTopicChip('Assessment Questions', isDarkMode),
                      _buildTopicChip('Graded Evaluation', isDarkMode),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Honor Code Notice Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF2563EB),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'By starting this exam, you agree to the University Honor Code. You confirm that you will not give or receive unauthorized assistance during this assessment.',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Start Exam Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _handleStartExam(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: const Color(0xFF1E1B4B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start Exam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
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
          Icon(icon, color: const Color(0xFFF59E0B), size: 22),
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

  Widget _buildInstructionItem(
    IconData icon,
    String text,
    Color textCol,
    Color subTextCol,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: subTextCol, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformerRow(
    String rank,
    String name,
    String score,
    bool isDarkMode,
    Color textCol,
    Color subTextCol,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF312E81)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  rank,
                  style: TextStyle(
                    color: isDarkMode
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFFB45309),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: isDarkMode ? Colors.white12 : Colors.grey[200],
              child: Icon(Icons.person, size: 20, color: subTextCol),
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                color: textCol,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          score,
          style: TextStyle(
            color: textCol,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicChip(String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF065F46),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
