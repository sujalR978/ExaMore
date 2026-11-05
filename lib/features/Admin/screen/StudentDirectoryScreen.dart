// ignore_for_file: deprecated_member_use, file_names

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FocusNode _searchFocusNode = FocusNode();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  String _userRole = 'admin';
  bool _isLoadingRole = true;

  // Storing the Stream reference prevents rebuilding the entire stream on setState
  Stream<QuerySnapshot>? _studentStream;

  @override
  void initState() {
    super.initState();
    _initRoleAndStream();
  }

  Future<void> _initRoleAndStream() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoadingRole = false);
      return;
    }

    if (_currentUser.email?.toLowerCase() == 'admin@gmail.com') {
      _userRole = 'super_admin';
    } else {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser.uid)
            .get();

        if (doc.exists) {
          _userRole = (doc.data()?['role'] ?? 'admin').toString().toLowerCase();
        }
      } catch (_) {}
    }

    final bool isSuperAdmin =
        _userRole == 'super_admin' ||
        _currentUser.email?.toLowerCase() == 'admin@gmail.com';
    final uid = _currentUser.uid;

    // Initialize the stream ONCE
    if (isSuperAdmin) {
      _studentStream = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .snapshots();
    } else {
      _studentStream = FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('adminId', isEqualTo: uid)
          .snapshots();
    }

    if (mounted) {
      setState(() {
        _isLoadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  ImageProvider _getProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) {
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

  void _showStudentInfo(Map<String, dynamic> studentData) {
    final String name = studentData['name']?.toString() ?? 'Unnamed Student';
    final String email = studentData['email']?.toString() ?? 'No email';
    final String phone = studentData['phone']?.toString() ?? 'No phone';
    final String major =
        studentData['major']?.toString() ??
        studentData['department']?.toString() ??
        'General';
    final String academicLevel =
        studentData['academicLevel']?.toString() ?? 'N/A';
    final String photoUrl = studentData['photoUrl']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: _getProfileImage(photoUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            _buildInfoRow(Icons.email_outlined, 'Email', email),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
            const SizedBox(height: 10),
            _buildInfoRow(Icons.science_outlined, 'Major', major),
            const SizedBox(height: 10),
            _buildInfoRow(
              Icons.school_outlined,
              'Academic Level',
              academicLevel,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteUser(String uid, String studentName) {
    final BuildContext parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Are you sure?', style: TextStyle(color: Colors.red)),
        content: Text(
          'Do you want to delete "$studentName" from the directory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .delete();

                if (!mounted) return;

                showDialog(
                  context: parentContext,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Success'),
                      ],
                    ),
                    content: Text(
                      '"$studentName" has been deleted successfully.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'OK',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(content: Text('Failed to delete user: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _normalizeMajor(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('major', '')
        .replaceAll('department', '')
        .replaceAll('&', '')
        .trim();
  }

  bool _checkCategoryMatch(String majorInDb, String selectedCategory) {
    if (selectedCategory.toLowerCase() == 'all') return true;

    final normDb = _normalizeMajor(majorInDb);
    final normCat = _normalizeMajor(selectedCategory);

    if (normDb == normCat) return true;

    if (normCat == 'science') {
      return normDb == 'science' ||
          normDb == 'pure science' ||
          normDb == 'general science';
    }

    if (normCat == 'computer science') {
      return normDb.contains('computer') ||
          normDb.contains('cs') ||
          normDb.contains('software');
    }

    return normDb.contains(normCat) || normCat.contains(normDb);
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

    if (_isLoadingRole || _studentStream == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isSuperAdmin =
        _userRole == 'super_admin' ||
        _currentUser?.email?.toLowerCase() == 'admin@gmail.com';

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
                    color: Colors.black.withValues(
                      alpha: isDarkMode ? 0.2 : 0.05,
                    ),
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
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  title: Text(
                    isSuperAdmin ? 'All System Students' : 'My Students',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _studentStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading students: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          final studentDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final role = (data['role'] ?? 'student').toString().toLowerCase();
            return role == 'student';
          }).toList();

          final Set<String> dynamicCategories = {'All'};
          for (final doc in studentDocs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final major =
                data['major']?.toString() ??
                data['department']?.toString() ??
                '';
            if (major.trim().isNotEmpty) {
              dynamicCategories.add(major.trim());
            }
          }

          if (dynamicCategories.length == 1) {
            dynamicCategories.addAll([
              'Science Major',
              'Computer Science',
              'Medicine',
              'Business Admin',
            ]);
          }

          final categoriesList = dynamicCategories.toList();
          if (_selectedCategoryIndex >= categoriesList.length) {
            _selectedCategoryIndex = 0;
          }

          final selectedCatName = categoriesList[_selectedCategoryIndex];

          // Filter documents using current query without interrupting UI stream
          final filteredDocs = studentDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final phone = (data['phone'] ?? '').toString().toLowerCase();
            final major = (data['major'] ?? data['department'] ?? '')
                .toString();
            final docId = doc.id.toLowerCase();

            final bool matchesSearch =
                _searchQuery.isEmpty ||
                name.contains(_searchQuery) ||
                email.contains(_searchQuery) ||
                phone.contains(_searchQuery) ||
                major.toLowerCase().contains(_searchQuery) ||
                docId.contains(_searchQuery);

            final bool matchesCategory = (_searchQuery.isNotEmpty)
                ? true
                : _checkCategoryMatch(major, selectedCatName);

            return matchesSearch && matchesCategory;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const SizedBox(height: 8),

              // Search Bar
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by student name, email, major...",
                  hintStyle: TextStyle(color: subtitleColor, fontSize: 13),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: subtitleColor,
                            size: 18,
                          ),
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
              const SizedBox(height: 16),

              // Category Chips
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categoriesList.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedCategoryIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(categoriesList[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        selectedColor: const Color(0xFFFBBF24),
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
                            color: isSelected
                                ? Colors.transparent
                                : borderColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Student Cards List
              if (filteredDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0),
                  child: Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No students matching "$_searchQuery"'
                          : 'No students found in category "$selectedCatName"',
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDocs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final String uid = doc.id;
                    final String name =
                        data['name']?.toString() ?? 'Unnamed Student';
                    final String major =
                        data['major']?.toString() ??
                        data['department']?.toString() ??
                        'General';
                    final String academicLevel =
                        data['academicLevel']?.toString() ?? 'Year 3';
                    final String photoUrl = data['photoUrl']?.toString() ?? '';

                    return _buildStudentCard(
                      uid: uid,
                      name: name,
                      department: '$major • $academicLevel',
                      photoUrl: photoUrl,
                      containerColor: containerColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                      borderColor: borderColor,
                      isDarkMode: isDarkMode,
                      onTap: () => _showStudentInfo(data),
                      onDelete: () => _confirmDeleteUser(uid, name),
                    );
                  },
                ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentCard({
    required String uid,
    required String name,
    required String department,
    required String photoUrl,
    required Color containerColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
    required bool isDarkMode,
    required VoidCallback onTap,
    required VoidCallback onDelete,
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
              color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: _getProfileImage(photoUrl),
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
                    department,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 22,
              ),
              onPressed: onDelete,
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
