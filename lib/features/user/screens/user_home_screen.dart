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
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/user/widgets/exam_card_widget.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';

class Userhomescreen extends StatefulWidget {
  const Userhomescreen({super.key});

  @override
  State<Userhomescreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Userhomescreen> {
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<ClassroomModel?>? _classroomStream;
  Stream<List<Map<String, dynamic>>>? _userAttemptsStream;
  Stream<List<ExamModel>>? _publishedExamsStream;
  late final Stream<List> _savedExamsStream;

  String _assignedAdminId = '';
  String _instructorName = '';
  String _studentClassroomId = '';
  String _classroomName = '';
  String _classroomSection = '';
  List<String> _enrolledSubjects = [];
  String? _selectedSubjectFilter;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    final uid = _currentUser?.uid ?? '';
    _savedExamsStream = _examService.getSavedExamsStream(uid);

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
        _assignedAdminId = (data['adminId'] ?? '').toString().trim();
        _studentClassroomId = (data['classroomId'] ?? '').toString().trim();

        if (_assignedAdminId.isNotEmpty) {
          final adminDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_assignedAdminId)
              .get();
          if (adminDoc.exists) {
            _instructorName =
                (adminDoc.data()?['name'] ?? 'Instructor').toString();
          }
        } else {
          _instructorName = '';
        }

