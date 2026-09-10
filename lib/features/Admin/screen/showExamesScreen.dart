import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/ExamAnalyticsDetailScreen.dart';
import 'package:prep_mate/features/Admin/screen/adminHomeScreen.dart';

class Showexamesscreen extends StatefulWidget {
  const Showexamesscreen({super.key});

  @override
  State<Showexamesscreen> createState() => _ActiveExamsScreenState();
}

class _ActiveExamsScreenState extends State<Showexamesscreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Mathematics',
    'Science',
    'History',
    'Physics',
  ];

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

  void _handleAction(String actionName, String examTitle) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ExamAnalyticsDetailScreen()),
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

    // List of active/draft exams
    final List<_ExamItemData> exams = [
      _ExamItemData(
        title: 'Finals 2024 – Advanced Physics',
        id: 'EXM-2024-089',
        category: 'Physics',
        status: 'Published',
        isPublished: true,
        startDate: 'Oct 24, 09:00 AM',
        duration: '120 mins',
        enrolled: '145 Students',
        submissions: '0 / 145',
        isSubmissionsMetric: true,
      ),
      _ExamItemData(
        title: 'Midterm – Calculus III',
        id: 'EXM-2024-092',
        category: 'Mathematics',
        status: 'Draft',
        isPublished: false,
        startDate: 'Nov 02, 10:00 AM',
        duration: '90 mins',
        enrolled: '82 Students',
        submissions: '45 Qs',
        isSubmissionsMetric: false,
      ),
      _ExamItemData(
        title: 'Quiz 3 – Organic Chemistry',
        id: 'EXM-2024-071',
        category: 'Science',
        status: 'Published',
        isPublished: true,
        startDate: 'Oct 26, 02:00 PM',
        duration: '45 mins',
        enrolled: '210 Students',
        submissions: '0 / 210',
        isSubmissionsMetric: true,
      ),
    ];

    // Filter exams based on search query and category chip selection
    final filteredExams = exams.where((exam) {
      final matchesSearch =
          exam.title.toLowerCase().contains(_searchQuery) ||
          exam.id.toLowerCase().contains(_searchQuery);

      if (_selectedCategoryIndex == 0) {
        return matchesSearch;
      }
      final selectedCategoryName = _categories[_selectedCategoryIndex];
      final matchesCategory =
          exam.category.toLowerCase() == selectedCategoryName.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color(0xFF1E1B4B)
                    : const Color(0xFF1E1B4B),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Examora Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Navigation Menu',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AdminHomeScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Active Exams'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
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
              'Active Exams',
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search exams by title or ID...",
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
            const SizedBox(height: 16),

            // Filter Category Chips Row
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_categories[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      selectedColor: const Color(0xFF1E1B4B),
                      backgroundColor: containerColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF1E1B4B)),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : borderColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // List of Exams
            if (filteredExams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No exams found matching your search',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredExams.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final exam = filteredExams[index];
                  return _buildExamCard(
                    title: exam.title,
                    id: exam.id,
                    status: exam.status,
                    isPublished: exam.isPublished,
                    startDate: exam.startDate,
                    duration: exam.duration,
                    enrolled: exam.enrolled,
                    submissions: exam.submissions,
                    isSubmissionsMetric: exam.isSubmissionsMetric,
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                    onPrimaryAction: () => _handleAction(
                      exam.isPublished ? 'View Results' : 'Publish Exam',
                      exam.title,
                    ),
                    onEdit: () => _handleAction('Edit', exam.title),
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard({
    required String title,
    required String id,
    required String status,
    required bool isPublished,
    required String startDate,
    required String duration,
    required String enrolled,
    required String submissions,
    required bool isSubmissionsMetric,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onPrimaryAction,
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPublished
                          ? (isDarkMode
                                ? const Color(0xFF064E3B)
                                : const Color(0xFFD1FAE5))
                          : (isDarkMode
                                ? const Color(0xFF451A03)
                                : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isPublished
                            ? (isDarkMode
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF065F46))
                            : const Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: $id',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: subtitleColor, size: 20),
                onPressed: () {
                  print('More options clicked for $title');
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Details Grid (Start Date, Duration, Enrolled, Submissions/Questions)
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Date',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          startDate,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: subtitleColor),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          duration,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 16, color: subtitleColor),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enrolled',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enrolled,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isSubmissionsMetric
                          ? Icons.assignment_turned_in_outlined
                          : Icons.list_alt,
                      size: 16,
                      color: subtitleColor,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSubmissionsMetric ? 'Submissions' : 'Questions',
                          style: TextStyle(color: subtitleColor, fontSize: 11),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          submissions,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 16),

          // Action Buttons Row (View Results / Publish Exam & Edit)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPublished
                          ? const Color(0xFF4C1D95)
                          : const Color(0xFFFBBF24),
                      foregroundColor: isPublished
                          ? Colors.white
                          : const Color(0xFF1E1B4B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPublished
                              ? Icons.visibility_outlined
                              : Icons.cloud_upload_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPublished ? 'View Results' : 'Publish Exam',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(color: borderColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExamItemData {
  final String title;
  final String id;
  final String category;
  final String status;
  final bool isPublished;
  final String startDate;
  final String duration;
  final String enrolled;
  final String submissions;
  final bool isSubmissionsMetric;

  _ExamItemData({
    required this.title,
    required this.id,
    required this.category,
    required this.status,
    required this.isPublished,
    required this.startDate,
    required this.duration,
    required this.enrolled,
    required this.submissions,
    required this.isSubmissionsMetric,
  });
}
