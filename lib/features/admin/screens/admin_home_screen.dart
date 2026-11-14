// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/core/widgets/custom_bottom_nav_bar.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/add_multiple_choice_question_screen.dart';
import 'package:prep_mate/features/admin/screens/classroom_detail_screen.dart';
import 'package:prep_mate/features/admin/screens/exam_configuration_screen.dart';
import 'package:prep_mate/features/admin/screens/student_directory_screen.dart';
import 'package:prep_mate/features/admin/screens/question_bank_screen.dart';
import 'package:prep_mate/features/admin/screens/show_exams_screen.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';
import 'package:prep_mate/features/admin/widgets/admin_menu_drawer.dart';
import 'package:prep_mate/features/admin/widgets/create_classroom_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ExamService _examService = ExamService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  int _currentIndex = 0;
  String _userRole = 'admin';
  String _adminUid = '';
  String _classroomCode = '';

  @override
  void initState() {
    super.initState();
    _adminUid = _currentUser?.uid ?? '';
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _userRole = (data['role'] ?? 'admin').toString().toLowerCase();
          _classroomCode = (data['classroomCode'] ?? '').toString();
        });
      }

      if (_classroomCode.isEmpty) {
        final code = await ClassroomService.getOrCreateClassroomCode(
          _currentUser.uid,
        );
        if (mounted) {
          setState(() => _classroomCode = code);
        }
      }
    } catch (_) {}
  }

  Future<void> _openCreateClassroomDialog({
    ClassroomModel? classroomToEdit,
  }) async {
    if (_adminUid.isEmpty) return;
    await CreateClassroomDialog.show(
      context,
      adminId: _adminUid,
      classroomToEdit: classroomToEdit,
    );
  }

  void _showAddSubjectDialog(ClassroomModel classroom) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.library_books_outlined, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text('Add Subject'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add subject(s) to "${classroom.name}". Separate multiple subjects with commas for instant batch adding:',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Mathematics, Physics, Chemistry',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isNotEmpty) {
                final names = raw
                    .split(RegExp(r'[,;\n]+'))
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (names.isNotEmpty) {
                  Navigator.pop(ctx);
                  ClassroomService.addSubjects(
                    classroomId: classroom.id,
                    subjectNames: names,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added ${names.length} subject${names.length > 1 ? 's' : ''} to ${classroom.name}',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('Add Subjects'),
          ),
        ],
      ),
    );
  }

  void _showAssignStudentDialog(ClassroomModel classroom) {
    final emailController = TextEditingController();
    bool isAssigning = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.person_add_outlined, color: Color(0xFF7C3AED)),
              SizedBox(width: 8),
              Text('Assign Student'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enroll student into "${classroom.name}":',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'student@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              onPressed: isAssigning
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;

                      setDialogState(() => isAssigning = true);
                      try {
                        final student =
                            await ClassroomService.assignStudentByEmail(
                              classroomId: classroom.id,
                              studentEmail: email,
                            );
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Enrolled ${student.name.isNotEmpty ? student.name : student.email} successfully!',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isAssigning = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceAll('Exception: ', ''),
                            ),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
              child: isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteClassroom(ClassroomModel classroom) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Classroom?'),
        content: Text(
          'Are you sure you want to delete "${classroom.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ClassroomService.deleteClassroom(classroom.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Classroom "${classroom.name}" deleted.'),
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      return FloatingActionButton.extended(
        heroTag: 'admin_home_create_classroom_fab',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Classroom',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: _openCreateClassroomDialog,
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton.extended(
        heroTag: 'admin_home_create_exam_fab',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'New Exam',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ExamConfigurationScreen(),
            ),
          );
        },
      );
    } else if (_currentIndex == 2) {
      return FloatingActionButton.extended(
        heroTag: 'admin_home_create_question_fab',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Question',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () {
          final tempExam = ExamModel(
            id: '',
            examCode: '',
            title: 'Question Bank Entry',
            category: 'General',
            adminId: _adminUid,
            durationMinutes: 60,
            totalMarks: 100,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMultipleChoiceQuestionScreen(
                exam: tempExam,
                isForQuestionBank: true,
              ),
            ),
          );
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSuperAdmin =
        _userRole == 'super_admin' ||
        _currentUser?.email?.toLowerCase() == 'admin@gmail.com';

    final surfaceColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : Colors.grey.shade600;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AdminMenuDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildClassroomsDashboard(
            theme: theme,
            isDarkMode: isDarkMode,
            isSuperAdmin: isSuperAdmin,
            surfaceColor: surfaceColor,
            textColor: textColor,
            subtitleColor: subtitleColor,
            borderColor: borderColor,
          ),
          const Showexamesscreen(),
          const QuestionBankScreen(),
          const StudentDirectoryScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        activeColor: const Color(0xFF7C3AED),
        items: const [
          CustomBottomNavItem(
            activeIcon: Icons.school_rounded,
            inactiveIcon: Icons.school_outlined,
            label: 'Classes',
          ),
          CustomBottomNavItem(
            activeIcon: Icons.assignment_rounded,
            inactiveIcon: Icons.assignment_outlined,
            label: 'Exams',
          ),
          CustomBottomNavItem(
            activeIcon: Icons.layers_rounded,
            inactiveIcon: Icons.layers_outlined,
            label: 'Questions',
          ),
          CustomBottomNavItem(
            activeIcon: Icons.people_rounded,
            inactiveIcon: Icons.people_outline_rounded,
            label: 'Students',
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // -------------------------------------------------------------
  // Google Classroom Primary Dashboard (Tab 0)
  // -------------------------------------------------------------
  Widget _buildClassroomsDashboard({
    required ThemeData theme,
    required bool isDarkMode,
    required bool isSuperAdmin,
    required Color surfaceColor,
    required Color textColor,
    required Color subtitleColor,
    required Color borderColor,
  }) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ExaMore',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  isSuperAdmin ? 'Super Admin Portal' : 'Classroom Dashboard',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _examService.getDashboardMetricsStream(
          adminId: _adminUid,
          role: isSuperAdmin ? 'super_admin' : _userRole,
        ),
        builder: (context, metricSnapshot) {
          final metrics =
              metricSnapshot.data ??
              {'totalStudents': 0, 'activeExams': 0, 'totalQuizzesBank': 0};

          return StreamBuilder<List<ClassroomModel>>(
            stream: ClassroomService.getClassroomsStream(_adminUid),
            builder: (context, classroomSnapshot) {
              final classrooms = classroomSnapshot.data ?? [];
              final totalClassrooms = classrooms.length;

              return RefreshIndicator(
                onRefresh: () async {
                  await _fetchUserRole();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Top Super Admin Key (if applicable)
                    if (isSuperAdmin && _adminUid.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _buildSuperAdminKeyBanner(),
                        ),
                      ),

                    // Compact Horizontal Status Strip
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: _buildCompactMetricsRibbon(
                          totalClassrooms: totalClassrooms,
                          totalStudents:
                              (metrics['totalStudents'] as num?)?.toInt() ?? 0,
                          activeExams:
                              (metrics['activeExams'] as num?)?.toInt() ?? 0,
                          totalQuizzes:
                              (metrics['totalQuizzesBank'] as num?)?.toInt() ??
                              0,
                          isDarkMode: isDarkMode,
                          surfaceColor: surfaceColor,
                          borderColor: borderColor,
                        ),
                      ),
                    ),

                    // Section Title: "My Classrooms" + Quick Actions
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'My Classrooms',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalClassrooms',
                                style: const TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Classrooms Grid / List or Empty State
                    if (classrooms.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyClassroomState(
                          isDarkMode: isDarkMode,
                          subtitleColor: subtitleColor,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    MediaQuery.of(context).size.width >= 900
                                    ? 4
                                    : MediaQuery.of(context).size.width >= 600
                                    ? 3
                                    : 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final classroom = classrooms[index];
                            return _buildGoogleClassroomSquareCard(
                              classroom: classroom,
                              cardIndex: index,
                              isDarkMode: isDarkMode,
                              surfaceColor: surfaceColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                            );
                          }, childCount: classrooms.length),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------


  // -------------------------------------------------------------
  // Compact 4-Segment Metrics Ribbon
  // -------------------------------------------------------------
  Widget _buildCompactMetricsRibbon({
    required int totalClassrooms,
    required int totalStudents,
    required int activeExams,
    required int totalQuizzes,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildRibbonItem(
            icon: Icons.school_outlined,
            iconColor: const Color(0xFF3B82F6),
            value: '$totalClassrooms',
            label: 'Classes',
            onTap: null,
          ),
          _buildRibbonDivider(borderColor),
          _buildRibbonItem(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF10B981),
            value: '$totalStudents',
            label: 'Students',
            onTap: null,
          ),
          _buildRibbonDivider(borderColor),
          _buildRibbonItem(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFFF59E0B),
            value: '$activeExams',
            label: 'Exams',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const Showexamesscreen(),
                ),
              );
            },
          ),
          _buildRibbonDivider(borderColor),
          _buildRibbonItem(
            icon: Icons.help_outline,
            iconColor: const Color(0xFF8B5CF6),
            value: '$totalQuizzes',
            label: 'Questions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuestionBankScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRibbonDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 28,
      color: borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildRibbonItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback? onTap,
  }) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: content,
              ),
            ),
    );
  }

  // -------------------------------------------------------------
  // Super Admin Authorization Key Banner
  // -------------------------------------------------------------
  Widget _buildSuperAdminKeyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF4338CA)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFFBBF24), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SUPER ADMIN AUTHORIZATION KEY',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _adminUid,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.copy_rounded,
              color: Color(0xFFFBBF24),
              size: 16,
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _adminUid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Super Admin Key copied to clipboard!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // Google Classroom-Style Compact Square Card (Responsive Grid)
  // -------------------------------------------------------------
  Widget _buildGoogleClassroomSquareCard({
    required ClassroomModel classroom,
    required int cardIndex,
    required bool isDarkMode,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    final gradients = CreateClassroomDialog.themeGradients;
    int themeIdx = classroom.themeIndex;
    if (themeIdx <= 0) {
      themeIdx = (classroom.id.hashCode.abs() + cardIndex) % gradients.length;
    }
    final gradient = gradients[themeIdx % gradients.length];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassroomDetailScreen(classroom: classroom),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Theme Gradient Banner (~48% of height)
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Class name and section
                    Padding(
                      padding: const EdgeInsets.only(right: 22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            classroom.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (classroom.section.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              classroom.section,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Top-right 3-dots popup menu
                    Positioned(
                      top: -6,
                      right: -6,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          color: Colors.white,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (value) {
                          if (value == 'open') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ClassroomDetailScreen(classroom: classroom),
                              ),
                            );
                          } else if (value == 'edit') {
                            _openCreateClassroomDialog(
                              classroomToEdit: classroom,
                            );
                          } else if (value == 'add_subject') {
                            _showAddSubjectDialog(classroom);
                          } else if (value == 'assign_student') {
                            _showAssignStudentDialog(classroom);
                          } else if (value == 'copy_code') {
                            Clipboard.setData(
                              ClipboardData(text: classroom.code),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Code "${classroom.code}" copied to clipboard!',
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            _confirmDeleteClassroom(classroom);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'open',
                            child: Row(
                              children: [
                                Icon(Icons.open_in_new, size: 18),
                                SizedBox(width: 8),
                                Text('Open'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'add_subject',
                            child: Row(
                              children: [
                                Icon(Icons.library_books_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Add Subject'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'assign_student',
                            child: Row(
                              children: [
                                Icon(Icons.person_add_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Assign Student'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'copy_code',
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Copy Code'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Body (Lower ~55% of height)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Subjects Tag
                    if (classroom.subjects.isNotEmpty)
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: gradient[0].withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: gradient[0].withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                classroom.subjects.first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? gradient[1] : gradient[0],
                                ),
                              ),
                            ),
                          ),
                          if (classroom.subjects.length > 1) ...[
                            const SizedBox(width: 4),
                            Text(
                              '+${classroom.subjects.length - 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: subtitleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      InkWell(
                        onTap: () => _showAddSubjectDialog(classroom),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add,
                              size: 12,
                              color: isDarkMode
                                  ? const Color(0xFFA78BFA)
                                  : const Color(0xFF7C3AED),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Subject',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? const Color(0xFFA78BFA)
                                    : const Color(0xFF7C3AED),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Bottom Row: Students & Join Code Pill
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 12,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${classroom.studentUids.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: subtitleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(
                              ClipboardData(text: classroom.code),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Class code "${classroom.code}" copied!',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  classroom.code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 10,
                                  color: subtitleColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // Clean Minimal Empty State
  // -------------------------------------------------------------
  Widget _buildEmptyClassroomState({
    required bool isDarkMode,
    required Color subtitleColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_outlined,
                size: 52,
                color: Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Classrooms Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a classroom to organize subjects, enroll students, and schedule tailored exams.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
