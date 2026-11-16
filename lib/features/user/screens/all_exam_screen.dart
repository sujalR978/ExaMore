// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/create_classroom_dialog.dart';
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';
import 'package:prep_mate/features/user/widgets/exam_list_widget.dart';

class AllExamsScreen extends StatefulWidget {
  final String? initialCategory;
  final String? classroomId;
  final String? classroomName;

  const AllExamsScreen({
    super.key,
    this.initialCategory,
    this.classroomId,
    this.classroomName,
  });

  @override
  State<AllExamsScreen> createState() => _AllExamsScreenState();
}

class _AllExamsScreenState extends State<AllExamsScreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;
  Stream<List<ExamModel>>? _allExamsStream;
  Stream<List<Map<String, dynamic>>>? _userAttemptsStream;
  Stream<ClassroomModel?>? _singleClassroomStream;
  Stream<List<ClassroomModel>>? _enrolledClassroomsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _allExamsStream = _examService.getExamsStream(role: 'super_admin');
    _userAttemptsStream = _examService.getUserExamAttemptsStream(
      _currentUser.uid,
    );

    if (widget.classroomId != null && widget.classroomId!.isNotEmpty) {
      _singleClassroomStream = ClassroomService.getSingleClassroomStream(
        widget.classroomId!,
      );
    } else {
      _enrolledClassroomsStream =
          ClassroomService.getStudentEnrolledClassroomsStream(
            studentUid: _currentUser.uid,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  /// Calculates points obtained, total possible points, and percentage for a specific subject
  Map<String, dynamic> _computeSubjectMetrics({
    required String subjectName,
    required String? classroomId,
    required String? classroomName,
    required List<ExamModel> allExams,
    required List<Map<String, dynamic>> attempts,
  }) {
    // 1. Filter all exams for this subject belonging to the classroom
    final subjectExams = allExams.where((e) {
      if (classroomId != null && classroomId.isNotEmpty) {
        if (e.classroomId != null && e.classroomId!.isNotEmpty) {
          if (e.classroomId != classroomId) return false;
        } else if (classroomName != null && classroomName.isNotEmpty) {
          if (e.classroomName?.trim().toLowerCase() !=
              classroomName.trim().toLowerCase()) {
            return false;
          }
        }
      }

      return e.category.trim().toLowerCase() ==
          subjectName.trim().toLowerCase();
    }).toList();

    final subjectExamIds = subjectExams.map((e) => e.id).toSet();

    // 2. Map student's best attempt for each exam in this subject
    final Map<String, StudentSubmissionModel> bestAttemptPerExam = {};
    for (var att in attempts) {
      final sub = att['submission'] as StudentSubmissionModel?;
      if (sub == null) continue;
      final examId = (att['examId'] ?? '').toString();
      final matchesId = examId.isNotEmpty && subjectExamIds.contains(examId);
      final matchesSub = subjectExamIds.contains(sub.id);

      if (matchesId || matchesSub) {
        final key = examId.isNotEmpty ? examId : sub.examTitle;
        if (!bestAttemptPerExam.containsKey(key) ||
            sub.marksObtained > bestAttemptPerExam[key]!.marksObtained) {
          bestAttemptPerExam[key] = sub;
        }
      }
    }

    final int givenExamsCount = bestAttemptPerExam.length;
    final int totalSubjectExams = subjectExams.length;

    double marksObtained = 0.0;
    double totalMarks = 0.0;

    for (var sub in bestAttemptPerExam.values) {
      marksObtained += sub.marksObtained;
      totalMarks += (sub.totalMarks > 0 ? sub.totalMarks : 100.0);
    }

    int percentage = 0;
    if (totalMarks > 0) {
      percentage = ((marksObtained / totalMarks) * 100).round().clamp(0, 100);
    }

    return {
      'percentage': percentage,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'givenExamsCount': givenExamsCount,
      'totalSubjectExams': totalSubjectExams,
      'hasGivenExams': givenExamsCount > 0,
      'exams': subjectExams,
    };
  }

  void _showSubjectExamsModal({
    required BuildContext context,
    required String subjectName,
    required List<ExamModel> subjectExams,
    required List<Color> gradient,
    required bool isDarkMode,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_books_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${subjectExams.length} Assessment${subjectExams.length == 1 ? '' : 's'} Available',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: subtitleColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(color: borderColor, height: 24),

              // Exams List
              Flexible(
                child: subjectExams.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 24,
                        ),
                        child: Center(
                          child: Text(
                            'No published assessments available for $subjectName yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        shrinkWrap: true,
                        itemCount: subjectExams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exam = subjectExams[index];
                          final difficulty = _calculateDifficulty(exam);
                          return ExamListItemWidget(
                            title: exam.title,
                            category: exam.category,
                            time: '${exam.durationMinutes} mins',
                            mcqs: '${exam.questions.length} MCQs',
                            difficulty: difficulty,
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExamdetailPage(exam: exam),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _calculateDifficulty(ExamModel exam) {
    if (exam.passingScorePercentage >= 75 || exam.durationMinutes >= 120) {
      return 'Hard';
    } else if (exam.passingScorePercentage >= 50) {
      return 'Medium';
    }
    return 'Easy';
  }

  /// Builds a Subject Card styled identically to the Home Screen Google Classroom card
  Widget _buildSubjectCard({
    required BuildContext context,
    required String subjectName,
    required String subSectionText,
    required int cardIndex,
    required List<Color> gradient,
    required Map<String, dynamic> metrics,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final int percentage = metrics['percentage'] as int;
    final int givenExamsCount = metrics['givenExamsCount'] as int;
    final int totalSubjectExams = metrics['totalSubjectExams'] as int;
    final double marksObtained = metrics['marksObtained'] as double;
    final double totalMarks = metrics['totalMarks'] as double;
    final bool hasGivenExams = metrics['hasGivenExams'] as bool;
    final List<ExamModel> subjectExams =
        metrics['exams'] as List<ExamModel>? ?? [];

    final String marksDisplay = totalMarks > 0
        ? '${marksObtained.truncateToDouble() == marksObtained ? marksObtained.toInt() : marksObtained.toStringAsFixed(1)} / ${totalMarks.toInt()} pts'
        : '0 pts';

    return InkWell(
      onTap: () {
        _showSubjectExamsModal(
          context: context,
          subjectName: subjectName,
          subjectExams: subjectExams,
          gradient: gradient,
          isDarkMode: isDarkMode,
          containerColor: surfaceColor,
          textColor: textColor,
          subtitleColor: subtitleColor,
          borderColor: borderColor,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Theme Gradient Banner (~48% of height)
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Icon(
                        Icons.book_rounded,
                        color: Colors.white.withOpacity(0.18),
                        size: 38,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (subSectionText.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subSectionText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Card Body (Lower ~52% of height)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Score % & Points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          hasGivenExams ? '$percentage%' : '0%',
                          style: TextStyle(
                            color: isDarkMode ? gradient[1] : gradient[0],
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            marksDisplay,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (percentage / 100).clamp(0.0, 1.0),
                        backgroundColor: isDarkMode
                            ? Colors.white10
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 60
                              ? const Color(0xFF10B981)
                              : (isDarkMode ? gradient[1] : gradient[0]),
                        ),
                        minHeight: 4,
                      ),
                    ),

                    // Exams count
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 11,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasGivenExams
                                ? '$givenExamsCount of $totalSubjectExams given'
                                : (totalSubjectExams > 0
                                      ? '$totalSubjectExams available'
                                      : 'No exams yet'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

    final String screenTitle = widget.classroomName != null &&
            widget.classroomName!.isNotEmpty
        ? widget.classroomName!
        : 'Enrolled Subjects';

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
                Icons.school_rounded,
                color: Color(0xFF7C3AED),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              screenTitle,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<ExamModel>>(
              stream: _allExamsStream,
              builder: (context, examSnap) {
                final allExams = examSnap.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _userAttemptsStream,
                  builder: (context, attemptSnap) {
                    final attempts = attemptSnap.data ?? [];

                    // Case A: Specific Classroom Screen
                    if (widget.classroomId != null &&
                        widget.classroomId!.isNotEmpty) {
                      return StreamBuilder<ClassroomModel?>(
                        stream: _singleClassroomStream,
                        builder: (context, classroomSnap) {
                          if (classroomSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final classroom = classroomSnap.data;
                          if (classroom == null) {
                            return Center(
                              child: Text(
                                'Classroom not found.',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }

                          // Collect all distinct subjects from classroom and classroom exams
                          final classroomExams = allExams.where((e) {
                            if (e.classroomId != null &&
                                e.classroomId!.isNotEmpty) {
                              return e.classroomId == classroom.id;
                            }
                            if (e.classroomName != null &&
                                e.classroomName!.isNotEmpty) {
                              return e.classroomName!.trim().toLowerCase() ==
                                  classroom.name.trim().toLowerCase();
                            }
                            return false;
                          }).toList();

                          final Set<String> distinctSubjects = {
                            ...classroom.subjects.map((s) => s.trim()),
                          };
                          for (var e in classroomExams) {
                            if (e.category.trim().isNotEmpty) {
                              distinctSubjects.add(e.category.trim());
                            }
                          }
                          final List<String> subjectsList =
                              distinctSubjects.where((s) => s.isNotEmpty).toList();

                          if (subjectsList.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'No subjects found in ${classroom.name}.',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          }

                          final gradients = CreateClassroomDialog.themeGradients;

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section header
                                Row(
                                  children: [
                                    Text(
                                      'Subjects',
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
                                        color: const Color(
                                          0xFF7C3AED,
                                        ).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                      ),
                                      child: Text(
                                        '${subjectsList.length}',
                                        style: const TextStyle(
                                          color: Color(0xFF7C3AED),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Grid of subject cards
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.02,
                                  ),
                                  itemCount: subjectsList.length,
                                  itemBuilder: (context, index) {
                                    final subject = subjectsList[index];
                                    final gradient =
                                        gradients[index % gradients.length];
                                    final metrics = _computeSubjectMetrics(
                                      subjectName: subject,
                                      classroomId: classroom.id,
                                      classroomName: classroom.name,
                                      allExams: allExams,
                                      attempts: attempts,
                                    );

                                    return _buildSubjectCard(
                                      context: context,
                                      subjectName: subject,
                                      subSectionText: classroom.name,
                                      cardIndex: index,
                                      gradient: gradient,
                                      metrics: metrics,
                                      isDarkMode: isDarkMode,
                                      surfaceColor: containerColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      subtitleColor: subtitleColor,
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    // Case B: General View (all enrolled classrooms)
                    return StreamBuilder<List<ClassroomModel>>(
                      stream: _enrolledClassroomsStream,
                      builder: (context, classroomListSnap) {
                        if (classroomListSnap.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final classrooms = classroomListSnap.data ?? [];
                        if (classrooms.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                'No enrolled subjects or classrooms found.',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        }

                        final gradients = CreateClassroomDialog.themeGradients;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Enrolled Subjects',
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
                                      color: const Color(
                                        0xFF7C3AED,
                                      ).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      '${classrooms.length}',
                                      style: const TextStyle(
                                        color: Color(0xFF7C3AED),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.02,
                                ),
                                itemCount: classrooms.length,
                                itemBuilder: (context, index) {
                                  final classroom = classrooms[index];
                                  final gradient =
                                      gradients[index % gradients.length];
                                  final metrics = _computeSubjectMetrics(
                                    subjectName: classroom.subjects.isNotEmpty
                                        ? classroom.subjects.first
                                        : classroom.name,
                                    classroomId: classroom.id,
                                    classroomName: classroom.name,
                                    allExams: allExams,
                                    attempts: attempts,
                                  );

                                  return _buildSubjectCard(
                                    context: context,
                                    subjectName: classroom.name,
                                    subSectionText: classroom.section,
                                    cardIndex: index,
                                    gradient: gradient,
                                    metrics: metrics,
                                    isDarkMode: isDarkMode,
                                    surfaceColor: containerColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
