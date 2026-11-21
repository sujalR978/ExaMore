// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/auth/screens/login_screen.dart';
import 'package:prep_mate/features/auth/services/auth_service.dart';
import 'package:prep_mate/features/user/screens/personal_information_screen.dart';
import 'package:prep_mate/features/user/screens/privacy_policy_screen.dart';
import 'package:prep_mate/features/user/screens/saved_exam_screen.dart';
import 'package:prep_mate/features/user/screens/settings_screen.dart';
import 'package:prep_mate/features/user/screens/support_center_screen.dart';
import 'package:prep_mate/core/widgets/app_image_view.dart';

class BadgeItem {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color bgLight;
  final Color iconLight;
  final bool isUnlocked;

  BadgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.bgLight,
    required this.iconLight,
    required this.isUnlocked,
  });
}

class Userprofile extends StatefulWidget {
  const Userprofile({super.key});

  @override
  State<Userprofile> createState() => _UserProfileState();
}

class _UserProfileState extends State<Userprofile> {
  bool _isLoggingOut = false;
  final ExamService _examService = ExamService();

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (user.email == 'admin@gmail.com') {
      return {
        'name': 'Admin User',
        'email': 'admin@gmail.com',
        'photoUrl': 'assets/image/L_image.png',
        'academicLevel': 'System Administrator',
        'major': 'Computer Science',
        'adminId': 'root_admin',
      };
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  void _showUpdateAdminIdDialog(BuildContext context, String currentAdminId) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final controller = TextEditingController(text: currentAdminId);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            backgroundColor: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.vpn_key_rounded,
                    color: Color(0xFF7C3AED),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Instructor UID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the Instructor UID provided by your teacher to access their scoped exams and cohorts.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? const Color(0xFF94A3B8)
                        : Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Instructor UID',
                    hintText: 'Paste teacher UID here',
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isSaving
                    ? null
                    : () async {
                        final newUid = controller.text.trim();
                        final currentUid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';

                        if (newUid.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an Instructor UID.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (newUid == currentUid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You cannot set your own UID as your instructor.',
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          // Validate that this UID corresponds to a registered admin
                          final adminDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(newUid)
                              .get();

                          if (!adminDoc.exists ||
                              (adminDoc.data()?['role'] ?? '')
                                      .toString()
                                      .toLowerCase() !=
                                  'admin') {
                            setDialogState(() => isSaving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Invalid Instructor UID. No active instructor found with this code.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          // Update student's linked adminId in Firestore
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUid)
                              .update({'adminId': newUid});

                          if (!ctx.mounted) return;
                          Navigator.of(ctx).pop();

                          _refreshProfile();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Instructor updated to ${adminDoc.data()?['name'] ?? 'Instructor'} successfully!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating instructor: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<BadgeItem> _calculateBadges(List<dynamic> attempts) {
    int totalAttempts = attempts.length;
    double maxScore = 0.0;
    bool hasSubmittedMorning = false;
    bool hasSubmittedNight = false;
    bool hasFlawlessExam = false;
    final Set<String> uniqueDays = {};

    for (var item in attempts) {
      final submission = item['submission'] as StudentSubmissionModel;

      if (submission.scorePercentage > maxScore) {
        maxScore = submission.scorePercentage;
      }

      final hour = submission.submittedAt.hour;
      if (hour >= 5 && hour < 12) {
        hasSubmittedMorning = true;
      }
      if (hour >= 21 || hour < 4) {
        hasSubmittedNight = true;
      }

      if (submission.incorrectAnswers == 0 &&
          submission.unattemptedAnswers == 0 &&
          submission.correctAnswers > 0) {
        hasFlawlessExam = true;
      }

      final d = submission.submittedAt;
      uniqueDays.add(
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      );
    }

    int streak = 0;
    DateTime checkDate = DateTime.now();
    String todayKey =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

    if (!uniqueDays.contains(todayKey)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (uniqueDays.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return [
      BadgeItem(
        id: 'first_step',
        title: 'First Step',
        description: 'Completed your first exam attempt.',
        icon: Icons.flag_outlined,
        bgLight: const Color(0xFFDBEAFE),
        iconLight: const Color(0xFF1D4ED8),
        isUnlocked: totalAttempts >= 1,
      ),
      BadgeItem(
        id: 'top_scorer',
        title: 'Top Scorer',
        description: 'Achieved 90% or higher on an assessment.',
        icon: Icons.emoji_events,
        bgLight: const Color(0xFFFEF3C7),
        iconLight: const Color(0xFFB45309),
        isUnlocked: maxScore >= 90.0,
      ),
      BadgeItem(
        id: 'consistent_learner',
        title: 'Consistent',
        description: 'Completed at least 3 exam assessments.',
        icon: Icons.auto_stories,
        bgLight: const Color(0xFFDCFCE7),
        iconLight: const Color(0xFF15803D),
        isUnlocked: totalAttempts >= 3,
      ),
      BadgeItem(
        id: 'master_mind',
        title: 'Master Mind',
        description: 'Scored a perfect 100% on any exam.',
        icon: Icons.psychology_outlined,
        bgLight: const Color(0xFFF3E8FF),
        iconLight: const Color(0xFF7E22CE),
        isUnlocked: maxScore >= 100.0,
      ),
      BadgeItem(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Submitted an exam before 12:00 PM.',
        icon: Icons.alarm,
        bgLight: const Color(0xFFD1FAE5),
        iconLight: const Color(0xFF065F46),
        isUnlocked: hasSubmittedMorning,
      ),
      BadgeItem(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Studied and submitted an exam after 9:00 PM.',
        icon: Icons.nights_stay_outlined,
        bgLight: const Color(0xFFE0E7FF),
        iconLight: const Color(0xFF4338CA),
        isUnlocked: hasSubmittedNight,
      ),
      BadgeItem(
        id: 'streak_master',
        title: 'Streak 3D',
        description: 'Maintained an active 3-day study streak.',
        icon: Icons.local_fire_department_outlined,
        bgLight: const Color(0xFFFFEDD5),
        iconLight: const Color(0xFFC2410C),
        isUnlocked: streak >= 3,
      ),
      BadgeItem(
        id: 'perfectionist',
        title: 'Perfectionist',
        description: 'Answered every single question without mistakes.',
        icon: Icons.verified_outlined,
        bgLight: const Color(0xFFCCFBF1),
        iconLight: const Color(0xFF0F766E),
        isUnlocked: hasFlawlessExam,
      ),
    ];
  }

  void _refreshProfile() {
    setState(() {});
  }

  void _showAllBadgesModal(List<BadgeItem> badges) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDarkMode = theme.brightness == Brightness.dark;
        final containerColor = theme.colorScheme.surface;
        final textColor = theme.colorScheme.onSurface;
        final subtitleColor = isDarkMode
            ? const Color(0xFF94A3B8)
            : Colors.grey[600]!;
        final unlockedCount = badges.where((b) => b.isUnlocked).length;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievement Badges',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$unlockedCount of ${badges.length} Unlocked',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: badges.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final b = badges[idx];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? (b.isUnlocked
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF0F172A))
                                : (b.isUnlocked
                                      ? const Color(0xFFF8FAFC)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: b.isUnlocked
                                  ? (isDarkMode
                                        ? Colors.white24
                                        : Colors.grey.shade300)
                                  : (isDarkMode
                                        ? Colors.white10
                                        : Colors.grey.shade200),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: b.isUnlocked
                                      ? (isDarkMode
                                            ? const Color(0xFF334155)
                                            : b.bgLight)
                                      : (isDarkMode
                                            ? Colors.white10
                                            : Colors.grey.shade300),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  b.icon,
                                  color: b.isUnlocked
                                      ? (isDarkMode
                                            ? const Color(0xFFFBBF24)
                                            : b.iconLight)
                                      : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          b.title,
                                          style: TextStyle(
                                            color: b.isUnlocked
                                                ? textColor
                                                : subtitleColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (b.isUnlocked)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 16,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      b.description,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _handleMenuAction(String title, {String currentAdminId = ''}) async {
    if (title == 'Personal Information') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalInformationScreen(),
        ),
      );
      _refreshProfile();
    } else if (title == 'Instructor UID') {
      _showUpdateAdminIdDialog(context, currentAdminId);
    } else if (title == 'Saved Exams') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const SavedExamsScreen()));
      _refreshProfile();
    } else if (title == 'Settings') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const Settingscreen()));
      _refreshProfile();
    } else if (title == 'Help & Support') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const SupportCenterScreen()),
      );
      _refreshProfile();
    } else if (title == 'Privacy Policy') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
      );
    }
  }

  void _handleLogout() async {
    // 1. Set logging out state to prevent UI flickers
    setState(() => _isLoggingOut = true);

    // 2. Show a clean blocking overlay so the cleared profile is never shown
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      ),
    );

    try {
      final AuthService authService = AuthService();
      await authService.signOut();

      if (!mounted) return;

      // 3. Clear navigation stack and route to Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        // Dismiss loading dialog if sign out fails
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Logout failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bgColor = AppColors.background(isDarkMode);
    final cardColor = AppColors.card(isDarkMode);
    final surfaceSec = AppColors.surfaceSecondary(isDarkMode);
    final borderColor = AppColors.border(isDarkMode);
    final textPrimary = AppColors.textPrimary(isDarkMode);
    final textSecondary = AppColors.textSecondary(isDarkMode);
    final textMuted = AppColors.textMuted(isDarkMode);

    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final String displayName = userData?['name'] ?? 'User';
        final String displayEmail = userData?['email'] ?? '';
        final String adminId = (userData?['adminId'] ?? '').toString();

        final String photoUrl =
            userData?['photoUrl']?.toString().isNotEmpty == true
            ? userData!['photoUrl'].toString()
            : 'assets/image/L_image.png';

        final String academicLevel = userData?['academicLevel'] ?? 'Year 3';
        final String major = userData?['major'] ?? 'Science Major';

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your account and academic details.',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED).withOpacity(0.18),
                  side: const BorderSide(color: Color(0xFF7C3AED), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF7C3AED)),
                label: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PersonalInformationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: textSecondary),
                tooltip: 'Settings',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const Settingscreen(),
                    ),
                  );
                  _refreshProfile();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Main Card (Reference Layout)
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.35)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4C1D95),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: (photoUrl.isNotEmpty && photoUrl != 'assets/image/L_image.png')
                                    ? AppImageView(
                                        imageSource: photoUrl,
                                        fit: BoxFit.cover,
                                        width: 68,
                                        height: 68,
                                        placeholder: Center(
                                          child: Text(
                                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        errorWidget: Center(
                                          child: Text(
                                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'J',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  displayEmail.isNotEmpty ? displayEmail : 'student@university.edu',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _buildTag(Icons.science_outlined, major, isDarkMode),
                                    const SizedBox(width: 8),
                                    _buildTag(Icons.calendar_today_outlined, academicLevel, isDarkMode),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(height: 1, color: borderColor),
                      const SizedBox(height: 16),
                      // Four Stats Cards inside Profile
                      StreamBuilder<List<dynamic>>(
                        stream: _examService.getUserExamAttemptsStream(currentUserId),
                        builder: (context, attemptSnap) {
                          final attempts = attemptSnap.data ?? [];
                          final int examsCount = attempts.length;
                          double bestScore = 0;
                          for (var att in attempts) {
                            final sub = att['submission'] as StudentSubmissionModel?;
                            if (sub != null && sub.scorePercentage > bestScore) {
                              bestScore = sub.scorePercentage;
                            }
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.layers_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  value: '0',
                                  label: 'Classrooms',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.assignment_outlined,
                                  iconColor: const Color(0xFF7C3AED),
                                  value: '$examsCount',
                                  label: 'Exams Taken',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.emoji_events_outlined,
                                  iconColor: const Color(0xFFF59E0B),
                                  value: examsCount > 0 ? '${bestScore.toInt()}%' : '-',
                                  label: 'Best Score',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.trending_up_rounded,
                                  iconColor: const Color(0xFF10B981),
                                  value: examsCount > 0 ? '${bestScore.toInt()}%' : '0%',
                                  label: 'Overall Progress',
                                  surfaceColor: surfaceSec,
                                  borderColor: borderColor,
                                  textColor: textPrimary,
                                  labelColor: textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Badges Section (Matching Reference design)
                StreamBuilder<List<dynamic>>(
                  stream: _examService.getUserExamAttemptsStream(currentUserId),
                  builder: (context, attemptSnap) {
                    final attempts = attemptSnap.data ?? [];
                    final allBadges = _calculateBadges(attempts);

                    final topScorer = allBadges[1];
                    final earlyBird = allBadges[4];
                    final streakMaster = allBadges[6];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Badges',
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _showAllBadgesModal(allBadges),
                              child: const Row(
                                children: [
                                  Text(
                                    'View All',
                                    style: TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFF59E0B)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildBadgeItem(
                                topScorer.icon,
                                topScorer.bgLight,
                                topScorer.iconLight,
                                topScorer.title,
                                topScorer.isUnlocked,
                                isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBadgeItem(
                                earlyBird.icon,
                                earlyBird.bgLight,
                                earlyBird.iconLight,
                                earlyBird.title,
                                earlyBird.isUnlocked,
                                isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildBadgeItem(
                                streakMaster.icon,
                                streakMaster.bgLight,
                                streakMaster.iconLight,
                                streakMaster.title,
                                streakMaster.isUnlocked,
                                isDarkMode,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Account Management Menu
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Column(
                    children: [
                      _buildMenuRow(
                        Icons.person_outline_rounded,
                        'Personal Information',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Personal Information'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.school_outlined,
                        'Instructor Code',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction(
                          'Instructor UID',
                          currentAdminId: adminId,
                        ),
                        subtitle: adminId.isNotEmpty
                            ? adminId
                            : 'Tap to connect your instructor',
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.bookmark_outline_rounded,
                        'Saved Exams',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Saved Exams'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.settings_outlined,
                        'Settings',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Settings'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.privacy_tip_outlined,
                        'Privacy Policy',
                        textPrimary,
                        textSecondary,
                        () => _handleMenuAction('Privacy Policy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut)
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFEF4444),
                            ),
                          )
                        else
                          const Icon(Icons.logout_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isLoggingOut ? 'Logging out...' : 'Logout',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? surfaceColor,
    Color? borderColor,
    Color? textColor,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor ?? const Color(0xFF13192B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? const Color(0xFF28334D), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: labelColor ?? const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF7C3AED).withOpacity(0.12)
            : const Color(0xFF7C3AED).withOpacity(0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: const Color(0xFF7C3AED).withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
    IconData icon,
    Color bgCol,
    Color iconCol,
    String title,
    bool isUnlocked,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? (isDarkMode ? Colors.white12 : Colors.grey.shade200)
              : (isDarkMode ? Colors.white10 : Colors.grey.shade100),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (isDarkMode ? const Color(0xFF334155) : bgCol)
                  : (isDarkMode ? Colors.white10 : Colors.grey.shade200),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked
                  ? (isDarkMode ? const Color(0xFFFBBF24) : iconCol)
                  : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnlocked
                        ? (isDarkMode
                              ? const Color(0xFFF8FAFC)
                              : const Color(0xFF1E1B4B))
                        : (isDarkMode ? Colors.white38 : Colors.grey.shade500),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isUnlocked) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, color: Colors.green, size: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(
    IconData icon,
    String title,
    Color textColor,
    Color subtitleColor,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(isDarkMode ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
        onTap: onTap,
      ),
    );
  }
}
