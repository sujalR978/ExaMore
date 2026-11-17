// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';

class SubjectTestsScreen extends StatefulWidget {
  final String subjectName;
  final String? classroomId;
  final String? classroomName;
  final List<ExamModel>? initialExams;
  final List<Color>? gradient;

  const SubjectTestsScreen({
    super.key,
    required this.subjectName,
    this.classroomId,
    this.classroomName,
    this.initialExams,
    this.gradient,
  });

  @override
  State<SubjectTestsScreen> createState() => _SubjectTestsScreenState();
}

class _SubjectTestsScreenState extends State<SubjectTestsScreen> {
  final ExamService _examService = ExamService();
  Stream<List<ExamModel>>? _examsStream;
  Stream<List<Map<String, dynamic>>>? _userAttemptsStream;

  @override
  void initState() {
    super.initState();
    _examsStream = _examService.getExamsStream(role: 'super_admin');
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _userAttemptsStream = _examService.getUserExamAttemptsStream(uid);
  }

  List<ExamModel> _filterExams(List<ExamModel> allExams) {
    return allExams.where((e) {
      // Must match classroom if specified
      if (widget.classroomId != null && widget.classroomId!.isNotEmpty) {
        if (e.classroomId != null && e.classroomId!.isNotEmpty) {
          if (e.classroomId != widget.classroomId) return false;
        } else if (widget.classroomName != null &&
            widget.classroomName!.isNotEmpty) {
          if (e.classroomName?.trim().toLowerCase() !=
              widget.classroomName!.trim().toLowerCase()) {
            return false;
          }
        }
      }

      // Must match subject
      return e.category.trim().toLowerCase() ==
          widget.subjectName.trim().toLowerCase();
    }).toList();
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
            Flexible(
              child: Text(
                widget.subjectName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: _examsStream,
        builder: (context, snapshot) {
          List<ExamModel> exams;
          if (snapshot.hasData && snapshot.data != null) {
            exams = _filterExams(snapshot.data!);
          } else if (widget.initialExams != null) {
            exams = widget.initialExams!;
          } else {
            exams = [];
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              exams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (exams.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        size: 40,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Tests Available',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There are currently no tests published for ${widget.subjectName}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userAttemptsStream,
            builder: (context, attemptSnapshot) {
              final allAttempts = attemptSnapshot.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Header
                    Row(
                      children: [
                        Text(
                          'Available Tests',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '${exams.length}',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tests List with Attempt & Mark Indications
                    ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: exams.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final exam = exams[index];

                        // Find attempts made for this exam
                        final attemptsForExam = allAttempts
                            .where((a) => a['examId'] == exam.id)
                            .toList();

                        final bool isAttempted = attemptsForExam.isNotEmpty;
                        final bool isClosed = exam.isClosed;
                        final bool isScheduled = exam.isScheduled;

                        // Calculate highest score if attempted
                        double highestScore = 0.0;
                        if (isAttempted) {
                          for (var a in attemptsForExam) {
                            final sub =
                                a['submission'] as StudentSubmissionModel;
                            if (sub.marksObtained > highestScore) {
                              highestScore = sub.marksObtained;
                            }
                          }
                        }

                        final totalMarksStr =
                            (exam.totalMarks.truncateToDouble() ==
                                    exam.totalMarks)
                                ? exam.totalMarks.toInt().toString()
                                : exam.totalMarks.toStringAsFixed(0);

                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExamdetailPage(exam: exam),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: containerColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isAttempted
                                    ? const Color(0xFF10B981).withOpacity(0.3)
                                    : (isClosed
                                        ? const Color(0xFFEF4444)
                                            .withOpacity(0.3)
                                        : borderColor),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDarkMode ? 0.2 : 0.03,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Clean Status Icon
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAttempted
                                        ? const Color(0xFF10B981)
                                            .withOpacity(0.12)
                                        : (isClosed
                                            ? const Color(0xFFEF4444)
                                                .withOpacity(0.12)
                                            : const Color(0xFF7C3AED)
                                                .withOpacity(0.12)),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isAttempted
                                        ? Icons.check_circle_rounded
                                        : (isClosed
                                            ? Icons.event_busy_rounded
                                            : Icons.access_time_rounded),
                                    color: isAttempted
                                        ? const Color(0xFF10B981)
                                        : (isClosed
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF7C3AED)),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title & Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          height: 1.25,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: subtitleColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${exam.durationMinutes} mins',
                                            style: TextStyle(
                                              color: subtitleColor,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (exam.endDate != null) ...[
                                            const SizedBox(width: 8),
                                            Text(
                                              '•',
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                isClosed
                                                    ? 'Closed'
                                                    : 'Closes ${DateFormat('MMM d, h:mm a').format(exam.endDate!)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isClosed
                                                      ? const Color(0xFFEF4444)
                                                      : subtitleColor,
                                                  fontSize: 11.5,
                                                  fontWeight: isClosed
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Marks / Attempt Status Badge
                                if (isAttempted) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF10B981),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(highestScore.truncateToDouble() == highestScore) ? highestScore.toInt().toString() : highestScore.toStringAsFixed(1)}/$totalMarksStr',
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (isClosed) ...[
                                  // Closed & not attempted -> 0 / Total marks
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      '0/$totalMarksStr',
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ] else if (isScheduled) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Scheduled',
                                      style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Not Given',
                                      style: TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(width: 8),

                                // Trailing Arrow
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: subtitleColor,
                                  size: 20,
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
            },
          );
        },
      ),
    );
  }
}
