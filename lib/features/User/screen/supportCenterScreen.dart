import 'package:flutter/material.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _handleQuestionTap(String question) {
    print('Tapped question: $question');
  }

  void _handleEmailSupport() {
    print('Email Support clicked');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: () {
                      print('Menu clicked');
                    },
                  ),
                  title: Text(
                    'Support Center',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: const NetworkImage(
                          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                        ),
                      ),
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
            const SizedBox(height: 12),
            Text(
              'How can we\nhelp you today?',
              style: TextStyle(
                color: textColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers to common questions or reach out to our team.',
              style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search for articles, questions...",
                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: subtitleColor),
                filled: true,
                fillColor: containerColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.0),
                  borderSide: const BorderSide(
                    color: Color(0xFF7C3AED),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 28),

            // Popular Questions Header
            Text(
              'Popular Questions',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Popular Questions Container Box
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
                  _buildQuestionItem(
                    question: 'How do I reset my password?',
                    category: 'Account',
                    categoryBgColor: isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE0E7FF),
                    categoryTextColor: isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF3730A3),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onTap: () =>
                        _handleQuestionTap('How do I reset my password?'),
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildQuestionItem(
                    question:
                        'What happens if my internet disconnects during an exam?',
                    category: 'Technical',
                    categoryBgColor: isDarkMode
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFEF2F2),
                    categoryTextColor: const Color(0xFFDC2626),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onTap: () => _handleQuestionTap(
                      'What happens if my internet disconnects during an exam?',
                    ),
                  ),
                  Divider(height: 1, color: borderColor),
                  _buildQuestionItem(
                    question: 'How to upgrade to Premium?',
                    category: 'Billing',
                    categoryBgColor: isDarkMode
                        ? const Color(0xFF451A03)
                        : const Color(0xFFFEF3C7),
                    categoryTextColor: const Color(0xFFB45309),
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    onTap: () =>
                        _handleQuestionTap('How to upgrade to Premium?'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Still Need Help? Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our dedicated student support team is available 24/7 to assist you with any issues.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleEmailSupport,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mail_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Email Support',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildQuestionItem({
    required String question,
    required String category,
    required Color categoryBgColor,
    required Color categoryTextColor,
    required Color textColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: categoryBgColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: categoryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios, size: 14, color: subtitleColor),
          ],
        ),
      ),
    );
  }
}
