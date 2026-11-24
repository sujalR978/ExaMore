// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/add_multiple_choice_question_screen.dart';
import 'package:prep_mate/features/admin/screens/exam_analytics_detail_screen.dart';
import 'package:prep_mate/features/admin/screens/exam_configuration_screen.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';

class Showexamesscreen extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onMenuPressed;

  const Showexamesscreen({super.key, this.isTab = false, this.onMenuPressed});

  @override
  State<Showexamesscreen> createState() => _ActiveExamsScreenState();
}

class _ActiveExamsScreenState extends State<Showexamesscreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Published', 'Draft'
  String _userRole = 'admin';
  String _adminUid = '';
  bool _isLoadingRole = true;

  Stream<List<ExamModel>>? _examsStream;

  @override
  void initState() {
    super.initState();
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
          final role = (doc.data()?['role'] ?? 'admin')
              .toString()
              .toLowerCase();
          _userRole = AuthService.isSuperAdminUser(_currentUser, role)
              ? 'super_admin'
              : role;
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

  void _handleEditExam(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExamConfigurationScreen(exam: exam),
      ),
    );
  }

  void _handleManageQuestions(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMultipleChoiceQuestionScreen(exam: exam),
      ),
    );
  }

  Future<void> _togglePublishStatus(ExamModel exam) async {
    final newStatus = exam.status.toLowerCase() == 'published'
        ? 'Draft'
        : 'Published';
    try {
      final updatedExam = exam.copyWith(status: newStatus);
      await _examService.updateExam(updatedExam);
      if (newStatus == 'Published') {
        try {
          await NotificationService.instance.sendNewExamNotification(updatedExam);
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam status updated to $newStatus'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleDeleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam'),
        content: Text('Are you sure you want to delete "${exam.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _examService.deleteExam(exam.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exam deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleViewResults(ExamModel exam) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExamAnalyticsDetailScreen(examId: exam.id, exam: exam),
      ),
    );
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final examDate = DateTime(date.year, date.month, date.day);

    if (examDate == today) {
      return 'Today';
    } else if (examDate == yesterday) {
      return 'Yesterday';
    } else if (date.year == now.year) {
      return DateFormat('EEEE, MMM d').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = AppColors.card(isDarkMode);
    final textColor = AppColors.textPrimary(isDarkMode);
    final subtitleColor = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);

    if (_isLoadingRole || _examsStream == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isSuperAdmin = _userRole == 'super_admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      appBar: AdminTopBar(
        title: isSuperAdmin ? 'All Platform Exams' : 'My Active Exams',
        subtitle: isSuperAdmin
            ? 'Super Admin Portal'
            : 'Published & Draft Assessments',
        showBackButton: !widget.isTab && Navigator.canPop(context),
        onBackPressed: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
            tooltip: 'Create New Exam',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExamConfigurationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ExamModel>>(
        stream: _examsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading exams: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allExams = snapshot.data ?? [];

          // Overview Metrics Calculations
          final totalExamsCount = allExams.length;
          final publishedCount = allExams
              .where((e) => e.status.toLowerCase() == 'published')
              .length;
          final draftCount = allExams
              .where((e) => e.status.toLowerCase() != 'published')
              .length;
          final totalQuestionsCount = allExams.fold<int>(
            0,
            (acc, e) => acc + e.questions.length,
          );

          // Filtering
          final filteredExams = allExams.where((exam) {
            final matchesSearch =
                _searchQuery.isEmpty ||
                exam.title.toLowerCase().contains(_searchQuery) ||
                exam.examCode.toLowerCase().contains(_searchQuery) ||
                exam.category.toLowerCase().contains(_searchQuery);

            final status = exam.status.toLowerCase();
            final matchesStatus =
                _selectedStatusFilter == 'All' ||
                (_selectedStatusFilter == 'Published' &&
                    status == 'published') ||
                (_selectedStatusFilter == 'Draft' && status != 'published');

            return matchesSearch && matchesStatus;
          }).toList();

          // Sort descending by created/start date
          filteredExams.sort((a, b) {
            final dateA = a.startDate ?? a.createdAt;
            final dateB = b.startDate ?? b.createdAt;
            return dateB.compareTo(dateA);
          });

          // Group by Date Header
          final Map<String, List<ExamModel>> groupedExams = {};
          for (final exam in filteredExams) {
            final date = exam.startDate ?? exam.createdAt;
            final header = _getDateHeader(date);
            groupedExams.putIfAbsent(header, () => []).add(exam);
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Overview Metric Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Total Exams',
                              value: '$totalExamsCount',
                              icon: Icons.layers_rounded,
                              iconColor: const Color(0xFF7C3AED),
                              cardColor: containerColor,
                              borderColor: borderColor,
                              textPrimary: textColor,
                              textSecondary: subtitleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Published',
                              value: '$publishedCount',
                              icon: Icons.check_circle_rounded,
                              iconColor: const Color(0xFF10B981),
                              cardColor: containerColor,
                              borderColor: borderColor,
                              textPrimary: textColor,
                              textSecondary: subtitleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Drafts',
                              value: '$draftCount',
                              icon: Icons.edit_note_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              cardColor: containerColor,
                              borderColor: borderColor,
                              textPrimary: textColor,
                              textSecondary: subtitleColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricMiniCard(
                              label: 'Questions',
                              value: '$totalQuestionsCount',
                              icon: Icons.format_list_numbered_rounded,
                              iconColor: const Color(0xFF3B82F6),
                              cardColor: containerColor,
                              borderColor: borderColor,
                              textPrimary: textColor,
                              textSecondary: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Search Input Field
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Search by title, category, or #code...',
                          hintStyle: TextStyle(color: textMuted, fontSize: 13),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: subtitleColor,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: subtitleColor,
                                    size: 18,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: containerColor,
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
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Status Filter Chips
                      Row(
                        children: ['All', 'Published', 'Draft'].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: isSelected,
                              labelStyle: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : subtitleColor,
                              ),
                              selectedColor: const Color(0xFF7C3AED),
                              backgroundColor: containerColor,
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF7C3AED)
                                    : borderColor,
                                width: 1,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 0,
                              ),
                              showCheckmark: false,
                              onSelected: (_) {
                                setState(() => _selectedStatusFilter = status);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty State
              if (groupedExams.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_late_outlined,
                            size: 48,
                            color: subtitleColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No exams found matching "$_searchQuery"'
                                : 'No exams available in this view.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final keys = groupedExams.keys.toList();
                      final dateHeader = keys[index];
                      final examsForDate = groupedExams[dateHeader]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chat-Style Date Badge Header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? Colors.white10
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white12
                                        : Colors.grey.shade300,
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  dateHeader,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: subtitleColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Exam cards for this date
                          ...examsForDate.map(
                            (exam) => _buildCompactExamCard(
                              exam: exam,
                              cardColor: containerColor,
                              borderColor: borderColor,
                              textPrimary: textColor,
                              textSecondary: subtitleColor,
                              textMuted: textMuted,
                              isDarkMode: isDarkMode,
                            ),
                          ),
                        ],
                      );
                    }, childCount: groupedExams.keys.length),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(icon, color: iconColor, size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExamCard({
    required ExamModel exam,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required bool isDarkMode,
  }) {
    final title = exam.title.trim().isNotEmpty
        ? exam.title.trim()
        : 'Untitled Exam';
    final category = exam.category.trim().isNotEmpty
        ? exam.category.trim()
        : 'General';
    final isPublished = exam.status.toLowerCase() == 'published';
    final questionCount = exam.questions.length;
    final duration = exam.durationMinutes;
    final totalMarks = exam.totalMarks.toInt();
    final submissionsCount = exam.submissionsCount;
    final date = exam.startDate ?? exam.createdAt;
    final timeStr = _formatTime(date);
    final examCode = exam.examCode.isNotEmpty
        ? exam.examCode
        : (exam.id.length >= 6
              ? '#${exam.id.substring(0, 6).toUpperCase()}'
              : '#${exam.id}');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : const Color(0xFFF59E0B).withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _handleEditExam(exam),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Leading: Compact Status / Type Emblem (44x44)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPublished
                        ? const Color(0xFF10B981).withValues(alpha: 0.14)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPublished
                          ? const Color(0xFF10B981).withValues(alpha: 0.35)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isPublished
                          ? Icons.check_circle_outline_rounded
                          : Icons.edit_note_rounded,
                      size: 22,
                      color: isPublished
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Center Column: Category + Code + Time, Title, Metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Category badge + Exam Code + Time
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(color: textMuted, fontSize: 10),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            examCode,
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Row 2: Exam Title (Single-line bold)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Row 3: Inline Metrics (Duration, Questions, Marks, Submissions)
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${duration}m',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.help_outline_rounded,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$questionCount Qs',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.stars_rounded,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$totalMarks pts',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.people_outline_rounded,
                            size: 12,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$submissionsCount subs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPublished
                                  ? const Color(0xFF10B981)
                                  : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing 3-Dots Action Menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: textSecondary,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 160),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: cardColor,
                  onSelected: (value) {
                    if (value == 'results') {
                      _handleViewResults(exam);
                    } else if (value == 'edit') {
                      _handleEditExam(exam);
                    } else if (value == 'questions') {
                      _handleManageQuestions(exam);
                    } else if (value == 'toggle') {
                      _togglePublishStatus(exam);
                    } else if (value == 'delete') {
                      _handleDeleteExam(exam);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Configurations',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'questions',
                      child: Row(
                        children: [
                          Icon(
                            Icons.quiz_outlined,
                            size: 16,
                            color: textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Edit Questions (${exam.questions.length})',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'results',
                      child: Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 16,
                            color: textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Submissions',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isPublished
                                ? Icons.cloud_off_rounded
                                : Icons.cloud_upload_rounded,
                            size: 16,
                            color: isPublished
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isPublished ? 'Unpublish to Draft' : 'Publish Live',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isPublished
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Exam',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
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
}
