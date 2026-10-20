import 'package:flutter/material.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<Settingscreen> {
  // Master flag: Set this to false once backend/functionality is live
  final bool _isFeatureAvailable = false;

  // Toggle states
  bool _examReminders = false;
  bool _resultAnnouncements = false;
  bool _streakAlerts = false;
  bool _systemUpdates = false;

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
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: Icon(
                        isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        color: const Color(0xFFFBBF24),
                      ),
                      onPressed: () {},
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
            const SizedBox(height: 8),
            Text(
              'Notification Preferences',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Control what alerts and updates you receive from Examora.',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 16),

            // Top notice banner indicating whole section is upcoming
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These notification services are under development and will be available in a future update.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toggles Container Box
            Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
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
                  _buildSwitchTile(
                    icon: Icons.notifications_active_outlined,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Exam Reminders',
                    subtitle: 'Get notified before your scheduled exams start.',
                    value: _examReminders,
                    isAvailable: _isFeatureAvailable,
                    onChanged: (val) => setState(() => _examReminders = val),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSwitchTile(
                    icon: Icons.assignment_turned_in_outlined,
                    iconColor: const Color(0xFF059669),
                    title: 'Result Announcements',
                    subtitle:
                        'Receive instant alerts when your score is posted.',
                    value: _resultAnnouncements,
                    isAvailable: _isFeatureAvailable,
                    onChanged: (val) =>
                        setState(() => _resultAnnouncements = val),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSwitchTile(
                    icon: Icons.local_fire_department_outlined,
                    iconColor: const Color(0xFFD97706),
                    title: 'Streak Alerts',
                    subtitle: 'Daily reminders to maintain your study streak.',
                    value: _streakAlerts,
                    isAvailable: _isFeatureAvailable,
                    onChanged: (val) => setState(() => _streakAlerts = val),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildSwitchTile(
                    icon: Icons.system_update_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'System & Feature Updates',
                    subtitle: 'News about new features and app improvements.',
                    value: _systemUpdates,
                    isAvailable: _isFeatureAvailable,
                    onChanged: (val) => setState(() => _systemUpdates = val),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subtitleColor,
    required bool isDarkMode,
    required bool isAvailable,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: !isAvailable
                  ? iconColor.withValues(alpha: 0.4)
                  : iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: !isAvailable
                              ? textColor.withValues(alpha: 0.75)
                              : textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Text(
                          'Available in Future',
                          style: TextStyle(
                            color: isDarkMode
                                ? const Color(0xFFFBBF24)
                                : const Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor.withValues(
                      alpha: !isAvailable ? 0.65 : 1.0,
                    ),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: !isAvailable ? false : value,
            onChanged: !isAvailable ? null : onChanged,
            activeColor: const Color(0xFFFBBF24),
            activeTrackColor: const Color(0xFF1E1B4B),
          ),
        ],
      ),
    );
  }
}