        if (_studentClassroomId.isNotEmpty) {
          final classDoc = await FirebaseFirestore.instance
              .collection('classrooms')
              .doc(_studentClassroomId)
              .get();
          if (classDoc.exists) {
            final cData = classDoc.data() ?? {};
            _classroomName = (cData['name'] ?? '').toString();
            _classroomSection = (cData['section'] ?? '').toString();
            _enrolledSubjects = List<String>.from(cData['subjects'] ?? []);
          }
        } else {
          _classroomName = '';
          _classroomSection = '';
          _enrolledSubjects = [];
        }
      }
    } catch (_) {}

    _userAttemptsStream =
        _examService.getUserExamAttemptsStream(_currentUser.uid);

    if (_studentClassroomId.isNotEmpty) {
      _classroomStream =
          ClassroomService.getSingleClassroomStream(_studentClassroomId);
      _publishedExamsStream = _examService.getPublishedExamsStream(
        adminId: _assignedAdminId,
        classroomId: _studentClassroomId,
        enrolledSubjects: _enrolledSubjects,
        role: 'student',
      );
    } else {
      _classroomStream = Stream.value(null);
      _publishedExamsStream = Stream.value(<ExamModel>[]);
    }

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

  void _handleViewAll(BuildContext context, {String? initialCategory}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllExamsScreen(initialCategory: initialCategory),
      ),
    );
  }

  void _handleViewDetails(BuildContext context, ExamModel exam) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)));
  }

  Future<void> _handleBookmarkToggle(ExamModel exam, String userId) async {
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save exams.')),
      );
      return;
    }

    try {
      final isSaved = await _examService.toggleSaveExam(
        userId: userId,
        exam: exam,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSaved ? 'Exam saved to bookmarks!' : 'Removed from bookmarks.',
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update bookmark: $e')));
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science_outlined;
      case 'mathematics':
      case 'math':
        return Icons.calculate_outlined;
      case 'history':
        return Icons.history_edu_outlined;
      case 'computer science':
        return Icons.computer_outlined;
      case 'literature':
        return Icons.auto_stories_outlined;
      default:
        return Icons.assignment_outlined;
    }
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

    final userId = _currentUser?.uid ?? '';
    final displayName = _currentUser?.displayName ?? 'Student';

    return Scaffold(
      backgroundColor: backgroundColor,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Hi, $displayName!',
              style: TextStyle(
                color: textColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready for your next challenge? Your assessments await.',
              style: TextStyle(color: subtitleColor, fontSize: 13.5),
            ),
            const SizedBox(height: 16),

            // Classroom Enrollment Status Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentClassroomId.isNotEmpty
                              ? (_classroomName.isNotEmpty
                                  ? _classroomName
                                  : 'Enrolled Classroom')
                              : "No Classroom Linked",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.white
                                : const Color(0xFF1E1B4B),
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _studentClassroomId.isNotEmpty
                              ? "${_classroomSection.isNotEmpty ? '$_classroomSection • ' : ''}${_instructorName.isNotEmpty ? 'Teacher: $_instructorName' : 'Active Assessment Cohort'}"
                              : "Enter a code or invite link to join your class.",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF6D28D9),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showJoinClassroomDialog(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      _studentClassroomId.isNotEmpty ? "Change" : "+ Join Class",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Real-time Enrolled Subjects & Scoped Exams
            _isLoadingUser
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 36.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : StreamBuilder<ClassroomModel?>(
                    stream: _classroomStream,
                    builder: (context, classroomSnapshot) {
                      final classroom = classroomSnapshot.data;
                      if (classroom != null) {
                        _classroomName = classroom.name;
                        _classroomSection = classroom.section;
                        _enrolledSubjects = classroom.subjects;
                      }
                      final subjects = _enrolledSubjects;
                      final isEnrolled =
                          _studentClassroomId.isNotEmpty && subjects.isNotEmpty;

                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _userAttemptsStream,
                        builder: (context, attemptsSnapshot) {
                          final attempts = attemptsSnapshot.data ?? [];

                          return StreamBuilder<List<ExamModel>>(
                            stream: _publishedExamsStream,
                            builder: (context, examsSnapshot) {
                              final allExams = examsSnapshot.data ?? [];

                              // Strictly scope to enrolled subjects only
                              final enrolledLower = subjects
                                  .map((s) => s.trim().toLowerCase())
                                  .toSet();
                              final validEnrolledExams = isEnrolled
                                  ? allExams
                                      .where(
                                        (e) => enrolledLower.contains(
                                          e.category.trim().toLowerCase(),
                                        ),
                                      )
                                      .toList()
                                  : <ExamModel>[];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Enrolled Subjects Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Enrolled Subjects',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (subjects.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                '${subjects.length}',
                                                style: const TextStyle(
                                                  color: Color(0xFF7C3AED),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (_selectedSubjectFilter != null)
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            foregroundColor:
                                                const Color(0xFF7C3AED),
                                          ),
                                          onPressed: () {
                                            setState(() =>
                                                _selectedSubjectFilter = null);
                                          },
                                          icon: const Icon(Icons.close,
                                              size: 14),
                                          label: const Text(
                                            'Clear filter',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 2. Subject Cards Grid (styled same as Admin Google Classroom cards)
                                  if (!isEnrolled)
                                    _buildEmptyEnrolledSubjectsState(
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
                                        childAspectRatio: 1.05,
                                      ),
                                      itemCount: subjects.length,
                                      itemBuilder: (context, index) {
                                        final subject = subjects[index];
                                        return _buildEnrolledSubjectCard(
                                          subject: subject,
                                          cardIndex: index,
                                          classroomName: _classroomName,
                                          classroomSection: _classroomSection,
                                          allExams: validEnrolledExams,
                                          attempts: attempts,
                                          isSelected:
                                              _selectedSubjectFilter == subject,
                                          isDarkMode: isDarkMode,
                                          surfaceColor: containerColor,
                                          borderColor: borderColor,
                                          textColor: textColor,
                                          subtitleColor: subtitleColor,
                                        );
                                      },
                                    ),

                                  const SizedBox(height: 26),

                                  // 3. Available Exams Header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedSubjectFilter != null
                                                ? 'Exams in $_selectedSubjectFilter'
                                                : 'Available Exams',
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_selectedSubjectFilter != null)
                                            Text(
                                              'Filtered by selected subject',
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (isEnrolled &&
                                          validEnrolledExams.isNotEmpty)
                                        TextButton(
                                          onPressed: () => _handleViewAll(
                                            context,
                                            initialCategory:
                                                _selectedSubjectFilter,
                                          ),
                                          child: Row(
                                            children: [
                                              Text(
                                                'View All',
                                                style: TextStyle(
                                                  color: isDarkMode
                                                      ? const Color(0xFFFBBF24)
                                                      : const Color(0xFFB45309),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 16,
                                                color: isDarkMode
                                                    ? const Color(0xFFFBBF24)
                                                    : const Color(0xFFB45309),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // 4. Exams List (Strictly obeys: Do not show exams without enrolling for that subject)
                                  if (!isEnrolled)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 24,
                                      ),
                                      decoration: BoxDecoration(
                                        color: containerColor,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No exams available.\nYou must be enrolled in a classroom with subjects to view assessments.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: subtitleColor,
                                            fontSize: 13.5,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    )
                                  else ...[
                                    Builder(
                                      builder: (context) {
                                        final filteredExams =
                                            _selectedSubjectFilter != null
                                                ? validEnrolledExams
                                                    .where(
                                                      (e) =>
                                                          e.category
                                                              .trim()
                                                              .toLowerCase() ==
                                                          _selectedSubjectFilter!
                                                              .trim()
                                                              .toLowerCase(),
                                                    )
                                                    .toList()
                                                : validEnrolledExams;

                                        if (filteredExams.isEmpty) {
                                          return Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: containerColor,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: borderColor),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _selectedSubjectFilter != null
                                                    ? 'No published exams found for "$_selectedSubjectFilter".'
                                                    : 'No exams published yet for your enrolled subjects.\nPlease check back later!',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: subtitleColor,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return StreamBuilder<List>(
                                          stream: _savedExamsStream,
                                          builder: (context, savedSnapshot) {
                                            final savedIds =
                                                (savedSnapshot.data ?? [])
                                                    .map((item) =>
                                                        (item['exam']
                                                                as ExamModel)
                                                            .id)
                                                    .toSet();

                                            final displayExams =
                                                filteredExams.take(4).toList();

                                            return ListView.separated(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemCount: displayExams.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 14),
                                              itemBuilder: (context, index) {
                                                final exam =
                                                    displayExams[index];
                                                final isBookmarked =
                                                    savedIds.contains(exam.id);

                                                final isScience = exam.category
                                                        .toLowerCase()
                                                        .contains('sci') ||
                                                    exam.category
                                                        .toLowerCase()
                                                        .contains('bio') ||
                                                    exam.category
                                                        .toLowerCase()
                                                        .contains('chem');

                                                final badgeBg = isScience
                                                    ? (isDarkMode
                                                        ? const Color(
                                                            0xFF2E2A72)
                                                        : const Color(
                                                            0xFFDBEAFE))
                                                    : (isDarkMode
                                                        ? const Color(
                                                            0xFF451A03)
                                                        : const Color(
                                                            0xFFFEF3C7));

                                                final badgeText = isScience
                                                    ? (isDarkMode
                                                        ? const Color(
                                                            0xFF93C5FD)
                                                        : const Color(
                                                            0xFF1D4ED8))
                                                    : (isDarkMode
                                                        ? const Color(
                                                            0xFFFCD34D)
                                                        : const Color(
                                                            0xFFB45309));

                                                return ExamCard(
                                                  badgeText:
                                                      exam.category.toUpperCase(),
                                                  badgeColor: badgeBg,
                                                  badgeTextColor: badgeText,
                                                  title: exam.title,
                                                  time:
                                                      '${exam.durationMinutes} mins',
                                                  mcqs:
                                                      '${exam.questions.length} MCQs',
                                                  icon: _getCategoryIcon(
                                                      exam.category),
                                                  isDarkMode: isDarkMode,
                                                  containerColor: containerColor,
                                                  textColor: textColor,
                                                  subtitleColor: subtitleColor,
                                                  borderColor: borderColor,
                                                  isBookmarked: isBookmarked,
                                                  onBookmarkToggle: () =>
                                                      _handleBookmarkToggle(
                                                          exam, userId),
                                                  onViewDetails: () =>
                                                      _handleViewDetails(
                                                          context, exam),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Calculates points obtained, total possible points, and percentage for an enrolled subject
  Map<String, dynamic> _computeSubjectMetrics({
    required String subject,
    required List<ExamModel> allExams,
    required List<Map<String, dynamic>> attempts,
  }) {
    final lowerSubject = subject.trim().toLowerCase();

    // 1. Find all exams belonging to this subject
    final subjectExams = allExams.where(
      (e) => e.category.trim().toLowerCase() == lowerSubject,
    ).toList();

    final subjectExamIds = subjectExams.map((e) => e.id).toSet();

    // 2. Find student's attempts for this subject
    final subjectAttempts = attempts.where((att) {
      final examId = (att['examId'] ?? '').toString();
      if (examId.isNotEmpty && subjectExamIds.contains(examId)) return true;
      final cat = (att['category'] ?? att['subject'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      if (cat.isNotEmpty && cat == lowerSubject) return true;
      final sub = att['submission'] as StudentSubmissionModel?;
      if (sub != null && subjectExamIds.contains(sub.id)) return true;
      return false;
    }).toList();

    // 3. For each unique exam given, pick the student's best attempt
    final Map<String, StudentSubmissionModel> bestAttemptPerExam = {};
    for (var att in subjectAttempts) {
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
    final int totalSubjectExams = subjectExams.length;

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
      'totalSubjectExams': totalSubjectExams,
      'marksObtained': totalMarksObtained,
      'totalMarks': totalMarksPossible,
      'percentage': percentage,
      'hasGivenExams': givenExamsCount > 0,
    };
  }

  /// Builds a Google Classroom style subject card with live % calculated from given exams & points
  Widget _buildEnrolledSubjectCard({
    required String subject,
    required int cardIndex,
    required String classroomName,
    required String classroomSection,
    required List<ExamModel> allExams,
    required List<Map<String, dynamic>> attempts,
    required bool isSelected,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final gradients = CreateClassroomDialog.themeGradients;
    final gradient = gradients[cardIndex % gradients.length];
    final metrics = _computeSubjectMetrics(
      subject: subject,
      allExams: allExams,
      attempts: attempts,
    );

    final int percentage = metrics['percentage'] as int;
    final int givenExamsCount = metrics['givenExamsCount'] as int;
    final int totalSubjectExams = metrics['totalSubjectExams'] as int;
    final double marksObtained = metrics['marksObtained'] as double;
    final double totalMarks = metrics['totalMarks'] as double;
    final bool hasGivenExams = metrics['hasGivenExams'] as bool;

    final String marksDisplay = totalMarks > 0
        ? '${marksObtained.truncateToDouble() == marksObtained ? marksObtained.toInt() : marksObtained.toStringAsFixed(1)} / ${totalMarks.toInt()} pts'
        : '0 pts';

    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedSubjectFilter == subject) {
            _selectedSubjectFilter = null;
          } else {
            _selectedSubjectFilter = subject;
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? gradient[1] : gradient[0])
                : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? gradient[0].withOpacity(0.25)
                  : Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
              blurRadius: isSelected ? 8 : 6,
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
                        _getCategoryIcon(subject),
                        color: Colors.white.withOpacity(0.2),
                        size: 40,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subject,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if (classroomName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            classroomSection.isNotEmpty
                                ? '$classroomName • $classroomSection'
                                : classroomName,
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
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: 12,
                            color: gradient[0],
                          ),
                        ),
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
                            fontSize: 20,
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
                              fontSize: 10.5,
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

                    // Exams count status
                    Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 12,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            hasGivenExams
                                ? '$givenExamsCount of $totalSubjectExams given'
                                : (totalSubjectExams > 0
                                    ? '$totalSubjectExams exam${totalSubjectExams > 1 ? 's' : ''} available'
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

  /// Empty state when student is not enrolled in any classroom or classroom has no subjects
  Widget _buildEmptyEnrolledSubjectsState({
    required bool isDarkMode,
    required Color containerColor,
    required Color borderColor,
    required Color subtitleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 40,
            color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
          ),
          const SizedBox(height: 10),
          Text(
            _studentClassroomId.isEmpty
                ? 'No Classroom Joined'
                : 'No Subjects Enrolled',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _studentClassroomId.isEmpty
                ? 'Join a classroom with the code from your instructor to access your enrolled subjects and tests.'
                : 'Your classroom instructor hasn\'t added any subjects yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtitleColor, fontSize: 13),
          ),
          if (_studentClassroomId.isEmpty) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showJoinClassroomDialog(context),
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Join Classroom'),
            ),
          ],
        ],
      ),
    );
  }
}
