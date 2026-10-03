import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/CandidateDetailScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


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
  final ExamService _examService = ExamService();

  String _searchQuery = '';

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

  void _handleViewDetails({
    required String examId,
    required StudentSubmissionModel submission,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CandidateDetailScreen(
          examId: examId,
          submissionId: submission.id,
          initialData: submission,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'ST';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final containerColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      drawer: const AdminMenuDrawer(),
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
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _examService.getAllRecentSubmissionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error loading results: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allResults = snapshot.data ?? [];

          // Local Search Filter
          final filteredResults = allResults.where((item) {
            final submission = item['submission'] as StudentSubmissionModel;
            return submission.studentName
                    .toLowerCase()
                    .contains(_searchQuery) ||
                submission.examTitle.toLowerCase().contains(_searchQuery) ||
                submission.studentId.toLowerCase().contains(_searchQuery);
          }).toList();

          return SingleChildScrollView(
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
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search students or exams...",
                    hintStyle: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: subtitleColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: subtitleColor,
                              size: 18,
                            ),
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
                        allResults.isEmpty
                            ? 'No student results submitted yet.'
                            : 'No student results found matching "$_searchQuery"',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
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
                      final examId = item['examId'] as String;
                      final submission =
                          item['submission'] as StudentSubmissionModel;

                      return _buildResultCard(
                        studentName: submission.studentName,
                        examTitle: submission.examTitle,
                        score: '${submission.scorePercentage.toInt()}%',
                        isPassed: submission.isPassed,
                        imageUrl: submission.studentImageUrl,
                        initials: _getInitials(submission.studentName),
                        containerColor: containerColor,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                        onViewDetails: () => _handleViewDetails(
                          examId: examId,
                          submission: submission,
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCard({
    required String studentName,
    required String examTitle,
    required String score,
    required bool isPassed,
    required String initials,
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
              imageUrl != null && imageUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(imageUrl),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: isPassed
                          ? const Color(0xFF312E81)
                          : const Color(0xFFFEF2F2),
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: isPassed
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFFDC2626),
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
                      backgroundColor: const Color(0xFF4C1D95),
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