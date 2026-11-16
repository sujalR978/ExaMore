// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _examsStream = _examService.getExamsStream(role: 'super_admin');
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

                // Tests List - ONLY showing Title and Time (NO tags like Easy, Subject name, mcq count)
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ExamdetailPage(exam: exam),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
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
                            // Clean Time Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF7C3AED),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),

                            // ONLY Title & Time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Trailing Arrow
                            Icon(
                              Icons.chevron_right_rounded,
                              color: subtitleColor,
                              size: 22,
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
      ),
    );
  }
}
