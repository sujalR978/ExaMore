import 'package:cloud_firestore/cloud_firestore.dart';

class ClassroomModel {
  final String id;
  final String adminId;
  final String name;
  final String section;
  final String code; // 6-character unique join code e.g. "PHY-804"
  final int themeIndex; // 0: Indigo, 1: Emerald, 2: Amber, 3: Rose, 4: Cyan, 5: Purple
  final List<String> subjects;
  final List<String> studentUids;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassroomModel({
    required this.id,
    required this.adminId,
    required this.name,
    this.section = '',
    required this.code,
    this.themeIndex = 0,
    this.subjects = const [],
    this.studentUids = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adminId': adminId,
      'name': name,
      'section': section,
      'code': code.toUpperCase(),
      'themeIndex': themeIndex,
      'subjects': subjects,
      'studentUids': studentUids,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ClassroomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    final rawSubjects = data['subjects'];
    final List<String> subjectsList = rawSubjects is List
        ? rawSubjects.map((e) => e.toString()).toList()
        : [];

    final rawStudents = data['studentUids'];
    final List<String> studentsList = rawStudents is List
        ? rawStudents.map((e) => e.toString()).toList()
        : [];

    return ClassroomModel(
      id: doc.id,
      adminId: (data['adminId'] ?? '').toString(),
      name: (data['name'] ?? 'Classroom').toString(),
      section: (data['section'] ?? '').toString(),
      code: (data['code'] ?? '').toString().toUpperCase(),
      themeIndex: (data['themeIndex'] as num?)?.toInt() ?? 0,
      subjects: subjectsList,
      studentUids: studentsList,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  ClassroomModel copyWith({
    String? id,
    String? adminId,
    String? name,
    String? section,
    String? code,
    int? themeIndex,
    List<String>? subjects,
    List<String>? studentUids,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassroomModel(
      id: id ?? this.id,
      adminId: adminId ?? this.adminId,
      name: name ?? this.name,
      section: section ?? this.section,
      code: code ?? this.code,
      themeIndex: themeIndex ?? this.themeIndex,
      subjects: subjects ?? this.subjects,
      studentUids: studentUids ?? this.studentUids,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

