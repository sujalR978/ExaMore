import 'package:flutter/material.dart';

class Settingscreen extends StatefulWidget {
  const Settingscreen({super.key});

  @override
  State<Settingscreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<Settingscreen> {
  // Toggle states for notification settings
  bool _examReminders = true;
  bool _resultAnnouncements = true;
  bool _streakAlerts = false;
  bool _systemUpdates = true;

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
      // Capsule-shaped Top Bar
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
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
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
                      onPressed: () {
                        // TODO: Implement your app-wide theme toggle logic here
                        print(
                          'Theme toggle clicked. Current mode: ${isDarkMode ? 'Dark' : 'Light'}',
                        );
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
            const SizedBox(height: 24),

            // Toggles Container Box
            Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.02),
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
                    onChanged: (val) {
                      setState(() {
                        _examReminders = val;
                      });
                    },
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
                    onChanged: (val) {
                      setState(() {
                        _resultAnnouncements = val;
                      });
                    },
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
                    onChanged: (val) {
                      setState(() {
                        _streakAlerts = val;
                      });
                    },
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
                    onChanged: (val) {
                      setState(() {
                        _systemUpdates = val;
                      });
                    },
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
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFBBF24),
            activeTrackColor: const Color(0xFF1E1B4B),
          ),
        ],
      ),
    );
  }
}
