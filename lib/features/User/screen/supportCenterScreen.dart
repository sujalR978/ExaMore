import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // FAQ Data Structure
  final List<Map<String, String>> _faqList = [
    {
      'question': 'How do I reset my password?',
      'answer':
          'Go to the login screen and tap "Forgot Password". Enter your registered email address, and we will send you a password reset link within a few minutes.',
      'category': 'Account',
    },
    {
      'question': 'What happens if my internet disconnects during an exam?',
      'answer':
          'Examora caches your progress locally. If your connection drops, keep the app open. Your answers will automatically sync to the server once the connection is restored.',
      'category': 'Technical',
    },
    {
      'question': 'How do I upgrade to Premium?',
      'answer':
          'Navigate to Settings > Subscription and choose your preferred monthly or annual plan to unlock unlimited exams and performance analytics.',
      'category': 'Billing',
    },
    {
      'question': 'Where can I see my past exam results and analytics?',
      'answer':
          'Head over to the "Saved Exams" tab from your User Profile screen or access detailed performance breakdowns from the Dashboard.',
      'category': 'Exams',
    },
    {
      'question': 'Can I edit my profile information and picture?',
      'answer':
          'Yes! Open the User Profile screen, tap "Personal Information", and click the edit icon in the top right to update your name, major, or profile picture.',
      'category': 'Account',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Fetch current user's profile image from Firestore
  Future<String?> _fetchUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()?['photoUrl'] as String?;
      }
    } catch (e) {
      debugPrint("Error fetching user profile image: $e");
    }
    return null;
  }

  ImageProvider _resolveProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      );
    }
    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    } else {
      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      }
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      );
    }
  }

  // Open native email app
  Future<void> _handleEmailSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@examora.com',
      queryParameters: {
        'subject': 'Support Request - Examora App',
        'body': 'Hello Examora Support Team,\n\nI need help with:\n',
      },
    );

    try {
      final bool launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email client found. Contact: support@examora.com',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open email: $e')));
    }
  }

  // Show answer dialog when a question is tapped
  void _showAnswerDialog(String question, String answer, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: Color(0xFF6D28D9),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(answer, style: const TextStyle(fontSize: 15, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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

    // Filter FAQs by search input
    final filteredFaqs = _faqList.where((faq) {
      if (_searchQuery.isEmpty) return true;
      final q = (faq['question'] ?? '').toLowerCase();
      final a = (faq['answer'] ?? '').toLowerCase();
      final c = (faq['category'] ?? '').toLowerCase();
      return q.contains(_searchQuery) ||
          a.contains(_searchQuery) ||
          c.contains(_searchQuery);
    }).toList();

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
                      padding: const EdgeInsets.only(right: 12.0),
                      child: FutureBuilder<String?>(
                        future: _fetchUserProfileImage(),
                        builder: (context, snapshot) {
                          return CircleAvatar(
                            radius: 18,
                            backgroundImage: _resolveProfileImage(
                              snapshot.data,
                            ),
                          );
                        },
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

            // Search Bar with onChanged
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search for articles, questions...",
                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: subtitleColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
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

            // Filtered Questions Container Box
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No questions match "$_searchQuery"',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              )
            else
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
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredFaqs.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: borderColor),
                  itemBuilder: (context, index) {
                    final item = filteredFaqs[index];
                    final question = item['question']!;
                    final answer = item['answer']!;
                    final category = item['category']!;

                    Color catBg = isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE0E7FF);
                    Color catText = isDarkMode
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF3730A3);

                    if (category == 'Technical') {
                      catBg = isDarkMode
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFEF2F2);
                      catText = const Color(0xFFDC2626);
                    } else if (category == 'Billing') {
                      catBg = isDarkMode
                          ? const Color(0xFF451A03)
                          : const Color(0xFFFEF3C7);
                      catText = const Color(0xFFB45309);
                    }

                    return _buildQuestionItem(
                      question: question,
                      category: category,
                      categoryBgColor: catBg,
                      categoryTextColor: catText,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      onTap: () =>
                          _showAnswerDialog(question, answer, category),
                    );
                  },
                ),
              ),
            const SizedBox(height: 28),

            // Still Need Help? Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
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
