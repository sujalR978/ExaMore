import 'dart:math';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/admin/services/classroom_service.dart';

class CreateClassroomDialog extends StatefulWidget {
  final String adminId;
  final ClassroomModel? classroomToEdit;

  static const List<List<Color>> themeGradients = [
    [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // 0: Google Blue
    [Color(0xFF065F46), Color(0xFF10B981)], // 1: Emerald Green
    [Color(0xFF4C1D95), Color(0xFF8B5CF6)], // 2: Royal Purple
    [Color(0xFF9A3412), Color(0xFFF97316)], // 3: Sunset Orange
    [Color(0xFF831843), Color(0xFFEC4899)], // 4: Rose Pink
    [Color(0xFF134E4A), Color(0xFF14B8A6)], // 5: Deep Teal
    [Color(0xFF1E1B4B), Color(0xFF6366F1)], // 6: Modern Indigo
    [Color(0xFF991B1B), Color(0xFFEF4444)], // 7: Ruby Red
    [Color(0xFF0E7490), Color(0xFF06B6D4)], // 8: Ocean Cyan
    [Color(0xFF701A75), Color(0xFFD946EF)], // 9: Vibrant Magenta
    [Color(0xFF14532D), Color(0xFF22C55E)], // 10: Forest Green
    [Color(0xFF78350F), Color(0xFFEAB308)], // 11: Golden Amber
  ];

  const CreateClassroomDialog({
    super.key,
    required this.adminId,
    this.classroomToEdit,
  });

  /// Displays the create/edit classroom form as an elegant Bottom Sheet
  static Future<ClassroomModel?> show(
    BuildContext context, {
    required String adminId,
    ClassroomModel? classroomToEdit,
  }) {
    return showModalBottomSheet<ClassroomModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateClassroomDialog(
        adminId: adminId,
        classroomToEdit: classroomToEdit,
      ),
    );
  }

  @override
  State<CreateClassroomDialog> createState() => _CreateClassroomDialogState();
}

class _CreateClassroomDialogState extends State<CreateClassroomDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sectionController;
  final TextEditingController _subjectInputController = TextEditingController();

  final List<String> _subjects = [];
  int _selectedThemeIndex = 0;
  bool _isLoading = false;

  bool get isEditing => widget.classroomToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.classroomToEdit?.name ?? '',
    );
    _sectionController = TextEditingController(
      text: widget.classroomToEdit?.section ?? '',
    );
    if (widget.classroomToEdit != null) {
      _subjects.addAll(widget.classroomToEdit!.subjects);
      _selectedThemeIndex = widget.classroomToEdit!.themeIndex;
    } else {
      // Auto-assign a random vibrant color for new classrooms
      _selectedThemeIndex =
          Random().nextInt(CreateClassroomDialog.themeGradients.length);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _subjectInputController.dispose();
    super.dispose();
  }

  void _addSubject() {
    final text = _subjectInputController.text.trim();
    if (text.isNotEmpty && !_subjects.contains(text)) {
      setState(() {
        _subjects.add(text);
        _subjectInputController.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        // Edit existing classroom
        final updatedClassroom = widget.classroomToEdit!.copyWith(
          name: _nameController.text.trim(),
          section: _sectionController.text.trim(),
          subjects: _subjects,
          themeIndex: _selectedThemeIndex,
          updatedAt: DateTime.now(),
        );

        await ClassroomService.updateClassroom(updatedClassroom);

        if (!mounted) return;
        Navigator.of(context).pop(updatedClassroom);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Classroom "${updatedClassroom.name}" updated successfully!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        // Create new classroom with selected or auto-assigned random theme
        final classroom = await ClassroomService.createClassroom(
          adminId: widget.adminId,
          name: _nameController.text.trim(),
          section: _sectionController.text.trim(),
          subjects: _subjects,
          themeIndex: _selectedThemeIndex,
        );

        if (!mounted) return;
        Navigator.of(context).pop(classroom);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Classroom "${classroom.name}" created successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final String raw = e.toString();
      final String errorMsg = raw.contains('permission-denied')
          ? 'Firestore permission denied: Please enable rules for the "classrooms" collection in your Firebase Console.'
          : 'Error: ${raw.replaceAll('Exception: ', '')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor =
        isDarkMode ? const Color(0xFF94A3B8) : Colors.grey.shade600;
    final borderColor = isDarkMode ? Colors.white12 : Colors.grey.shade300;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.edit_note_rounded
                          : Icons.school_rounded,
                      color: const Color(0xFF7C3AED),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Edit Classroom' : 'Create Classroom',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'Update classroom details, section, or theme'
                              : 'Set up a new space for exams and subjects',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: subtitleColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Classroom Name Field
                      Text(
                        'Classroom Name *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. 10th Standard Science, CS Batch 2026',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white38 : Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a classroom name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section / Batch Field
                      Text(
                        'Section / Batch / Room (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _sectionController,
                        textCapitalization: TextCapitalization.words,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'e.g. Section A, Fall Semester, Room 204',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white38 : Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF7C3AED),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Subjects Tag Input
                      Text(
                        'Subjects / Topics in this Classroom',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _subjectInputController,
                              textCapitalization: TextCapitalization.words,
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'e.g. Physics, Calculus, Botany',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: isDarkMode
                                      ? Colors.white38
                                      : Colors.grey,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _addSubject(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addSubject,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Add',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Subject Chips
                      if (_subjects.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _subjects.map((sub) {
                            return Chip(
                              label: Text(
                                sub,
                                style: const TextStyle(fontSize: 12),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () =>
                                  setState(() => _subjects.remove(sub)),
                              backgroundColor: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'No subjects added yet. You can also add subjects later.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.white38 : Colors.grey,
                          ),
                        ),

                      const SizedBox(height: 28),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    isEditing ? Icons.check : Icons.add,
                                    size: 18,
                                  ),
                            label: Text(
                              isEditing ? 'Save Changes' : 'Create Classroom',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
