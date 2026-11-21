// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/candidate_detail_screen.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';

class RecentResultsAndUsersScreen extends StatefulWidget {
  final bool isTab;
  const RecentResultsAndUsersScreen({super.key, this.isTab = false});

  @override
  State<RecentResultsAndUsersScreen> createState() =>
      _RecentResultsAndUsersScreenState();
}

class _RecentResultsAndUsersScreenState
    extends State<RecentResultsAndUsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _searchQuery = '';
  String _userRole = 'admin';
  bool _isLoadingRole = true;
  Stream<List>? _resultsStream;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  Future<void> _fetchUserRole() async {
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

    _resultsStream = _getResultsStream();

    if (mounted) {
      setState(() => _isLoadingRole = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleViewDetails({
    required String examId,
    required StudentSubmissionModel submission,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CandidateDetailScreen(
          examId: examId,
          submissionId: submission.id,
          initialData: submission,
        ),
      ),
    );
  }

  Stream<List> _getResultsStream() {
    final bool isSuperAdmin = AuthService.isSuperAdminUser(
      _currentUser,
      _userRole,
    );

    if (isSuperAdmin) {
      // Super Admin inspects results across the entire platform
      return _examService.getAllRecentSubmissionsStream();
    } else {
      // Regular Admin only receives submissions for exams they created
      final String adminId = _currentUser?.uid ?? '';
      return _examService.getRecentSubmissionsByAdminStream(adminId);
    }
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

    if (_isLoadingRole) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool isSuperAdmin = AuthService.isSuperAdminUser(
      _currentUser,
      _userRole,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      appBar: AdminTopBar(
        title: isSuperAdmin ? 'Super Admin Portal' : 'Exam Results',
        subtitle: isSuperAdmin
            ? 'System-wide Submissions'
            : 'Candidate Performance & Analytics',
        showBackButton: !widget.isTab && Navigator.canPop(context),
        onBackPressed: () => Navigator.pop(context),
      ),
      body: StreamBuilder<List>(
        stream: _resultsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading results: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allResults = snapshot.data ?? [];

          // Local Search Filter
          final filteredResults = allResults.where((item) {
            final submission = item['submission'] as StudentSubmissionModel;
            return submission.studentName.toLowerCase().contains(
                  _searchQuery,
                ) ||
                submission.examTitle.toLowerCase().contains(_searchQuery) ||
                submission.studentId.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredResults.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40.0,
                  horizontal: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: subtitleColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      allResults.isEmpty
                          ? 'No student results submitted yet.'
                          : 'No student results found matching "$_searchQuery"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: filteredResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = filteredResults[index];
              final examId = item['examId'] as String;
              final submission = item['submission'] as StudentSubmissionModel;

              return _CompactResultCard(
                submission: submission,
                containerColor: containerColor,
                textColor: textColor,
                subtitleColor: subtitleColor,
                borderColor: borderColor,
                isDarkMode: isDarkMode,
                onTap: () => _handleViewDetails(
                  examId: examId,
                  submission: submission,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompactResultCard extends StatefulWidget {
  final StudentSubmissionModel submission;
  final Color containerColor;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _CompactResultCard({
    required this.submission,
    required this.containerColor,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_CompactResultCard> createState() => _CompactResultCardState();
}

class _CompactResultCardState extends State<_CompactResultCard> {
  static final Map<String, String?> _resolvedPhotoCache = {};
  String? _resolvedPhotoUrl;

  @override
  void initState() {
    super.initState();
    _resolveStudentPhoto();
  }

  @override
  void didUpdateWidget(covariant _CompactResultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submission.studentId != widget.submission.studentId) {
      _resolveStudentPhoto();
    }
  }

  void _resolveStudentPhoto() {
    final directUrl = widget.submission.studentImageUrl;
    if (directUrl != null &&
        directUrl.trim().isNotEmpty &&
        directUrl != 'assets/image/L_image.png' &&
        !directUrl.startsWith('assets/')) {
      _resolvedPhotoUrl = directUrl;
      return;
    }

    final studentId = widget.submission.studentId.trim();
    if (studentId.isEmpty) return;

    if (_resolvedPhotoCache.containsKey(studentId)) {
      _resolvedPhotoUrl = _resolvedPhotoCache[studentId];
      return;
    }

    // Asynchronously resolve from users collection
    FirebaseFirestore.instance
        .collection('users')
        .doc(studentId)
        .get()
        .then((doc) {
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data() ?? {};
        final rawPhoto = (data['photoUrl'] ??
                data['profilePicture'] ??
                data['imageUrl'] ??
                '')
            .toString()
            .trim();
        final bool isValid = rawPhoto.isNotEmpty &&
            !rawPhoto.startsWith('assets/') &&
            rawPhoto != 'assets/image/L_image.png';
        final photo = isValid ? rawPhoto : null;
        _resolvedPhotoCache[studentId] = photo;
        setState(() {
          _resolvedPhotoUrl = photo;
        });
      } else {
        _resolvedPhotoCache[studentId] = null;
      }
    }).catchError((_) {
      _resolvedPhotoCache[studentId] = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.submission.isPassed;
    final String firstLetter = widget.submission.studentName.trim().isNotEmpty
        ? widget.submission.studentName.trim()[0].toUpperCase()
        : 'S';
    final hasPhoto = _resolvedPhotoUrl != null && _resolvedPhotoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: widget.containerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF10B981).withValues(alpha: 0.25)
              : const Color(0xFFEF4444).withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: widget.isDarkMode ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Avatar (44x44)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed
                        ? (widget.isDarkMode
                            ? const Color(0xFF064E3B)
                            : const Color(0xFFD1FAE5))
                        : (widget.isDarkMode
                            ? const Color(0xFF451A03)
                            : const Color(0xFFFEE2E2)),
                    border: Border.all(
                      color: isPassed
                          ? const Color(0xFF10B981).withValues(alpha: 0.4)
                          : const Color(0xFFEF4444).withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? AppImageView(
                          imageSource: _resolvedPhotoUrl!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          placeholder: Center(
                            child: Text(
                              firstLetter,
                              style: TextStyle(
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          errorWidget: Center(
                            child: Text(
                              firstLetter,
                              style: TextStyle(
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            firstLetter,
                            style: TextStyle(
                              color: isPassed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),

                // Center Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name & Time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.submission.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM d • h:mm a')
                                .format(widget.submission.submittedAt),
                            style: TextStyle(
                              color: widget.subtitleColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Exam Title
                      Text(
                        widget.submission.examTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.subtitleColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Score, Marks, Pass/Fail
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? const Color(0xFF10B981)
                                      .withValues(alpha: 0.12)
                                  : const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.submission.scorePercentage.toInt()}%',
                              style: TextStyle(
                                color: isPassed
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: widget.subtitleColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.submission.marksObtained.toInt()}/${widget.submission.totalMarks.toInt()} pts',
                            style: TextStyle(
                              color: widget.subtitleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '•',
                            style: TextStyle(
                              color: widget.subtitleColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: isPassed
                                  ? (widget.isDarkMode
                                      ? const Color(0xFF064E3B)
                                      : const Color(0xFFD1FAE5))
                                  : (widget.isDarkMode
                                      ? const Color(0xFF451A03)
                                      : const Color(0xFFFEF2F2)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPassed ? 'Passed' : 'Failed',
                              style: TextStyle(
                                color: isPassed
                                    ? (widget.isDarkMode
                                        ? const Color(0xFF34D399)
                                        : const Color(0xFF065F46))
                                    : const Color(0xFFDC2626),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing Arrow
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: widget.subtitleColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
