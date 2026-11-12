import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[700]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(75),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.05),
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
                    'Privacy Policy',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(24),
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
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Examora Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Last updated: October 2026',
                          style: TextStyle(fontSize: 12, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: borderColor),
              const SizedBox(height: 16),
              _buildSection(
                title: '1. Information We Collect',
                content:
                    '• Personal Details: Name, email address, academic level, and major collected during registration.\n'
                    '• Photos & Avatars: User-selected profile pictures stored securely for identification.\n'
                    '• Assessment Records: Exam submissions, scores, answers, time spent, and badge progression.\n'
                    '• Administrative Uploads: Question bank files (CSV/JSON) imported by authorized examiners.',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              _buildSection(
                title: '2. Use of Information',
                content:
                    'Your data is used strictly for authentication, serving examinations, tracking study streaks, generating performance metrics, and preventing unauthorized test retakes (two-attempt limit enforcement). We do not display third-party advertisements or sell user information.',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              _buildSection(
                title: '3. Data Security & Storage',
                content:
                    'All authentication and persistent data are secured through Google Firebase (Authentication & Cloud Firestore) utilizing role-based access rules and TLS encryption in transit.',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              _buildSection(
                title: '4. Account & Data Deletion',
                content:
                    'You have the legal right to delete your account and all associated submissions at any time. You can perform this within the app via "Settings > Delete Account" or submit an online deletion request through our web portal at https://examora-441d4.web.app/delete-account.',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
              _buildSection(
                title: '5. Contact Support',
                content:
                    'For privacy inquiries or technical questions regarding your personal information, reach out to our team at support@examora.com.',
                textColor: textColor,
                subtitleColor: subtitleColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: subtitleColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}