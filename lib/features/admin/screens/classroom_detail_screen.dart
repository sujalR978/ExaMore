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
  late Future<List<UserModel>> _studentsFuture;

  @override
  void initState() {
    super.initState();
    _classroom = widget.classroom;
    _studentsFuture = ClassroomService.getStudentsByUids(_classroom.studentUids);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.library_books_outlined,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Add Subjects',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter subject name(s). You can add multiple subjects separated by commas for instant batch adding:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'e.g. Physics, Chemistry, Mathematics',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                  // Instant 0ms optimistic local update
                  setState(() {
                    for (final n in names) {
                      if (!_classroom.subjects.contains(n)) {
                        _classroom.subjects.add(n);
                      }
                    }
                  });
                  Navigator.pop(ctx);

                  // Asynchronous batch Firestore sync
                  ClassroomService.addSubjects(
                    classroomId: _classroom.id,
                    subjectNames: names,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added ${names.length} subject${names.length > 1 ? 's' : ''} to ${_classroom.name}!',
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      duration: const Duration(seconds: 1),
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

  void _showEditSubjectDialog(String currentSubject) {
    final controller = TextEditingController(text: currentSubject);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF7C3AED),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Edit Subject',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update the subject title:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Subject Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentSubject) {
                // Optimistic local update
                setState(() {
                  final idx = _classroom.subjects.indexOf(currentSubject);
                  if (idx != -1) {
                    _classroom.subjects[idx] = newName;
                  }
                });
                Navigator.pop(ctx);
                ClassroomService.editSubject(
                  classroomId: _classroom.id,
                  oldSubjectName: currentSubject,
                  newSubjectName: newName,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Subject updated to "$newName"'),
                    backgroundColor: const Color(0xFF10B981),
                    duration: const Duration(seconds: 1),
                  ),
                );
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 24),
            SizedBox(width: 8),
            Text('Delete Exam?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete "${exam.title}"? All student submission records will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Exam'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _examService.deleteExam(exam.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exam "${exam.title}" deleted.'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete exam: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
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
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return FloatingActionButton.extended(
              heroTag: 'create_exam_in_class',
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExamConfigurationScreen(
                      classroom: _classroom,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Exam'),
            );
          } else if (_tabController.index == 1) {
            return FloatingActionButton.extended(
              heroTag: 'add_subject_btn',
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Subject'),
            );
          } else {
            return FloatingActionButton.extended(
              heroTag: 'assign_student_btn',
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              onPressed: _showAssignStudentDialog,
              icon: const Icon(Icons.person_add_outlined, size: 20),
              label: const Text('Assign Student'),
            );
          }
        },
      ),
      body: StreamBuilder<ClassroomModel?>(
        stream: ClassroomService.getSingleClassroomStream(_classroom.id),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            _classroom = snapshot.data!;
          }

          return Column(
            children: [
              // 1. Static Gradient Header (Status bar + Actions + Info + TabBar)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.35 : 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Navigation & Action Icons Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.share_outlined, color: Colors.white),
                              tooltip: 'Share Invitation Link',
                              onPressed: () => ClassroomService.shareClassroomInvite(_classroom),
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
                                if (val == 'share') {
                                  ClassroomService.shareClassroomInvite(_classroom);
                                } else if (val == 'edit') {
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
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share_outlined, size: 18, color: Color(0xFF7C3AED)),
                                      SizedBox(width: 8),
                                      Text('Share Invite Link'),
                                    ],
                                  ),
                                ),
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
                        ),
                      ),

                      // Classroom Title, Section & Badges
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 2, 20, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            const SizedBox(height: 10),
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

                      // Static TabBar Container
                      Container(
                        decoration: BoxDecoration(
                          color: gradient.last,
                          border: const Border(
                            bottom: BorderSide(color: Colors.white24, width: 0.8),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
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
                    ],
                  ),
                ),
              ),

              // 2. TabBarView in Expanded (List scrolls strictly within body, never behind the static header)
              Expanded(
                child: TabBarView(
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
                ),
              ],
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
        // Strictly isolate exams belonging only to this classroom
        final classroomExams = allExams.where((e) {
          if (e.classroomId != null && e.classroomId!.isNotEmpty) {
            return e.classroomId == _classroom.id;
          }
          if (e.classroomName != null && e.classroomName!.isNotEmpty) {
            return e.classroomName!.trim().toLowerCase() ==
                _classroom.name.trim().toLowerCase();
          }
          return false;
        }).toList();

        return classroomExams.isEmpty
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
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDarkMode
                                ? Colors.white60
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          onSelected: (val) {
                            if (val == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExamAnalyticsDetailScreen(
                                    exam: exam,
                                    examId: exam.id,
                                  ),
                                ),
                              );
                            } else if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ExamConfigurationScreen(
                                    exam: exam,
                                    classroom: _classroom,
                                  ),
                                ),
                              );
                            } else if (val == 'delete') {
                              _confirmDeleteExam(exam);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.analytics_outlined,
                                    size: 18,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Analytics / View'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: Color(0xFF7C3AED),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Edit Exam'),
                                ],
                              ),
                            ),
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
                                    'Delete Exam',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                );
      },
    );
  }

  Widget _buildSubjectsTab(ThemeData theme, bool isDarkMode) {
    return _classroom.subjects.isEmpty
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 19,
                            color: Color(0xFF7C3AED),
                          ),
                          tooltip: 'Edit Subject',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showEditSubjectDialog(subject),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete Subject',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            // Instant optimistic removal
                            setState(() => _classroom.subjects.remove(subject));
                            ClassroomService.removeSubject(
                              classroomId: _classroom.id,
                              subjectName: subject,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Removed "$subject"'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
  }

  Widget _buildStudentsTab(ThemeData theme, bool isDarkMode) {
    return FutureBuilder<List<UserModel>>(
        future: _studentsFuture,
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
      );
  }
}

