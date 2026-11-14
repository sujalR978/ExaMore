// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/create_classroom_dialog.dart';
import 'package:prep_mate/features/user/screens/all_exam_screen.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';

class Userhomescreen extends StatefulWidget {
  const Userhomescreen({super.key});

  @override
  State<Userhomescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Userhomescreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<List<ClassroomModel>>? _enrolledClassroomsStream;
  Stream<List<Map<String, dynamic>>>? _userAttemptsStream;
  Stream<List<ExamModel>>? _allExamsStream;

  String _studentClassroomId = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchStudentAdminAndInitStream();
  }

  /// Looks up the student's assigned instructor/admin ID & classroom details
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
        _studentClassroomId = (data['classroomId'] ?? '').toString().trim();
      }
    } catch (_) {}

    _enrolledClassroomsStream =
        ClassroomService.getStudentEnrolledClassroomsStream(
      studentUid: _currentUser.uid,
      currentClassroomId: _studentClassroomId,
    );

    _userAttemptsStream =
        _examService.getUserExamAttemptsStream(_currentUser.uid);

    _allExamsStream = _examService.getExamsStream(role: 'super_admin');

    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  void _showJoinClassroomDialog(BuildContext context) async {
    final codeController = TextEditingController();
    bool isSubmitting = false;

    // Auto-detect invitation link or code from clipboard
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text?.trim() ?? '';
      if (text.isNotEmpty &&
          (text.contains('CLA-') ||
              text.contains('code=') ||
              text.contains('EXM-'))) {
        codeController.text = text;
      }
    } catch (_) {}

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.school_outlined, color: Color(0xFF7C3AED)),
              SizedBox(width: 10),
              Text('Join a Classroom'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the Classroom Code or paste the invite link/message shared by your teacher.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. CLA-198 or paste invite link',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final input = codeController.text.trim();
                      if (input.isEmpty) return;
                      setDialogState(() => isSubmitting = true);
                      try {
                        final result = await ClassroomService.joinClassroom(
                          studentUid: _currentUser!.uid,
                          inputQuery: input,
                        );
                        if (!mounted) return;
                        Navigator.of(dialogCtx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Successfully joined ${result['adminName']}\'s classroom!',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                        _fetchStudentAdminAndInitStream();
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDarkMode
        ? const Color(0xFF0F0E17)
        : Colors.grey[100]!;
    final containerColor = isDarkMode ? const Color(0xFF1E1B4B) : Colors.white;
    final textColor = isDarkMode
        ? const Color(0xFFF8FAFC)
        : const Color(0xFF1E1B4B);
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    final displayName = _currentUser?.displayName ?? 'Student';

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'student_join_class_fab',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: () => _showJoinClassroomDialog(context),
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Join Classroom'),
      ),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: Builder(
              builder: (context) {
                final photoUrl = _currentUser?.photoURL;
                final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
                return CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15),
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                  child: !hasPhoto
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
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
              'ExaMore',
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Settingscreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoadingUser
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 36.0),
                child: CircularProgressIndicator(),
              ),
            )
          : StreamBuilder<List<ClassroomModel>>(
              stream: _enrolledClassroomsStream,
              builder: (context, classroomSnapshot) {
                final classrooms = classroomSnapshot.data ?? [];

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _userAttemptsStream,
                  builder: (context, attemptsSnapshot) {
                    final attempts = attemptsSnapshot.data ?? [];

                    return StreamBuilder<List<ExamModel>>(
                      stream: _allExamsStream,
                      builder: (context, examsSnapshot) {
                        final allExams = examsSnapshot.data ?? [];

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting
                              Text(
                                'Hi, $displayName!',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Your enrolled classrooms & assessments.',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Section Header
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Enrolled Classrooms',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (classrooms.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7C3AED)
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(100),
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
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _showJoinClassroomDialog(context),
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Join Class',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF7C3AED),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Enrolled Classrooms Grid (Google Classroom style, same as admin)
                              if (classrooms.isEmpty)
                                _buildEmptyEnrolledClassroomsState(
                                  isDarkMode: isDarkMode,
                                  containerColor: containerColor,
                                  borderColor: borderColor,
                                  subtitleColor: subtitleColor,
                                )
                              else
                                GridView.builder(
                                  physics:
                                      const NeverScrollableScrollPhysics(),
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
                                    return _buildGoogleClassroomStudentCard(
                                      classroom: classroom,
                                      cardIndex: index,
                                      allExams: allExams,
                                      attempts: attempts,
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

  /// Calculates points obtained, total possible points, and percentage for an enrolled classroom
  Map<String, dynamic> _computeClassroomMetrics({
    required ClassroomModel classroom,
    required List<ExamModel> allExams,
    required List<Map<String, dynamic>> attempts,
  }) {
    // 1. Find all exams belonging to this classroom
    final classroomExams = allExams.where((e) {
      if (e.classroomId != null && e.classroomId!.isNotEmpty) {
        return e.classroomId == classroom.id;
      }
      if (e.classroomName != null && e.classroomName!.isNotEmpty) {
        return e.classroomName!.trim().toLowerCase() ==
            classroom.name.trim().toLowerCase();
      }
      return false;
    }).toList();

    final classroomExamIds = classroomExams.map((e) => e.id).toSet();

    // 2. Find student's attempts for these exams
    final classroomAttempts = attempts.where((att) {
      final examId = (att['examId'] ?? '').toString();
      if (examId.isNotEmpty && classroomExamIds.contains(examId)) return true;
      final sub = att['submission'] as StudentSubmissionModel?;
      if (sub != null && classroomExamIds.contains(sub.id)) return true;
      return false;
    }).toList();

    // 3. For each unique exam given, pick the student's best attempt
    final Map<String, StudentSubmissionModel> bestAttemptPerExam = {};
    for (var att in classroomAttempts) {
      final sub = att['submission'] as StudentSubmissionModel?;
      if (sub == null) continue;
      final examKey =
          (att['examId'] != null && (att['examId'] as String).isNotEmpty)
              ? (att['examId'] as String)
              : sub.examTitle;
      if (!bestAttemptPerExam.containsKey(examKey) ||
          sub.marksObtained > bestAttemptPerExam[examKey]!.marksObtained) {
        bestAttemptPerExam[examKey] = sub;
      }
    }

    final int givenExamsCount = bestAttemptPerExam.length;
    final int totalClassroomExams = classroomExams.length;

    double totalMarksObtained = 0.0;
    double totalMarksPossible = 0.0;

    for (var sub in bestAttemptPerExam.values) {
      totalMarksObtained += sub.marksObtained;
      totalMarksPossible += (sub.totalMarks > 0 ? sub.totalMarks : 100.0);
    }

    int percentage = 0;
    if (totalMarksPossible > 0) {
      percentage =
          ((totalMarksObtained / totalMarksPossible) * 100).round().clamp(0, 100);
    }

    return {
      'givenExamsCount': givenExamsCount,
      'totalClassroomExams': totalClassroomExams,
      'marksObtained': totalMarksObtained,
      'totalMarks': totalMarksPossible,
      'percentage': percentage,
      'hasGivenExams': givenExamsCount > 0,
    };
  }

  /// Builds a Google Classroom square card with live % calculated from given exams & points
  Widget _buildGoogleClassroomStudentCard({
    required ClassroomModel classroom,
    required int cardIndex,
    required List<ExamModel> allExams,
    required List<Map<String, dynamic>> attempts,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final gradients = CreateClassroomDialog.themeGradients;
    int themeIdx = classroom.themeIndex;
    if (themeIdx <= 0) {
      themeIdx = (classroom.id.hashCode.abs() + cardIndex) % gradients.length;
    }
    final gradient = gradients[themeIdx % gradients.length];

    final metrics = _computeClassroomMetrics(
      classroom: classroom,
      allExams: allExams,
      attempts: attempts,
    );

    final int percentage = metrics['percentage'] as int;
    final int givenExamsCount = metrics['givenExamsCount'] as int;
    final int totalClassroomExams = metrics['totalClassroomExams'] as int;
    final double marksObtained = metrics['marksObtained'] as double;
    final double totalMarks = metrics['totalMarks'] as double;
    final bool hasGivenExams = metrics['hasGivenExams'] as bool;

    final String marksDisplay = totalMarks > 0
        ? '${marksObtained.truncateToDouble() == marksObtained ? marksObtained.toInt() : marksObtained.toStringAsFixed(1)} / ${totalMarks.toInt()} pts'
        : '0 pts';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AllExamsScreen(
              classroomId: classroom.id,
              classroomName: classroom.name,
            ),
          ),
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
                        Icons.school_rounded,
                        color: Colors.white.withOpacity(0.18),
                        size: 38,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          classroom.name,
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
                        if (classroom.section.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            classroom.section,
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
                        backgroundColor:
                            isDarkMode ? Colors.white10 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 60
                              ? const Color(0xFF10B981)
                              : (isDarkMode ? gradient[1] : gradient[0]),
                        ),
                        minHeight: 4,
                      ),
                    ),

                    // Exams count and subjects
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
                                ? '$givenExamsCount of $totalClassroomExams exams given'
                                : (totalClassroomExams > 0
                                    ? '$totalClassroomExams exam${totalClassroomExams > 1 ? 's' : ''} available'
                                    : (classroom.subjects.isNotEmpty
                                        ? classroom.subjects.first
                                        : 'No exams yet')),
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

  /// Empty state when student is not enrolled in any classroom
  Widget _buildEmptyEnrolledClassroomsState({
    required bool isDarkMode,
    required Color containerColor,
    required Color borderColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 44,
            color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No Classrooms Joined',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Join a classroom with the code or invite link from your instructor to access your assessments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showJoinClassroomDialog(context),
            icon: const Icon(Icons.login, size: 18),
            label: const Text('Join Classroom'),
          ),
        ],
      ),
    );
  }
}
