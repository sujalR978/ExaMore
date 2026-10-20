import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';
import 'package:prep_mate/features/Auth/screens/login.dart';
import 'package:prep_mate/features/Auth/services/auth_service.dart';
import 'package:prep_mate/features/User/screen/presnoalInformation.dart';
import 'package:prep_mate/features/User/screen/savedExamScreen.dart';
import 'package:prep_mate/features/User/screen/settingScreen.dart';
import 'package:prep_mate/features/User/screen/supportCenterScreen.dart';

// Definition of an achievement badge
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

  // Fetch current user details from Firestore
  Future<Map<String, dynamic>?> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (user.email == 'admin@gmail.com') {
      return {
        'name': 'Admin User',
        'email': 'admin@gmail.com',
        'photoUrl':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
        'academicLevel': 'System Administrator',
        'major': 'Computer Science',
      };
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  // Evaluate user submissions to compute earned and locked badges
  List<BadgeItem> _calculateBadges(List<Map<String, dynamic>> attempts) {
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

    // Calculate streak
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

  void _handleMenuAction(String title) async {
    if (title == 'Personal Information') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PersonalInformationScreen(),
        ),
      );
      _refreshProfile();
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
    }
  }

  void _handleLogout() async {
    setState(() => _isLoggingOut = true);

    try {
      final AuthService authService = AuthService();
      await authService.signOut();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
        setState(() => _isLoggingOut = false);
      }
    }
  }

  ImageProvider _getProfileImage(String photoUrl) {
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    } else {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return const NetworkImage(
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
        );
      }
    }
  }

  // Modal to show all available badges and their progress
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

    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? '';

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data;
        final String displayName = userData?['name'] ?? 'User';
        final String displayEmail = userData?['email'] ?? '';
        final String photoUrl =
            userData?['photoUrl'] ??
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200';
        final String academicLevel = userData?['academicLevel'] ?? 'Year 3';
        final String major = userData?['major'] ?? 'Science Major';

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
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
                      leading: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundImage: _getProfileImage(photoUrl),
                        ),
                      ),
                      title: Text(
                        'Examora',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.settings_outlined, color: textColor),
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const Settingscreen(),
                              ),
                            );
                            _refreshProfile();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundImage: _getProfileImage(photoUrl),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: containerColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayEmail.isNotEmpty
                            ? displayEmail
                            : 'Academic Level: $academicLevel',
                        style: TextStyle(color: subtitleColor, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTag(Icons.science_outlined, major, isDarkMode),
                          const SizedBox(width: 8),
                          _buildTag(
                            Icons.school_outlined,
                            academicLevel,
                            isDarkMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dynamic Badges Card Stream
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _examService.getUserExamAttemptsStream(currentUserId),
                  builder: (context, attemptSnap) {
                    final attempts = attemptSnap.data ?? [];
                    final allBadges = _calculateBadges(attempts);

                    final topScorer = allBadges[1];
                    final earlyBird = allBadges[4];
                    final streakMaster = allBadges[6];

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFF59E0B),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Badges',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${allBadges.where((b) => b.isUnlocked).length} Unlocked',
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                              const SizedBox(width: 12),
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showAllBadgesModal(allBadges),
                                  borderRadius: BorderRadius.circular(16),
                                  child: _buildDashedBadge(
                                    'View All',
                                    borderColor,
                                    textColor,
                                    isDarkMode,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Menu Options Card
                Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildMenuRow(
                        Icons.person_outline,
                        'Personal Information',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Personal Information'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.bookmark_border,
                        'Saved Exams',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Saved Exams'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.notifications_outlined,
                        'Notification Settings',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Settings'),
                      ),
                      Divider(height: 1, color: borderColor),
                      _buildMenuRow(
                        Icons.help_outline,
                        'Help & Support',
                        textColor,
                        subtitleColor,
                        () => _handleMenuAction('Help & Support'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoggingOut ? null : _handleLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoggingOut)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        else
                          const Icon(Icons.logout, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isLoggingOut ? 'Logging out...' : 'Logout',
                          style: const TextStyle(
                            fontSize: 16,
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

  Widget _buildTag(IconData icon, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDarkMode
                ? const Color(0xFF93C5FD)
                : const Color(0xFF1E1B4B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDarkMode
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF1E1B4B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
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

  Widget _buildDashedBadge(
    String title,
    Color borderColor,
    Color textColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white30 : Colors.grey.shade400,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_outlined, color: textColor, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
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
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subtitleColor),
      onTap: onTap,
    );
  }
}
