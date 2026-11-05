// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/CandidateDetailScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';

class ExamAnalyticsDetailScreen extends StatefulWidget {
  final ExamModel? exam;
  final String? examId;

  const ExamAnalyticsDetailScreen({super.key, this.exam, this.examId});

  @override
  State<ExamAnalyticsDetailScreen> createState() =>
      _ExamAnalyticsDetailScreenState();
}

class _ExamAnalyticsDetailScreenState extends State<ExamAnalyticsDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _searchQuery = '';
  ExamModel? _selectedExam;

  String _userRole = 'admin';
  String _adminUid = '';
  bool _isLoadingRole = true;

  Stream<List<ExamModel>>? _examsStream;

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.exam;
    _adminUid = _currentUser?.uid ?? '';
    _initRoleAndStream();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase().trim();
        });
      }
    });
  }

  Future<void> _initRoleAndStream() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    if (_currentUser.email?.toLowerCase() == 'admin@gmail.com') {
      _userRole = 'super_admin';
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();

        if (doc.exists) {
          _userRole = (doc.data()?['role'] ?? 'admin').toString().toLowerCase();
        }
      } catch (_) {}
    }

    // Role-based scoping: Super admin sees all, regular admin only sees their own
    _examsStream = _examService.getExamsStream(
      adminId: _adminUid,
      role: _userRole,
    );

    if (mounted) {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ST';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
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

    if (_isLoadingRole || _examsStream == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<ExamModel>>(
      stream: _examsStream,
      builder: (context, examsSnapshot) {
        final availableExams = examsSnapshot.data ?? [];

        // 1. Resolve active exam with multiple fallbacks
        ExamModel? activeExam = _selectedExam;

        if (activeExam == null || activeExam.id.trim().isEmpty) {
          final targetId = widget.examId ?? widget.exam?.id ?? '';
          final targetCode = widget.exam?.examCode ?? '';
          final targetTitle = widget.exam?.title ?? '';

          if (availableExams.isNotEmpty) {
            try {
              activeExam = availableExams.firstWhere(
                (e) =>
                    (targetId.isNotEmpty && e.id == targetId) ||
                    (targetCode.isNotEmpty && e.examCode == targetCode) ||
                    (targetTitle.isNotEmpty && e.title == targetTitle),
              );
            } catch (_) {
              activeExam = availableExams.first;
            }
          }
        } else {
          // Keep activeExam synced with the latest Firestore data
          final match = availableExams.where((e) => e.id == activeExam!.id);
          if (match.isNotEmpty) {
            activeExam = match.first;
          } else if (availableExams.isNotEmpty) {
            activeExam = availableExams.first;
          } else {
            activeExam = null;
          }
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          key: _scaffoldKey,
          drawer: const AdminMenuDrawer(),
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
                        color: Colors.black.withValues(
                          alpha: isDarkMode ? 0.2 : 0.05,
                        ),
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
                        icon: Icon(
                          Icons.menu,
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                        ),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                      ),
                      title: Text(
                        _userRole == 'super_admin'
                            ? 'Examora Global Analytics'
                            : 'Examora Analytics',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      centerTitle: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body:
              examsSnapshot.connectionState == ConnectionState.waiting &&
                  availableExams.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : (activeExam == null || activeExam.id.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 60,
                          color: subtitleColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Exams Found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userRole == 'super_admin'
                              ? 'No exams exist across the platform.'
                              : 'You have not created any exams yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildAnalyticsContent(
                  context: context,
                  currentExam: activeExam,
                  availableExams: availableExams,
                  containerColor: containerColor,
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                  borderColor: borderColor,
                  isDarkMode: isDarkMode,
                ),
        );
      },
    );
  }

  Widget _buildAnalyticsContent({
    required BuildContext context,
    required ExamModel currentExam,
    required List<ExamModel> availableExams,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return StreamBuilder<List<StudentSubmissionModel>>(
      stream: _examService.getExamSubmissionsStream(currentExam.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error loading submissions: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final submissions = snapshot.data ?? [];

        final totalSubmissions = submissions.length;
        final averageScore = totalSubmissions > 0
            ? (submissions
                          .map((s) => s.scorePercentage)
                          .reduce((a, b) => a + b) /
                      totalSubmissions)
                  .toStringAsFixed(0)
            : '0';

        final passedCount = submissions.where((s) {
          return s.isPassed ||
              s.scorePercentage >= currentExam.passingScorePercentage;
        }).length;

        final passRate = totalSubmissions > 0
            ? ((passedCount / totalSubmissions) * 100).toStringAsFixed(0)
            : '0';

        final topScore = totalSubmissions > 0
            ? submissions
                  .map((s) => s.scorePercentage)
                  .reduce((a, b) => a > b ? a : b)
                  .toStringAsFixed(0)
            : '0';

        final filteredSubmissions = submissions.where((student) {
          final query = _searchQuery.toLowerCase();
          return student.studentName.toLowerCase().contains(query) ||
              student.studentId.toLowerCase().contains(query);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown switcher only shows exams the logged in admin has access to
              if (availableExams.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: currentExam.id,
                      icon: Icon(Icons.swap_horiz, color: subtitleColor),
                      dropdownColor: containerColor,
                      items: availableExams.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.id,
                          child: Text(
                            e.title.isEmpty ? 'Untitled Exam' : e.title,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          setState(() {
                            _selectedExam = availableExams.firstWhere(
                              (e) => e.id == newId,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Back to Exams Link
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back,
                      size: 16,
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back to Exams',
                      style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF1E1B4B),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Title and Badges
              Text(
                currentExam.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    '# ${currentExam.examCode.isNotEmpty ? currentExam.examCode : currentExam.id.substring(0, 6)}',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: currentExam.status.toLowerCase() == 'published'
                          ? (isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                          : (isDarkMode
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentExam.status,
                      style: TextStyle(
                        color: currentExam.status.toLowerCase() == 'published'
                            ? (isDarkMode
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF065F46))
                            : const Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pass Mark: ${currentExam.passingScorePercentage.toInt()}%',
                      style: TextStyle(
                        color: isDarkMode
                            ? const Color(0xFF93C5FD)
                            : const Color(0xFF1D4ED8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Metric Cards Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.25,
                children: [
                  _buildMetricCard(
                    title: 'AVERAGE SCORE',
                    value: '$averageScore%',
                    icon: Icons.assessment_outlined,
                    iconColor: const Color(0xFFD97706),
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  _buildMetricCard(
                    title: 'PASS RATE',
                    value: '$passRate%',
                    icon: Icons.check_circle_outline,
                    iconColor: const Color(0xFF059669),
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  _buildMetricCard(
                    title: 'TOP SCORE',
                    value: '$topScore%',
                    icon: Icons.emoji_events_outlined,
                    iconColor: const Color(0xFFD97706),
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                  _buildMetricCard(
                    title: 'TOTAL ATTEMPTS',
                    value: '$totalSubmissions',
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF1D4ED8),
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Student Results Container
              Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.2 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submissions',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 3,
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Live Sync',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search by student name or ID...",
                              hintStyle: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: subtitleColor,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: subtitleColor,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDarkMode
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF7C3AED),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                            : const Color(0xFFF8FAFC),
                        border: Border(
                          top: BorderSide(color: borderColor),
                          bottom: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              'STUDENT',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ID',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'SCORE',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Rows
                    if (filteredSubmissions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36.0),
                        child: Center(
                          child: Text(
                            submissions.isEmpty
                                ? 'No student submissions recorded yet.'
                                : 'No matching results found for "$_searchQuery"',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredSubmissions.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (context, index) {
                          final student = filteredSubmissions[index];
                          final isFailed =
                              !student.isPassed &&
                              student.scorePercentage <
                                  currentExam.passingScorePercentage;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CandidateDetailScreen(
                                    examId: currentExam.id,
                                    submissionId: student.id,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isFailed
                                    ? (isDarkMode
                                          ? const Color(
                                              0xFF451A03,
                                            ).withValues(alpha: 0.3)
                                          : const Color(0xFFFEF2F2))
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        student.studentImageUrl != null &&
                                                student
                                                    .studentImageUrl!
                                                    .isNotEmpty
                                            ? CircleAvatar(
                                                radius: 18,
                                                backgroundImage: NetworkImage(
                                                  student.studentImageUrl!,
                                                ),
                                              )
                                            : CircleAvatar(
                                                radius: 18,
                                                backgroundColor: isFailed
                                                    ? const Color(0xFFFEE2E2)
                                                    : const Color(0xFFDBEAFE),
                                                child: Text(
                                                  _getInitials(
                                                    student.studentName,
                                                  ),
                                                  style: TextStyle(
                                                    color: isFailed
                                                        ? const Color(
                                                            0xFFDC2626,
                                                          )
                                                        : const Color(
                                                            0xFF1D4ED8,
                                                          ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            student.studentName,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      student.studentId,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${student.scorePercentage.toInt()}%',
                                        style: TextStyle(
                                          color: isFailed
                                              ? const Color(0xFFDC2626)
                                              : textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${filteredSubmissions.length} of ${submissions.length} results',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          if (filteredSubmissions.isNotEmpty)
                            Text(
                              'Tap student for answers',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
