// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/widgets/offline_banner.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/create_classroom_dialog.dart';
import 'package:prep_mate/features/user/screens/all_exam_screen.dart';
import 'package:prep_mate/features/user/screens/student_notifications_screen.dart';
import 'package:prep_mate/features/user/navigation/main_navigator.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';

class Userhomescreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  const Userhomescreen({super.key, this.onNavigateToTab});

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
  String _assignedAdminId = '';
  String _userName = '';
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
        _userName = (data['name'] ?? data['fullName'] ?? '').toString().trim();
        _assignedAdminId = (data['adminId'] ?? '').toString().trim();
        NotificationService.instance.subscribeStudentTopics(
          studentClassroomId: _studentClassroomId,
          adminId: _assignedAdminId,
        );
      }
    } catch (_) {}

    _enrolledClassroomsStream =
        ClassroomService.getStudentEnrolledClassroomsStream(
          studentUid: _currentUser.uid,
          currentClassroomId: _studentClassroomId,
        );

    _userAttemptsStream = _examService.getUserExamAttemptsStream(
      _currentUser.uid,
    );

    _allExamsStream = _examService.getExamsStream(
      adminId: _assignedAdminId.isNotEmpty ? _assignedAdminId : null,
      role: _assignedAdminId.isNotEmpty ? 'admin' : 'super_admin',
    );

    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  void _showJoinClassroomDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final inputFill = isDark ? const Color(0xFF192132) : const Color(0xFFF1F5F9);
    final inputBorder = isDark ? const Color(0xFF2E384D) : const Color(0xFFE2E8F0);

    final codeController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: borderColor,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.55 : 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Join a Classroom',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Enter the classroom code or paste the invite link shared by your instructor.',
                  style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: codeController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. CLA-123',
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14),
                    prefixIcon: Icon(Icons.vpn_key_outlined, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 18),
                    filled: true,
                    fillColor: inputFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF192132) : const Color(0xFFF1F5F9),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
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
                                    content: Text(
                                      e.toString().replaceAll('Exception: ', ''),
                                    ),
                                    backgroundColor: const Color(0xFFEF4444),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0F172A),
                              ),
                            )
                          : const Text(
                              'Join',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isDarkMode = isDark;

    final String displayName = _userName.isNotEmpty
        ? _userName
        : (_currentUser?.displayName?.isNotEmpty == true
              ? _currentUser!.displayName!
              : (_currentUser?.email?.isNotEmpty == true
                    ? _currentUser!.email!.split('@').first
                    : 'Student'));

    final String firstLetter = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'S';

    final bgColor = AppColors.background(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'student_join_class_fab',
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 4,
        onPressed: () => _showJoinClassroomDialog(context),
        icon: const Icon(Icons.add, size: 20, color: Color(0xFF0F172A)),
        label: const Text(
          'Join Classroom',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
            tooltip: 'Search',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AllExamsScreen()),
              );
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _currentUser != null
                ? NotificationService.instance
                    .getUserNotificationsStream(_currentUser.uid)
                : const Stream.empty(),
            builder: (context, notifSnapshot) {
              final notifications = notifSnapshot.data ?? [];
              final unreadCount =
                  notifications.where((n) => n['isRead'] == false).length;

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Color(0xFF94A3B8),
                    ),
                    tooltip: 'Notifications',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const StudentNotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14.0, left: 6),
            child: GestureDetector(
              onTap: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(3);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigator(initialIndex: 3),
                    ),
                  );
                }
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4C1D95),
                ),
                alignment: Alignment.center,
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator())
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

                        // Calculate overall stats
                        final int classroomsCount = classrooms.length;
                        final int examsTakenCount = attempts.length;
                        double totalPercentSum = 0;
                        for (var att in attempts) {
                          final sub = att['submission'] as StudentSubmissionModel?;
                          if (sub != null) {
                            totalPercentSum += sub.scorePercentage;
                          }
                        }
                        final double avgScore = examsTakenCount > 0
                            ? (totalPercentSum / examsTakenCount)
                            : 0;

                        return RefreshIndicator(
                          onRefresh: () async {
                            await _fetchStudentAdminAndInitStream();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                OfflineBanner(
                                  onRetry: () => _fetchStudentAdminAndInitStream(),
                                ),
                                const SizedBox(height: 12),
                                // Four Quick Stats Cards arranged in responsive 2x2 grid (Classrooms, Exams Taken, Avg. Score, Progress)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildHomeMetricCard(
                                        icon: Icons.layers_outlined,
                                        iconColor: const Color(0xFFA78BFA),
                                        value: '$classroomsCount',
                                        label: 'Classrooms',
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildHomeMetricCard(
                                        icon: Icons.assignment_outlined,
                                        iconColor: const Color(0xFFA78BFA),
                                        value: '$examsTakenCount',
                                        label: 'Exams Taken',
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildHomeMetricCard(
                                        icon: Icons.emoji_events_outlined,
                                        iconColor: const Color(0xFFF59E0B),
                                        value: examsTakenCount > 0
                                            ? '${avgScore.toInt()}%'
                                            : '-',
                                        label: 'Avg. Score',
                                        isDark: isDark,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildHomeMetricCard(
                                        icon: Icons.trending_up_rounded,
                                        iconColor: const Color(0xFF34D399),
                                        value: examsTakenCount > 0
                                            ? '${avgScore.toInt()}%'
                                            : '0%',
                                        label: 'Progress',
                                        isDark: isDark,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Section: Enrolled Classrooms
                                if (classrooms.isNotEmpty) ...[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Enrolled Classrooms',
                                        style: TextStyle(
                                          color: textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED).withOpacity(0.18),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${classrooms.length}',
                                          style: const TextStyle(
                                            color: Color(0xFFA78BFA),
                                            fontSize: 11,
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
                                          childAspectRatio: 1.05,
                                        ),
                                    itemCount: classrooms.length,
                                    itemBuilder: (context, index) {
                                      final classroom = classrooms[index];
                                      return _buildGoogleClassroomStudentCard(
                                        classroom: classroom,
                                        cardIndex: index,
                                        allExams: allExams,
                                        attempts: attempts,
                                        isDarkMode: isDark,
                                        surfaceColor: cardColor,
                                        borderColor: borderColor,
                                        textColor: textPrimary,
                                        subtitleColor: textSecondary,
                                      );
                                    },
                                  ),
                                ] else ...[
                                  _buildEmptyEnrolledClassroomsState(
                                    isDarkMode: isDark,
                                    containerColor: cardColor,
                                    borderColor: borderColor,
                                    subtitleColor: textSecondary,
                                  ),
                                ],
                              ],
                            ),
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

  Widget _buildHomeMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
      percentage = ((totalMarksObtained / totalMarksPossible) * 100)
          .round()
          .clamp(0, 100);
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
              Icons.school_outlined,
              size: 44,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Classrooms Joined',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Join a classroom with the code or invite link from your instructor to access your assessments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () => _showJoinClassroomDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Join Classroom',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
