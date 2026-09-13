import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/CandidateDetailScreen.dart';

import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class RecentResultsAndUsersScreen extends StatefulWidget {
  const RecentResultsAndUsersScreen({super.key});

  @override
  State<RecentResultsAndUsersScreen> createState() =>
      _RecentResultsAndUsersScreenState();
}

class _RecentResultsAndUsersScreenState
    extends State<RecentResultsAndUsersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleViewDetails(String studentName, String examTitle) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => CandidateDetailScreen()));
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

    // List of student mock test results
    final List<_StudentResult> results = [
      _StudentResult(
        name: 'Jane Doe',
        exam: 'Advanced Calculus - Mock A',
        score: '92%',
        isPassed: true,
        isAvatarImage: false,
        avatarText: 'JD',
        avatarBgColor: const Color(0xFF312E81),
        avatarTextColor: const Color(0xFF93C5FD),
      ),
      _StudentResult(
        name: 'Alex Smith',
        exam: 'Organic Chemistry - Final Prep',
        score: '45%',
        isPassed: false,
        isAvatarImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      ),
      _StudentResult(
        name: 'Elena Petrova',
        exam: 'Physics 101 - Midterm Mock',
        score: '78%',
        isPassed: true,
        isAvatarImage: false,
        avatarText: 'EP',
        avatarBgColor: const Color(0xFFDBEAFE),
        avatarTextColor: const Color(0xFF1D4ED8),
      ),
    ];

    // Filter results based on search query
    final filteredResults = results.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.exam.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
drawer: AdminMenuDrawer(),
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
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                  title: Text(
                    'Exam Administration',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
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
            const SizedBox(height: 8),
            Text(
              'Recent Results & Users',
              style: TextStyle(
                color: textColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Review recent mock test performance across cohorts.',
              style: TextStyle(color: subtitleColor, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search students...",
                hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: subtitleColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                        onPressed: () => _searchController.clear(),
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
            const SizedBox(height: 20),

            // Results List
            if (filteredResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No student results found matching "$_searchQuery"',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredResults.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = filteredResults[index];
                  return _buildResultCard(
                    studentName: item.name,
                    examTitle: item.exam,
                    score: item.score,
                    isPassed: item.isPassed,
                    isAvatarImage: item.isAvatarImage,
                    avatarText: item.avatarText,
                    avatarBgColor: item.avatarBgColor,
                    avatarTextColor: item.avatarTextColor,
                    imageUrl: item.imageUrl,
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                    onViewDetails: () =>
                        _handleViewDetails(item.name, item.exam),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String studentName,
    required String examTitle,
    required String score,
    required bool isPassed,
    required bool isAvatarImage,
    String? avatarText,
    Color? avatarBgColor,
    Color? avatarTextColor,
    String? imageUrl,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onViewDetails,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              isAvatarImage
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(imageUrl ?? ''),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: avatarBgColor ?? const Color(0xFF312E81),
                      child: Text(
                        avatarText ?? '',
                        style: TextStyle(
                          color: avatarTextColor ?? Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      examTitle,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    score,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? (isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                          : (isDarkMode
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF2F2)),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      isPassed ? 'Passed' : 'Failed',
                      style: TextStyle(
                        color: isPassed
                            ? (isDarkMode
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF065F46))
                            : const Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C1D95), // Deep Indigo
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentResult {
  final String name;
  final String exam;
  final String score;
  final bool isPassed;
  final bool isAvatarImage;
  final String? avatarText;
  final Color? avatarBgColor;
  final Color? avatarTextColor;
  final String? imageUrl;

  _StudentResult({
    required this.name,
    required this.exam,
    required this.score,
    required this.isPassed,
    required this.isAvatarImage,
    this.avatarText,
    this.avatarBgColor,
    this.avatarTextColor,
    this.imageUrl,
  });
}
