import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends State<StudentNotificationsScreen> {
  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Recently';
    }

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.MMMd().format(date);
  }

  final ExamService _examService = ExamService();

  void _openExamDetail(String examId) async {
    if (examId.isEmpty) return;
    try {
      final exam = await _examService.getExamById(examId);
      if (exam != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.background(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final textMuted = AppColors.textMuted(isDark);

    final currentUser = _currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              NotificationService.instance.markAllAsRead(currentUser.uid);
            },
            icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFF7C3AED)),
            label: const Text(
              'Mark all read',
              style: TextStyle(
                color: Color(0xFF7C3AED),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.instance.getUserNotificationsStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_off_outlined,
                        size: 36,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Notifications Yet',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Whenever your instructor adds a new assessment or exam, you will be notified here instantly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final notifId = notif['id']?.toString() ?? '';
              final title = notif['title']?.toString() ?? 'Exam Update';
              final body = notif['body']?.toString() ?? '';
              final subject = notif['subject']?.toString() ?? 'Assessment';
              final examId = notif['examId']?.toString() ?? '';
              final notifType = notif['type']?.toString() ?? 'new_exam';
              final isRead = notif['isRead'] == true;
              final timestamp = notif['createdAt'];

              // Context-specific theme per notification type
              final IconData typeIcon;
              final Color typeColor;
              final String typeTag;

              if (notifType == 'deadline_approaching') {
                typeIcon = Icons.alarm_rounded;
                typeColor = const Color(0xFFEF4444); // Alert Red
                typeTag = '⏰ 1 Hour Left • $subject';
              } else if (notifType == 'deadline_changed') {
                typeIcon = Icons.edit_calendar_rounded;
                typeColor = const Color(0xFFF59E0B); // Amber / Warning
                typeTag = '⏳ Deadline Updated • $subject';
              } else {
                typeIcon = Icons.assignment_add;
                typeColor = const Color(0xFF7C3AED); // Brand Purple
                typeTag = 'New Exam • $subject';
              }

              return Material(
                color: isRead
                    ? cardColor
                    : (isDark ? const Color(0xFF1E293B) : typeColor.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!isRead && notifId.isNotEmpty) {
                      NotificationService.instance.markAsRead(currentUser.uid, notifId);
                    }
                    if (examId.isNotEmpty) {
                      _openExamDetail(examId);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isRead
                            ? borderColor
                            : typeColor.withOpacity(0.4),
                        width: isRead ? 1 : 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Badge
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            typeIcon,
                            color: typeColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Subject Tag
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      typeTag,
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: typeColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                body,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
