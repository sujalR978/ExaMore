import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/screen/adminMenuDrawer.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Engineering',
    'Medicine',
    'Fine Arts',
    'Business Admin',
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

  void _handleStudentTap(String name) {
    print('Tapped student: $name');
  }

  void _handleLoadMore() {
    print('Load More Students clicked');
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

    // Student directory items
    final List<_StudentDirectoryData> students = [
      _StudentDirectoryData(
        name: 'Jane Cooper',
        department: 'Computer Science',
        id: '202401',
        isImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      ),
      _StudentDirectoryData(
        name: 'Wade Warren',
        department: 'Mechanical Eng',
        id: '202442',
        isImage: false,
        initials: 'WL',
        avatarBg: const Color(0xFFDBEAFE),
        avatarText: const Color(0xFF1D4ED8),
      ),
      _StudentDirectoryData(
        name: 'Cameron Williamson',
        department: 'Medicine',
        id: '202418',
        isImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
      ),
      _StudentDirectoryData(
        name: 'Brooklyn Simmons',
        department: 'Fine Arts',
        id: '202476',
        isImage: false,
        initials: 'BF',
        avatarBg: const Color(0xFFDBEAFE),
        avatarText: const Color(0xFF1D4ED8),
      ),
      _StudentDirectoryData(
        name: 'Leslie Alexander',
        department: 'Business Admin',
        id: '202409',
        isImage: true,
        imageUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&q=80&w=200',
      ),
    ];

    // Filter students by search and category
    final filteredStudents = students.where((student) {
      final matchesSearch =
          student.name.toLowerCase().contains(_searchQuery) ||
          student.id.toLowerCase().contains(_searchQuery) ||
          student.department.toLowerCase().contains(_searchQuery);

      if (_selectedCategoryIndex == 0) {
        return matchesSearch;
      }
      final selectedCat = _categories[_selectedCategoryIndex].toLowerCase();
      final matchesCategory = student.department.toLowerCase().contains(
        selectedCat,
      );

      return matchesSearch && matchesCategory;
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
                    'Student Directory',
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

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name, ID...",
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

            // Category Filter Chips Row
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
                      selectedColor: const Color(
                        0xFFFBBF24,
                      ), // Amber color matching screenshot selection
                      backgroundColor: containerColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1E1B4B)
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

            // Student List Cards
            if (filteredStudents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No students found matching "$_searchQuery"',
                    style: TextStyle(color: subtitleColor, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStudents.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  return _buildStudentCard(
                    name: student.name,
                    department: student.department,
                    id: student.id,
                    isImage: student.isImage,
                    imageUrl: student.imageUrl,
                    initials: student.initials,
                    avatarBg: student.avatarBg,
                    avatarText: student.avatarText,
                    containerColor: containerColor,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                    onTap: () => _handleStudentTap(student.name),
                  );
                },
              ),
            const SizedBox(height: 30),

            // Load More Students Button
            Center(
              child: SizedBox(
                width: 240,
                height: 48,
                child: OutlinedButton(
                  onPressed: _handleLoadMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(
                      color: const Color(0xFF1E1B4B),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Load More Students',
                        style: TextStyle(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1E1B4B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF1E1B4B),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String department,
    required String id,
    required bool isImage,
    String? imageUrl,
    String? initials,
    Color? avatarBg,
    Color? avatarText,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
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
        child: Row(
          children: [
            isImage
                ? CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(imageUrl ?? ''),
                  )
                : CircleAvatar(
                    radius: 28,
                    backgroundColor: avatarBg ?? const Color(0xFFDBEAFE),
                    child: Text(
                      initials ?? '',
                      style: TextStyle(
                        color: avatarText ?? const Color(0xFF1D4ED8),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$department • ID: $id',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StudentDirectoryData {
  final String name;
  final String department;
  final String id;
  final bool isImage;
  final String? imageUrl;
  final String? initials;
  final Color? avatarBg;
  final Color? avatarText;

  _StudentDirectoryData({
    required this.name,
    required this.department,
    required this.id,
    required this.isImage,
    this.imageUrl,
    this.initials,
    this.avatarBg,
    this.avatarText,
  });
}
