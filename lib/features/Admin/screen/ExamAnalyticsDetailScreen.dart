import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class ExamAnalyticsDetailScreen extends StatefulWidget {
  const ExamAnalyticsDetailScreen({super.key});

  @override
  State<ExamAnalyticsDetailScreen> createState() =>
      _ExamAnalyticsDetailScreenState();
}

class _ExamAnalyticsDetailScreenState
    extends State<ExamAnalyticsDetailScreen> {
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

    // Student performance rows
    final List<_StudentResultData> students = [
      _StudentResultData(
        name: 'Elena Rostova',
        id: 'STU-1042',
        score: '98%',
        isImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      ),
      _StudentResultData(
        name: 'James Miller',
        id: 'STU-1088',
        score: '76%',
        isImage: false,
        initials: 'JM',
        avatarBg: const Color(0xFFDBEAFE),
        avatarText: const Color(0xFF1D4ED8),
      ),
      _StudentResultData(
        name: 'Sarah Watanabe',
        id: 'STU-1102',
        score: '42%',
        isImage: false,
        initials: 'SW',
        avatarBg: const Color(0xFFFEF2F2),
        avatarText: const Color(0xFFDC2626),
        isFailedRow: true,
      ),
      _StudentResultData(
        name: 'Marcus Johnson',
        id: 'STU-1145',
        score: '88%',
        isImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      ),
    ];

    // Filter students based on search query
    final filteredStudents = students.where((student) {
      return student.name.toLowerCase().contains(_searchQuery) ||
          student.id.toLowerCase().contains(_searchQuery);
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
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFFFBBF24),
                        child: const Text(
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
      body: SingleChildScrollView(
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
              'Finals 2024 – Advanced Physics',
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
                  '# EXM-8924A',
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
                    color: isDarkMode
                        ? const Color(0xFF064E3B)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Published',
                    style: TextStyle(
                      color: isDarkMode
                          ? const Color(0xFF34D399)
                          : const Color(0xFF065F46),
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
                  value: '78%',
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
                  value: '85%',
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
                  value: '98%',
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
                  value: '145/145',
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
                  if (filteredStudents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Center(
                        child: Text(
                          'No students found',
                          style: TextStyle(color: subtitleColor, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredStudents.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: borderColor),
                      itemBuilder: (context, index) {
                        final student = filteredStudents[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: student.isFailedRow
                                ? (isDarkMode
                                      ? const Color(0xFF451A03).withOpacity(0.3)
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
                                    student.isImage
                                        ? CircleAvatar(
                                            radius: 18,
                                            backgroundImage: NetworkImage(
                                              student.imageUrl ?? '',
                                            ),
                                          )
                                        : CircleAvatar(
                                            radius: 18,
                                            backgroundColor: student.avatarBg,
                                            child: Text(
                                              student.initials ?? '',
                                              style: TextStyle(
                                                color: student.avatarText,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        student.name,
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
                                  student.id,
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
                                    student.score,
                                    style: TextStyle(
                                      color: student.isFailedRow
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

                  // Pagination Footer
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
                          'Showing 1 to 4 of 145 results',
                          style: TextStyle(color: subtitleColor, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.chevron_left,
                              size: 18,
                              color: subtitleColor,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '1',
                              style: TextStyle(
                                color: Color(0xFF7C3AED),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '2',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '...',
                              style: TextStyle(color: subtitleColor),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '37',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: textColor,
                            ),
                          ],
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

class _StudentResultData {
  final String name;
  final String id;
  final String score;
  final bool isImage;
  final String? imageUrl;
  final String? initials;
  final Color? avatarBg;
  final Color? avatarText;
  final bool isFailedRow;

  _StudentResultData({
    required this.name,
    required this.id,
    required this.score,
    required this.isImage,
    this.imageUrl,
    this.initials,
    this.avatarBg,
    this.avatarText,
    this.isFailedRow = false,
  });
}