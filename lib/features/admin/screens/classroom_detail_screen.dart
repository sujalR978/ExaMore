import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/admin/screens/exam_configuration_screen.dart';
import 'package:prep_mate/features/admin/screens/exam_analytics_detail_screen.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';
import 'package:prep_mate/features/admin/services/exam_service.dart';
import 'package:prep_mate/features/admin/widgets/create_classroom_dialog.dart';
import 'package:prep_mate/features/auth/models/user_model.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final ClassroomModel classroom;

  const ClassroomDetailScreen({super.key, required this.classroom});

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExamService _examService = ExamService();
  late ClassroomModel _classroom;

  @override
  void initState() {
    super.initState();
    _classroom = widget.classroom;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Thermodynamics, Linear Algebra',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await ClassroomService.addSubject(
                  classroomId: _classroom.id,
                  subjectName: name,
                );
                if (mounted) {
                  setState(() {
                    if (!_classroom.subjects.contains(name)) {
                      _classroom.subjects.add(name);
                    }
                  });
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignStudentDialog() {
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
              const Text(
                'Enter the registered email of the student to assign them to this classroom.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'student@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isAssigning ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isAssigning
                  ? null
                  : () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      setDialogState(() => isAssigning = true);
                      try {
                        final student =
                            await ClassroomService.assignStudentByEmail(
                          classroomId: _classroom.id,
                          studentEmail: email,
                        );
                        if (!mounted) return;
                        setState(() {
                          if (!_classroom.studentUids.contains(student.uid)) {
                            _classroom.studentUids.add(student.uid);
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Assigned ${student.name} to classroom!',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final gradients = CreateClassroomDialog.themeGradients;
    int themeIdx = _classroom.themeIndex;
    if (themeIdx <= 0) {
      themeIdx = _classroom.id.hashCode.abs() % gradients.length;
    }
    final gradient = gradients[themeIdx % gradients.length];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<ClassroomModel?>(
        stream: ClassroomService.getSingleClassroomStream(_classroom.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _classroom = snapshot.data!;
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _classroom.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Classroom Code (${_classroom.code}) copied to clipboard!',
                            ),
                            backgroundColor: const Color(0xFF7C3AED),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white),
                      tooltip: 'Edit Classroom',
                      onPressed: () async {
                        final updated = await CreateClassroomDialog.show(
                          context,
                          adminId: _classroom.adminId,
                          classroomToEdit: _classroom,
                        );
                        if (updated != null && mounted) {
                          setState(() => _classroom = updated);
                        }
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          final updated = await CreateClassroomDialog.show(
                            context,
                            adminId: _classroom.adminId,
                            classroomToEdit: _classroom,
                          );
                          if (updated != null && mounted) {
                            setState(() => _classroom = updated);
                          }
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Classroom?'),
                              content: Text(
                                'Are you sure you want to delete "${_classroom.name}"? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ClassroomService.deleteClassroom(_classroom.id);
                            if (mounted) Navigator.pop(context);
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Classroom'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text(
                                'Delete Classroom',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 58),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _classroom.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (_classroom.section.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _classroom.section,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _classroom.code),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Class code "${_classroom.code}" copied!',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.vpn_key_outlined,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Code: ${_classroom.code}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11.5,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white70,
                                        size: 11,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      color: Colors.white70,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_classroom.studentUids.length} Students',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.18),
                        border: const Border(
                          bottom: BorderSide(color: Colors.white12, width: 0.8),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.white,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        tabs: const [
                          Tab(text: 'Exams'),
                          Tab(text: 'Subjects'),
                          Tab(text: 'Students'),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // 1. Exams Tab
                _buildExamsTab(theme, isDarkMode),

                // 2. Subjects Tab
                _buildSubjectsTab(theme, isDarkMode),

                // 3. Students Tab
                _buildStudentsTab(theme, isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExamsTab(ThemeData theme, bool isDarkMode) {
    return StreamBuilder<List<ExamModel>>(
      stream: _examService.getExamsStream(adminId: _classroom.adminId),
      builder: (context, snapshot) {
        final allExams = snapshot.data ?? [];
        // Filter exams matching this classroom's subjects or general
        final classroomExams = allExams.where((e) {
          if (_classroom.subjects.isEmpty) return true;
          return _classroom.subjects
              .any((sub) => e.category.toLowerCase() == sub.toLowerCase());
        }).toList();

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'create_exam_in_class',
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ExamConfigurationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Create Exam'),
          ),
          body: classroomExams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No exams created for this classroom yet',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "+ Create Exam" to assign assessments.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white38 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: classroomExams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exam = classroomExams[index];
                    final isPublished =
                        exam.status.toLowerCase() == 'published';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: (isPublished
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withOpacity(0.15),
                          child: Icon(
                            isPublished
                                ? Icons.check_circle_outline
                                : Icons.edit_note,
                            color: isPublished
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        title: Text(
                          exam.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${exam.category} • ${exam.durationMinutes} mins • ${exam.questions.length} Qs • ${exam.submissionsCount} submissions',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExamAnalyticsDetailScreen(
                                exam: exam,
                                examId: exam.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSubjectsTab(ThemeData theme, bool isDarkMode) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_subject_btn',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: _showAddSubjectDialog,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add Subject'),
      ),
      body: _classroom.subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 48,
                    color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No subjects added yet',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Add subjects to organize tests and quizzes.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _classroom.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final subject = _classroom.subjects[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEDE9FE),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () async {
                        await ClassroomService.removeSubject(
                          classroomId: _classroom.id,
                          subjectName: subject,
                        );
                        setState(() => _classroom.subjects.remove(subject));
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStudentsTab(ThemeData theme, bool isDarkMode) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'assign_student_btn',
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        onPressed: _showAssignStudentDialog,
        icon: const Icon(Icons.person_add_outlined, size: 20),
        label: const Text('Assign Student'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: ClassroomService.getStudentsByUids(_classroom.studentUids),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data ?? [];

          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: isDarkMode ? Colors.white24 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No students enrolled yet',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share Classroom Code "${_classroom.code}" or tap "+ Assign Student".',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white38 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7C3AED).withOpacity(0.15),
                    child: Text(
                      student.name.isNotEmpty
                          ? student.name[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    student.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    student.email,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.person_remove_outlined,
                      size: 20,
                      color: Colors.redAccent,
                    ),
                    onPressed: () async {
                      await ClassroomService.removeStudentFromClassroom(
                        classroomId: _classroom.id,
                        studentUid: student.uid,
                      );
                      setState(() => _classroom.studentUids.remove(student.uid));
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

