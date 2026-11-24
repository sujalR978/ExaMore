// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/candidate_detail_screen.dart';
import 'package:prep_mate/features/admin/widgets/admin_menu_drawer.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/services/csv_export_service.dart';
import 'package:prep_mate/features/admin/widgets/edit_exam_options_sheet.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';

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

  // Global student name cache to instantly display real names instead of 'Student User'
  static final Map<String, String> _resolvedNameCache = {};

  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'passed', 'failed'
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

    if (AuthService.isSuperAdminUser(_currentUser)) {
      _userRole = 'super_admin';
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();

        if (doc.exists) {
          final role =
              (doc.data()?['role'] ?? 'admin').toString().toLowerCase();
          _userRole = AuthService.isSuperAdminUser(_currentUser, role) ? 'super_admin' : role;
        }
      } catch (_) {}
    }

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
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  void _handleExportCsv(
    BuildContext context,
    ExamModel exam,
    List<StudentSubmissionModel> submissions,
  ) {
    final csvString = CsvExportService.generateExamSubmissionsCsv(
      exam: exam,
      submissions: submissions,
    );
    Clipboard.setData(ClipboardData(text: csvString));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.table_chart_outlined, color: Color(0xFF7C3AED)),
            SizedBox(width: 10),
            Text(
              'Marksheet Exported',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${submissions.length} final student performance records successfully copied to clipboard in CSV format!',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Columns Included:\nRank, Student Name, Student ID, Score %, Marks Obtained, Total Marks, Correct, Incorrect, Unattempted, Status, Timestamp',
                style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final backgroundColor =
        isDarkMode ? const Color(0xFF0F0E17) : const Color(0xFFF8FAFC);
    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    if (_isLoadingRole || _examsStream == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<List<ExamModel>>(
      stream: _examsStream,
      builder: (context, examsSnapshot) {
        final availableExams = examsSnapshot.data ?? [];

        // Resolve active exam
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
          backgroundColor: backgroundColor,
          key: _scaffoldKey,
          drawer: const AdminMenuDrawer(),
          appBar: AdminTopBar(
            title: activeExam != null && activeExam.title.isNotEmpty
                ? activeExam.title
                : 'Exam Submissions',
            subtitle: 'Submissions & Candidate Analytics',
            showBackButton: Navigator.canPop(context),
            onBackPressed: () => Navigator.pop(context),
            onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
            actions: [
              if (activeExam != null && activeExam.id.isNotEmpty)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: textColor),
                  onSelected: (val) async {
                    if (val == 'edit') {
                      EditExamOptionsSheet.show(
                        context,
                        exam: activeExam!,
                      );
                    } else if (val == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.delete_forever,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              SizedBox(width: 8),
                              Text('Delete Exam?'),
                            ],
                          ),
                          content: Text(
                            'Permanently delete "${activeExam!.title}"? All submissions and statistics will also be deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete Exam'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        await _examService.deleteExam(activeExam!.id);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exam deleted successfully'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF7C3AED),
                          ),
                          SizedBox(width: 8),
                          Text('Edit Exam'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Exam',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: examsSnapshot.connectionState == ConnectionState.waiting &&
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
                              style: TextStyle(
                                fontSize: 13,
                                color: subtitleColor,
                              ),
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

        final allSubmissions = snapshot.data ?? [];

        // Group by student and keep best attempt (highest score)
        final Map<String, StudentSubmissionModel> bestSubmissionPerStudent = {};
        final Map<String, int> attemptCountPerStudent = {};

        for (var sub in allSubmissions) {
          final studentKey =
              sub.studentId.isNotEmpty ? sub.studentId : sub.studentName;
          attemptCountPerStudent[studentKey] =
              (attemptCountPerStudent[studentKey] ?? 0) + 1;

          if (!bestSubmissionPerStudent.containsKey(studentKey) ||
              sub.scorePercentage >
                  bestSubmissionPerStudent[studentKey]!.scorePercentage) {
            bestSubmissionPerStudent[studentKey] = sub;
          }
        }

        // Leaderboard order: Sorted by highest score descending
        final rankedSubmissions = bestSubmissionPerStudent.values.toList();
        rankedSubmissions.sort(
          (a, b) => b.scorePercentage.compareTo(a.scorePercentage),
        );

        int passedCount = 0;
        int failedCount = 0;
        for (var s in rankedSubmissions) {
          final pass = s.isPassed ||
              s.scorePercentage >= currentExam.passingScorePercentage;
          if (pass) {
            passedCount++;
          } else {
            failedCount++;
          }
        }

        // Filter based on search query and filter chips
        final filteredSubmissions = rankedSubmissions.where((student) {
          final resolvedName =
              _resolvedNameCache[student.studentId] ?? student.studentName;
          final query = _searchQuery.toLowerCase();
          final matchesQuery =
              resolvedName.toLowerCase().contains(query) ||
              student.studentId.toLowerCase().contains(query);
          if (!matchesQuery) return false;

          final pass = student.isPassed ||
              student.scorePercentage >= currentExam.passingScorePercentage;
          if (_selectedFilter == 'passed') return pass;
          if (_selectedFilter == 'failed') return !pass;
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exam Switcher Dropdown (if multiple exams exist)
              if (availableExams.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(14),
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
                const SizedBox(height: 14),
              ],

              // TOP HEADER CARD: ONLY Title and Export CSV (as explicitly requested: all other chips removed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentExam.title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (rankedSubmissions.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {
                          _handleExportCsv(
                            context,
                            currentExam,
                            rankedSubmissions,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 16,
                        ),
                        label: const Text(
                          'Export CSV',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PRODUCTION-LEVEL STUDENT LIST CARD
              Container(
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search & Filters Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Student Leaderboard',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${rankedSubmissions.length} Students',
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

                          // Search TextField
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by student name or ID...',
                              hintStyle: TextStyle(
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: subtitleColor,
                                size: 20,
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
                                  ? const Color(0xFF1E293B).withOpacity(0.5)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF7C3AED),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Filter Segmented Chips (All / Passed / Failed)
                          Row(
                            children: [
                              _buildFilterChip(
                                label: 'All (${rankedSubmissions.length})',
                                filterKey: 'all',
                                isSelected: _selectedFilter == 'all',
                                activeColor: const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Passed ($passedCount)',
                                filterKey: 'passed',
                                isSelected: _selectedFilter == 'passed',
                                activeColor: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: 'Failed ($failedCount)',
                                filterKey: 'failed',
                                isSelected: _selectedFilter == 'failed',
                                activeColor: const Color(0xFFEF4444),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: borderColor),

                    // Student List Items
                    if (filteredSubmissions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48.0),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 44,
                                color: subtitleColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                rankedSubmissions.isEmpty
                                    ? 'No student submissions recorded yet.'
                                    : 'No matching students found for "$_searchQuery"',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
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
                          final rank = index + 1;
                          final attemptsCount =
                              attemptCountPerStudent[student.studentId] ?? 1;

                          return _StudentSubmissionRow(
                            submission: student,
                            rank: rank,
                            attemptsCount: attemptsCount,
                            maxAttempts: currentExam.allowedAttempts,
                            passingScore: currentExam.passingScorePercentage,
                            isDarkMode: isDarkMode,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
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
                            getInitials: _getInitials,
                          );
                        },
                      ),

                    // Table Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1E293B).withOpacity(0.3)
                            : const Color(0xFFF8FAFC),
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${filteredSubmissions.length} of ${rankedSubmissions.length} students',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Tap student to review answers',
                            style: TextStyle(
                              color: const Color(0xFF7C3AED),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required bool isSelected,
    required Color activeColor,
  }) {
    return InkWell(
      onTap: () {
        setState(() => _selectedFilter = filterKey);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? activeColor : Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// Dynamic Row that resolves the student's actual registered name from Firestore /users/{uid}
/// so it never displays fallback "Student User".
class _StudentSubmissionRow extends StatefulWidget {
  final StudentSubmissionModel submission;
  final int rank;
  final int attemptsCount;
  final int maxAttempts;
  final double passingScore;
  final bool isDarkMode;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onTap;
  final String Function(String) getInitials;

  const _StudentSubmissionRow({
    required this.submission,
    required this.rank,
    required this.attemptsCount,
    required this.maxAttempts,
    required this.passingScore,
    required this.isDarkMode,
    required this.textColor,
    required this.subtitleColor,
    required this.onTap,
    required this.getInitials,
  });

  @override
  State<_StudentSubmissionRow> createState() => _StudentSubmissionRowState();
}

class _StudentSubmissionRowState extends State<_StudentSubmissionRow> {
  late String _displayName;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _displayName = widget.submission.studentName;
    _photoUrl = widget.submission.studentImageUrl;

    // Check if we need to resolve real student name from Firestore
    if (_displayName.trim().isEmpty ||
        _displayName == 'Student User' ||
        _displayName == 'Student') {
      final cached =
          _ExamAnalyticsDetailScreenState._resolvedNameCache[widget.submission.studentId];
      if (cached != null && cached.isNotEmpty) {
        _displayName = cached;
      } else {
        _fetchActualStudentName();
      }
    }
  }

  Future<void> _fetchActualStudentName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.submission.studentId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final realName = (data['name'] ?? '').toString().trim();
          final userPhoto = (data['photoUrl'] ?? '').toString().trim();

          if (realName.isNotEmpty) {
            _ExamAnalyticsDetailScreenState._resolvedNameCache[
                widget.submission.studentId] = realName;
            setState(() {
              _displayName = realName;
              if (_photoUrl == null || _photoUrl!.isEmpty) {
                _photoUrl = userPhoto.isNotEmpty ? userPhoto : null;
              }
            });
            return;
          }

          final email = (data['email'] ?? '').toString().trim();
          if (email.isNotEmpty) {
            final emailName = email.split('@').first;
            _ExamAnalyticsDetailScreenState._resolvedNameCache[
                widget.submission.studentId] = emailName;
            setState(() {
              _displayName = emailName;
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.submission.isPassed ||
        widget.submission.scorePercentage >= widget.passingScore;

    // Elegant Rank Visuals
    Widget rankWidget;
    if (widget.rank == 1) {
      rankWidget = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFF59E0B),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.star, color: Colors.white, size: 14),
        ),
      );
    } else if (widget.rank == 2) {
      rankWidget = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFF94A3B8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '2',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else if (widget.rank == 3) {
      rankWidget = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: Color(0xFFD97706),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            '3',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    } else {
      rankWidget = SizedBox(
        width: 26,
        child: Text(
          '#${widget.rank}',
          style: TextStyle(
            color: widget.subtitleColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Rank
            rankWidget,
            const SizedBox(width: 12),

            // Student Avatar
            CircleAvatar(
              radius: 19,
              backgroundColor: isPassed
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : const Color(0xFFEF4444).withOpacity(0.15),
              backgroundImage:
                  (_photoUrl != null &&
                   _photoUrl!.isNotEmpty &&
                   _photoUrl!.startsWith('http'))
                      ? NetworkImage(_photoUrl!)
                      : null,
              child: (_photoUrl == null ||
                      !_photoUrl!.startsWith('http') ||
                      _photoUrl == 'assets/image/L_image.png')
                  ? Text(
                      _displayName.trim().isNotEmpty ? _displayName.trim()[0].toUpperCase() : 'S',
                      style: TextStyle(
                        color: isPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Student Name & ID / Attempt Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        widget.submission.studentId.length > 8
                            ? widget.submission.studentId.substring(0, 8)
                            : widget.submission.studentId,
                        style: TextStyle(
                          color: widget.subtitleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.attemptsCount > 1) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Best of ${widget.attemptsCount}',
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Final Score & Status Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${widget.submission.scorePercentage.toInt()}%',
                      style: TextStyle(
                        color: isPassed
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.submission.marksObtained.truncateToDouble() == widget.submission.marksObtained ? widget.submission.marksObtained.toInt() : widget.submission.marksObtained.toStringAsFixed(1)} pts)',
                      style: TextStyle(
                        color: widget.subtitleColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : const Color(0xFFEF4444).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isPassed ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      color: isPassed
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: widget.subtitleColor.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
