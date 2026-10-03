import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';
import 'package:prep_mate/features/Admin/services/exam_service.dart';


class ExamAnalyticsDetailScreen extends StatefulWidget {
  final ExamModel? exam;

  const ExamAnalyticsDetailScreen({super.key, this.exam});

  @override
  State<ExamAnalyticsDetailScreen> createState() =>
      _ExamAnalyticsDetailScreenState();
}

class _ExamAnalyticsDetailScreenState extends State<ExamAnalyticsDetailScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ExamService _examService = ExamService();

  late ExamModel _exam;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _exam = widget.exam ??
        ExamModel(
          id: 'demo_id',
          examCode: 'EXM-8924A',
          title: 'Finals 2024 – Advanced Physics',
          category: 'Physics',
          durationMinutes: 120,
          totalMarks: 100,
          passingScorePercentage: 50.0,
          enrolledCount: 145,
          status: 'Published',
        );

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
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.menu_book,
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    'Examora',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFF1E1B4B),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  centerTitle: false,
                  actions: const [
                    Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFFBBF24),
                        child: Text(
                          'AP',
                          style: TextStyle(
                            color: Color(0xFF1E1B4B),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
      body: StreamBuilder<List<StudentSubmissionModel>>(
        stream: _examService.getExamSubmissionsStream(_exam.id),
        builder: (context, snapshot) {
          final submissions = snapshot.data ?? [];

          // Compute analytics metrics dynamically
          final totalSubmissions = submissions.length;
          final averageScore = totalSubmissions > 0
              ? (submissions.map((s) => s.scorePercentage).reduce((a, b) => a + b) /
                      totalSubmissions)
                  .toStringAsFixed(0)
              : '0';

          final passedCount = submissions.where((s) {
            return s.isPassed ||
                s.scorePercentage >= _exam.passingScorePercentage;
          }).length;

          final passRate = totalSubmissions > 0
              ? ((passedCount / totalSubmissions) * 100).toStringAsFixed(0)
              : '0';

          final topScore = totalSubmissions > 0
              ? submissions
                  .map((s) => s.scorePercentage)
                  .reduce((a, b) => a > b ? a : b)
                  .toStringAsFixed(0)
              : '0';

          final filteredSubmissions = submissions.where((student) {
            return student.studentName.toLowerCase().contains(_searchQuery) ||
                student.studentId.toLowerCase().contains(_searchQuery);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back to Modules link
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 16,
                        color: isDarkMode
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF1E1B4B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Back to Modules',
                        style: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF1E1B4B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Exam Title & Status Header
                Text(
                  _exam.title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '# ${_exam.examCode.isNotEmpty ? _exam.examCode : _exam.id.substring(0, 6)}',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _exam.status.toLowerCase() == 'published'
                            ? (isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                            : (isDarkMode
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF3C7)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _exam.status,
                        style: TextStyle(
                          color: _exam.status.toLowerCase() == 'published'
                              ? (isDarkMode
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF065F46))
                              : const Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2x2 Metric Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.25,
                  children: [
                    _buildMetricCard(
                      title: 'AVERAGE SCORE',
                      value: '$averageScore%',
                      icon: Icons.assessment_outlined,
                      iconColor: const Color(0xFFD97706),
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMetricCard(
                      title: 'PASS RATE',
                      value: '$passRate%',
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF059669),
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMetricCard(
                      title: 'TOP SCORE',
                      value: '$topScore%',
                      icon: Icons.emoji_events_outlined,
                      iconColor: const Color(0xFFD97706),
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                    ),
                    _buildMetricCard(
                      title: 'SUBMISSIONS',
                      value:
                          '$totalSubmissions/${_exam.enrolledCount > 0 ? _exam.enrolledCount : totalSubmissions}',
                      icon: Icons.people_outline,
                      iconColor: const Color(0xFF1D4ED8),
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Student Results Container Box (Table layout)
                Container(
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(24),
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
                      // Title & Search
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Student Results',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search students...",
                                hintStyle: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: subtitleColor,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear,
                                            color: subtitleColor, size: 18),
                                        onPressed: () =>
                                            _searchController.clear(),
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1E293B).withOpacity(0.5)
                              : const Color(0xFFF8FAFC),
                          border: Border(
                            top: BorderSide(color: borderColor),
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                'STUDENT',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'ID',
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'SCORE',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Student Rows
                      if (filteredSubmissions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: Center(
                            child: Text(
                              submissions.isEmpty
                                  ? 'No student submissions yet'
                                  : 'No students found matching "$_searchQuery"',
                              style: TextStyle(
                                  color: subtitleColor, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredSubmissions.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final student = filteredSubmissions[index];
                            final isFailed = !student.isPassed &&
                                student.scorePercentage <
                                    _exam.passingScorePercentage;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isFailed
                                    ? (isDarkMode
                                        ? const Color(0xFF451A03)
                                            .withOpacity(0.3)
                                        : const Color(0xFFFEF2F2))
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  // Student Name & Avatar
                                  Expanded(
                                    flex: 5,
                                    child: Row(
                                      children: [
                                        student.studentImageUrl != null &&
                                                student.studentImageUrl!
                                                    .isNotEmpty
                                            ? CircleAvatar(
                                                radius: 18,
                                                backgroundImage: NetworkImage(
                                                  student.studentImageUrl!,
                                                ),
                                              )
                                            : CircleAvatar(
                                                radius: 18,
                                                backgroundColor: isFailed
                                                    ? const Color(0xFFFEF2F2)
                                                    : const Color(0xFFDBEAFE),
                                                child: Text(
                                                  _getInitials(
                                                      student.studentName),
                                                  style: TextStyle(
                                                    color: isFailed
                                                        ? const Color(
                                                            0xFFDC2626)
                                                        : const Color(
                                                            0xFF1D4ED8),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            student.studentName,
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ID
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      student.studentId,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // Score
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '${student.scorePercentage.toInt()}%',
                                        style: TextStyle(
                                          color: isFailed
                                              ? const Color(0xFFDC2626)
                                              : textColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                      // Results Count Summary Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: borderColor)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${filteredSubmissions.length} of ${submissions.length} results',
                              style:
                                  TextStyle(color: subtitleColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}