// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';

class AdminExamManagementScreen extends StatefulWidget {
  final String adminUid;
  final String adminName;

  const AdminExamManagementScreen({
    super.key,
    required this.adminUid,
    required this.adminName,
  });

  @override
  State<AdminExamManagementScreen> createState() =>
      _AdminExamManagementScreenState();
}

class _AdminExamManagementScreenState extends State<AdminExamManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Published', 'Draft'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _togglePublishStatus(
    BuildContext context,
    String examId,
    String currentStatus,
  ) async {
    final newStatus = currentStatus.toLowerCase() == 'published'
        ? 'Draft'
        : 'Published';
    await FirebaseFirestore.instance.collection('exams').doc(examId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam status updated to $newStatus'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String examId,
    String examTitle,
  ) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 26,
            ),
            SizedBox(width: 10),
            Text(
              'Delete Exam',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "$examTitle"? All associated submission records will also be affected.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('exams').doc(examId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Exam removed successfully'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _editExamDetails(
    BuildContext context,
    String examId,
    Map<String, dynamic> data,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final durCtrl = TextEditingController(
      text: '${data['duration'] ?? data['durationMinutes'] ?? 30}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: 'Exam Title',
                prefixIcon: const Icon(Icons.title, size: 20),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: durCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (Minutes)',
                prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1B4B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newDuration = int.tryParse(durCtrl.text.trim()) ?? 30;
              await FirebaseFirestore.instance
                  .collection('exams')
                  .doc(examId)
                  .update({
                    'title': titleCtrl.text.trim(),
                    'duration': newDuration,
                    'durationMinutes': newDuration,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Save Changes',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getExamDate(Map<String, dynamic> data) {
    if (data['createdAt'] is Timestamp) {
      return (data['createdAt'] as Timestamp).toDate();
    }
    if (data['updatedAt'] is Timestamp) {
      return (data['updatedAt'] as Timestamp).toDate();
    }
    return DateTime.now();
  }

  String _getChatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7 &&
        itemDate.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
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
                  title,
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
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactExamCard({
    required BuildContext context,
    required DocumentSnapshot doc,
    required Map<String, dynamic> data,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required bool isDarkMode,
  }) {
    final title = (data['title'] ?? 'Untitled Exam').toString().trim();
    final category = (data['category'] ?? 'General').toString().trim();
    final status = (data['status'] ?? 'Draft').toString().trim();
    final isPublished = status.toLowerCase() == 'published';
    final questionCount = (data['questions'] as List?)?.length ?? 0;
    final duration = data['duration'] ?? data['durationMinutes'] ?? 30;
    final totalMarks = (data['totalMarks'] as num?)?.toInt() ?? 100;
    final submissionsCount = (data['submissionsCount'] as num?)?.toInt() ?? 0;
    final date = _getExamDate(data);
    final timeStr = _formatTime(date);
    final examCode = doc.id.length >= 6
        ? '#${doc.id.substring(0, 6).toUpperCase()}'
        : '#${doc.id.toUpperCase()}';

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
          onTap: () => _editExamDetails(context, doc.id, data),
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
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
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
                          Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
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
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
                          const SizedBox(width: 6),
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
                      const SizedBox(height: 3),

                      // Row 2: Exam Title
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Row 3: Metrics summary
                      Row(
                        children: [
                          Text(
                            '$questionCount Qs',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '${duration}m',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '$totalMarks pts',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('•', style: TextStyle(color: textMuted, fontSize: 10)),
                          const SizedBox(width: 6),
                          Text(
                            '$submissionsCount subs',
                            style: TextStyle(
                              color: isPublished
                                  ? const Color(0xFF10B981)
                                  : textMuted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Trailing: Status Pill + Actions Menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPublished
                              ? const Color(0xFF10B981).withValues(alpha: 0.35)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          color: isPublished
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: textMuted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: borderColor),
                      ),
                      onSelected: (action) {
                        if (action == 'toggle') {
                          _togglePublishStatus(context, doc.id, status);
                        } else if (action == 'edit') {
                          _editExamDetails(context, doc.id, data);
                        } else if (action == 'delete') {
                          _confirmDelete(context, doc.id, title);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                isPublished
                                    ? Icons.visibility_off_outlined
                                    : Icons.publish_rounded,
                                size: 16,
                                color: isPublished
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 8),
                              Text(isPublished ? 'Unpublish' : 'Publish'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('Edit Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AdminTopBar(
        title: '${widget.adminName}\'s Exams',
        subtitle: 'Instructor Managed Assessments',
        showBackButton: true,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exams')
            .where('adminId', isEqualTo: widget.adminUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allExams = snapshot.data?.docs ?? [];

          // Calculate summary stats
          final totalExams = allExams.length;
          int publishedCount = 0;
          int totalSubmissions = 0;

          final List<DocumentSnapshot> filteredExams = [];

          for (var doc in allExams) {
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'Draft').toString().toLowerCase();
            final isPub = status == 'published';
            if (isPub) publishedCount++;
            totalSubmissions += (data['submissionsCount'] as num?)?.toInt() ?? 0;

            // Filter by Status
            if (_selectedStatusFilter == 'Published' && !isPub) continue;
            if (_selectedStatusFilter == 'Draft' && isPub) continue;

            // Filter by Search Query
            if (_searchQuery.isNotEmpty) {
              final title = (data['title'] ?? '').toString().toLowerCase();
              final category = (data['category'] ?? '').toString().toLowerCase();
              final id = doc.id.toLowerCase();
              if (!title.contains(_searchQuery) &&
                  !category.contains(_searchQuery) &&
                  !id.contains(_searchQuery)) {
                continue;
              }
            }

            filteredExams.add(doc);
          }

          // Sort descending (newest first)
          filteredExams.sort((a, b) {
            final dateA = _getExamDate(a.data() as Map<String, dynamic>);
            final dateB = _getExamDate(b.data() as Map<String, dynamic>);
            return dateB.compareTo(dateA);
          });

          // Group by chat-style date
          final Map<String, List<DocumentSnapshot>> dateGroups = {};
          for (var doc in filteredExams) {
            final date = _getExamDate(doc.data() as Map<String, dynamic>);
            final label = _getChatDateLabel(date);
            dateGroups.putIfAbsent(label, () => []).add(doc);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // 1. Overview Metric Micro-Cards (Same design as Student Report Screen)
              if (allExams.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Total Exams',
                        value: '$totalExams',
                        icon: Icons.layers_outlined,
                        iconColor: const Color(0xFF7C3AED),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Published',
                        value: '$publishedCount',
                        icon: Icons.verified_rounded,
                        iconColor: const Color(0xFF10B981),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'Submissions',
                        value: '$totalSubmissions',
                        icon: Icons.people_outline_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // 2. Search and Filter Controls (Same as Student Report Screen)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: "Search exam, subject, or code...",
                        hintStyle: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: textMuted,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: textSecondary,
                                  size: 18,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C3AED),
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PopupMenuButton<String>(
                    tooltip: 'Filter by Status',
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: borderColor),
                    ),
                    initialValue: _selectedStatusFilter,
                    onSelected: (val) {
                      setState(() {
                        _selectedStatusFilter = val;
                      });
                    },
                    itemBuilder: (context) => ['All', 'Published', 'Draft'].map((filter) {
                      final isSel = filter == _selectedStatusFilter;
                      return PopupMenuItem<String>(
                        value: filter,
                        child: Text(
                          filter,
                          style: TextStyle(
                            color: isSel
                                ? const Color(0xFF7C3AED)
                                : textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _selectedStatusFilter,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Empty State
              if (dateGroups.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_late_outlined,
                          color: Color(0xFF7C3AED),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        allExams.isEmpty
                            ? 'No Active Exams'
                            : 'No Matching Exams Found',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        allExams.isEmpty
                            ? 'No assessments have been published or drafted by ${widget.adminName} yet.'
                            : 'Try searching for a different keyword or change your status filter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // 4. Chat-Style Date Groups with Compact Cards
                ...dateGroups.entries.map((entry) {
                  final dateLabel = entry.key;
                  final examsInDay = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Chat-style floating date separator bubble
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: borderColor.withValues(alpha: 0.6),
                                thickness: 1,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor.withValues(alpha: 0.7),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                dateLabel,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: borderColor.withValues(alpha: 0.6),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Compact Cards for this day
                      ...examsInDay.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildCompactExamCard(
                          context: context,
                          doc: doc,
                          data: data,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          textMuted: textMuted,
                          isDarkMode: isDarkMode,
                        );
                      }),
                    ],
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
