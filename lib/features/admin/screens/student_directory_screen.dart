// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/widgets/admin_menu_drawer.dart';
import 'package:prep_mate/features/admin/widgets/admin_top_bar.dart';

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
    } else if (photoUrl.startsWith('assets/')) {
      return AssetImage(photoUrl);
    } else {
      if (!kIsWeb) {
        try {
          final file = File(photoUrl);
          if (file.existsSync()) {
            return FileImage(file);
          }
        } catch (_) {}
      }
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
      );
    }
  }

  void _showStudentInfo(Map<String, dynamic> studentData) {
    final String name = studentData['name']?.toString().trim().isNotEmpty == true
        ? studentData['name'].toString().trim()
        : 'Unnamed Student';
    final String email = studentData['email']?.toString().trim().isNotEmpty == true
        ? studentData['email'].toString().trim()
        : 'No email';
    final String phone = studentData['phone']?.toString().trim().isNotEmpty == true
        ? studentData['phone'].toString().trim()
        : 'No phone';
    final String major = studentData['major']?.toString().trim().isNotEmpty == true
        ? studentData['major'].toString().trim()
        : (studentData['department']?.toString().trim().isNotEmpty == true
            ? studentData['department'].toString().trim()
            : 'General');
    final String academicLevel =
        studentData['academicLevel']?.toString().trim().isNotEmpty == true
            ? studentData['academicLevel'].toString().trim()
            : 'N/A';
    final String photoUrl = studentData['photoUrl']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardBg = isDark ? const Color(0xFF171E31) : Colors.white;
        final borderColor = isDark ? const Color(0xFF28334D) : const Color(0xFFE2E8F0);
        final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
        final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
        final dividerColor = isDark ? const Color(0xFF28334D) : const Color(0xFFE2E8F0);
        final avatarBg = isDark ? Colors.white : const Color(0xFFF1F5F9);

        return Dialog(
          backgroundColor: cardBg,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borderColor, width: 1),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student Header (Avatar + Name)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: avatarBg,
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: _getProfileImage(photoUrl),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Divider(height: 1, thickness: 1, color: dividerColor),
                  const SizedBox(height: 16),

                  // Information rows with responsive layouts and non-overflowing text
                  _buildInfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: email,
                    labelColor: labelColor,
                    valueColor: textColor,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: phone,
                    labelColor: labelColor,
                    valueColor: textColor,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.science_outlined,
                    label: 'Major',
                    value: major,
                    labelColor: labelColor,
                    valueColor: textColor,
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.school_outlined,
                    label: 'Academic Level',
                    value: academicLevel,
                    labelColor: labelColor,
                    valueColor: textColor,
                  ),
                  const SizedBox(height: 20),

                  // Actions: Right-aligned styled Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                  height: 1.25,
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
      appBar: AdminTopBar(
        title: isSuperAdmin ? 'All System Students' : 'My Students',
        subtitle: isSuperAdmin ? 'Super Admin Portal' : 'Student Directory',
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
