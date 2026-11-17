// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';

class CandidateDetailScreen extends StatefulWidget {
  final String examId;
  final String submissionId;
  final StudentSubmissionModel? initialData;

  const CandidateDetailScreen({
    super.key,
    required this.examId,
    required this.submissionId,
    this.initialData,
  });

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  final ExamService _examService = ExamService();
  static final Map<String, String> _resolvedNameCache = {};

  String? _resolvedStudentName;
  String? _resolvedStudentPhoto;
  String? _resolvedStudentEmail;
  bool _isResolvingUser = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _checkAndResolveStudentName(
        widget.initialData!.studentId,
        widget.initialData!.studentName,
      );
    }
  }

  void _checkAndResolveStudentName(String studentId, String currentName) {
    if (studentId.isEmpty) return;

    if (_resolvedNameCache.containsKey(studentId)) {
      _resolvedStudentName = _resolvedNameCache[studentId];
      return;
    }

    final bool isFallback = currentName.trim().isEmpty ||
        currentName.trim().toLowerCase() == 'student user' ||
        currentName.trim().toLowerCase() == 'student';

    if (isFallback && !_isResolvingUser) {
      _isResolvingUser = true;
      FirebaseFirestore.instance
          .collection('users')
          .doc(studentId)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data() ?? {};
          final fetchedName = (data['name'] ??
                  data['fullName'] ??
                  data['displayName'] ??
                  '')
              .toString()
              .trim();
          final fetchedPhoto = (data['photoUrl'] ?? data['photoURL'] ?? '')
              .toString()
              .trim();
          final fetchedEmail = (data['email'] ?? '').toString().trim();

          if (fetchedName.isNotEmpty) {
            _resolvedNameCache[studentId] = fetchedName;
            setState(() {
              _resolvedStudentName = fetchedName;
              if (fetchedPhoto.isNotEmpty) _resolvedStudentPhoto = fetchedPhoto;
              if (fetchedEmail.isNotEmpty) _resolvedStudentEmail = fetchedEmail;
            });
          }
        }
      }).catchError((_) {
        // Silent catch
      }).whenComplete(() {
        if (mounted) _isResolvingUser = false;
      });
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ST';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = const Color(0xFF7C3AED);
    final surfaceColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Candidate Submission',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<StudentSubmissionModel>(
        stream: _examService.getCandidateDetailStream(
          examId: widget.examId,
          submissionId: widget.submissionId,
        ),
        initialData: widget.initialData,
        builder: (context, submissionSnap) {
          if (submissionSnap.connectionState == ConnectionState.waiting &&
              !submissionSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (submissionSnap.hasError && !submissionSnap.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading submission: ${submissionSnap.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final candidate = submissionSnap.data;
          if (candidate == null) {
            return Center(
              child: Text(
                'Submission record not found.',
                style: TextStyle(color: subtitleColor),
              ),
            );
          }

          // Trigger name lookup if needed
          _checkAndResolveStudentName(candidate.studentId, candidate.studentName);

          final displayName = _resolvedStudentName ??
              ((candidate.studentName.trim().isEmpty ||
                      candidate.studentName.trim().toLowerCase() ==
                          'student user')
                  ? 'Student #${candidate.studentId.length > 5 ? candidate.studentId.substring(0, 5) : candidate.studentId}'
                  : candidate.studentName);

          final isPassed = candidate.isPassed;
          final scorePct = candidate.scorePercentage.toInt();

          return StreamBuilder<ExamModel>(
            stream: _examService.getExamStream(widget.examId),
            builder: (context, examSnap) {
              final exam = examSnap.data;
              final questions = exam?.questions ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Profile & Performance Card
                    _buildCandidateProfileCard(
                      candidate: candidate,
                      displayName: displayName,
                      scorePct: scorePct,
                      isPassed: isPassed,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // 2. Metrics Statistics Bar
                    _buildMetricsGrid(
                      candidate: candidate,
                      surfaceColor: surfaceColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // 3. Section Title
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question Breakdown (${questions.length})',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 4. Questions & Answers List
                    if (questions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'Questions data is loading or no questions configured for this exam.',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          final studentAnswer = candidate.answers[question.id];

                          return _buildQuestionCard(
                            index: index,
                            question: question,
                            studentAnswer: studentAnswer,
                            surfaceColor: surfaceColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            borderColor: borderColor,
                            primaryColor: primaryColor,
                            isDark: isDark,
                          );
                        },
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Profile Card ---
  Widget _buildCandidateProfileCard({
    required StudentSubmissionModel candidate,
    required String displayName,
    required int scorePct,
    required bool isPassed,
    required Color surfaceColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required Color primaryColor,
    required bool isDark,
  }) {
    final photoUrl = _resolvedStudentPhoto ?? candidate.studentImageUrl;
    final dateStr =
        DateFormat('MMM d, yyyy • h:mm a').format(candidate.submittedAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              photoUrl != null && photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppImageView(
                        imageSource: photoUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(displayName),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
              const SizedBox(width: 14),

              // Name & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (_resolvedStudentEmail != null) ...[
                      Text(
                        _resolvedStudentEmail!,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pass / Fail Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPassed
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPassed ? 'PASSED' : 'FAILED',
                  style: TextStyle(
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),

          // Score Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OVERALL SCORE',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$scorePct',
                        style: TextStyle(
                          color: isPassed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '%',
                        style: TextStyle(
                          color: isPassed
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${candidate.marksObtained.truncateToDouble() == candidate.marksObtained ? candidate.marksObtained.toInt() : candidate.marksObtained.toStringAsFixed(1)} / ${candidate.totalMarks.toInt()} pts)',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  'ID: ${candidate.studentId.length > 8 ? candidate.studentId.substring(0, 8) : candidate.studentId}',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Metrics Statistics Grid ---
  Widget _buildMetricsGrid({
    required StudentSubmissionModel candidate,
    required Color surfaceColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            label: 'Correct',
            count: '${candidate.correctAnswers}',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle_rounded,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'Incorrect',
            count: '${candidate.incorrectAnswers}',
            color: const Color(0xFFEF4444),
            icon: Icons.cancel_rounded,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            label: 'Unattempted',
            count: '${candidate.unattemptedAnswers}',
            color: const Color(0xFF64748B),
            icon: Icons.remove_circle_outline_rounded,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String count,
    required Color color,
    required IconData icon,
    required Color surfaceColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            count,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --- Question Breakdown Card ---
  Widget _buildQuestionCard({
    required int index,
    required QuestionModel question,
    required dynamic studentAnswer,
    required Color surfaceColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required Color primaryColor,
    required bool isDark,
  }) {
    final bool isDescriptive = question.type.toLowerCase() == 'descriptive';
    final bool isUnattempted =
        studentAnswer == null || studentAnswer.toString().trim().isEmpty;

    bool isCorrect = false;
    if (!isUnattempted) {
      if (isDescriptive) {
        // Descriptive submission with answer recorded
        isCorrect = true;
      } else {
        isCorrect = (studentAnswer.toString() == question.correctOptionId);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnattempted
              ? borderColor
              : isCorrect
                  ? const Color(0xFF10B981).withOpacity(0.4)
                  : const Color(0xFFEF4444).withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Q Number + Type + Status Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDescriptive ? 'Descriptive' : 'MCQ',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${question.marks} pt${question.marks > 1 ? 's' : ''}',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnattempted
                      ? const Color(0xFF64748B).withOpacity(0.12)
                      : isCorrect
                          ? const Color(0xFF10B981).withOpacity(0.12)
                          : const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isUnattempted
                      ? 'UNATTEMPTED'
                      : isCorrect
                          ? 'CORRECT'
                          : 'INCORRECT',
                  style: TextStyle(
                    color: isUnattempted
                        ? const Color(0xFF64748B)
                        : isCorrect
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Question Image if attached
          if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
            GestureDetector(
              onTap: () {
                AppImageView.showFullScreenViewer(
                  context,
                  question.imageUrl!,
                  title: 'Question #${index + 1} Image',
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 140,
                  maxHeight: 320,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AppImageView(
                      imageSource: question.imageUrl!,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Zoom',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Question Text
          Text(
            question.questionText,
            style: TextStyle(
              color: textColor,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Render Answers
          if (isDescriptive) ...[
            // Descriptive Answer Box
            Text(
              'Candidate Response:',
              style: TextStyle(
                color: subtitleColor,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                isUnattempted
                    ? 'No response submitted by candidate.'
                    : studentAnswer.toString(),
                style: TextStyle(
                  color: isUnattempted ? subtitleColor : textColor,
                  fontSize: 13,
                  fontStyle:
                      isUnattempted ? FontStyle.italic : FontStyle.normal,
                  height: 1.4,
                ),
              ),
            ),
          ] else ...[
            // MCQ Options
            Column(
              children: question.options.map((option) {
                final isSelected =
                    (studentAnswer?.toString() == option.id);
                final isCorrectOption =
                    (option.id == question.correctOptionId);

                Color optBorder = borderColor;
                Color optBg = Colors.transparent;
                Color optTextColor = textColor;

                if (isCorrectOption) {
                  optBorder = const Color(0xFF10B981);
                  optBg = const Color(0xFF10B981).withOpacity(0.08);
                }
                if (isSelected && !isCorrectOption) {
                  optBorder = const Color(0xFFEF4444);
                  optBg = const Color(0xFFEF4444).withOpacity(0.08);
                }

                final hasOptionImage =
                    option.imageUrl != null && option.imageUrl!.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: optBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: optBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Status Icon for Option
                          if (isCorrectOption)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 18,
                            )
                          else if (isSelected)
                            const Icon(
                              Icons.cancel_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            )
                          else
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: subtitleColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          const SizedBox(width: 10),

                          // Option Text
                          Expanded(
                            child: Text(
                              option.text.isNotEmpty
                                  ? option.text
                                  : 'Option Image',
                              style: TextStyle(
                                color: optTextColor,
                                fontSize: 13,
                                fontWeight: isSelected || isCorrectOption
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),

                          // Option Badges (Selected / Correct)
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isCorrectOption
                                    ? const Color(0xFF10B981).withOpacity(0.15)
                                    : const Color(0xFFEF4444).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Selected',
                                style: TextStyle(
                                  color: isCorrectOption
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (isCorrectOption && !isSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Correct Answer',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (hasOptionImage) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            AppImageView.showFullScreenViewer(
                              context,
                              option.imageUrl!,
                              title: 'Option Image',
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              minHeight: 90,
                              maxHeight: 180,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: borderColor),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AppImageView(
                                  imageSource: option.imageUrl!,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.65),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in_rounded,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Zoom',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
