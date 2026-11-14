import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:prep_mate/features/admin/models/classroom_model.dart';
import 'package:prep_mate/features/auth/models/user_model.dart';

class ClassroomService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static CollectionReference get _classroomsCollection =>
      _firestore.collection('classrooms');

  static String _generateCleanCode(String name) {
    final prefix = name.trim().isNotEmpty
        ? (name.trim().replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase())
        : 'EXM';
    final tag = prefix.length >= 3 ? prefix.substring(0, 3) : 'CLS';
    final randomDigits = (100 + Random().nextInt(900)).toString();
    return '$tag-$randomDigits';
  }

  /// Creates a new Classroom with subjects and generates a unique join code
  static Future<ClassroomModel> createClassroom({
    required String adminId,
    required String name,
    String section = '',
    List<String> subjects = const [],
    int themeIndex = -1,
    String? customCode,
  }) async {
    final docRef = _classroomsCollection.doc();
    final code = (customCode != null && customCode.trim().isNotEmpty)
        ? customCode.trim().toUpperCase()
        : _generateCleanCode(name);

    final assignedTheme = themeIndex >= 0 ? themeIndex : Random().nextInt(12);

    final classroom = ClassroomModel(
      id: docRef.id,
      adminId: adminId,
      name: name.trim(),
      section: section.trim(),
      code: code,
      themeIndex: assignedTheme,
      subjects: subjects
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(),
      studentUids: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(classroom.toMap());
    return classroom;
  }

  /// Streams all classrooms belonging to an instructor
  static Stream<List<ClassroomModel>> getClassroomsStream(String adminId) {
    if (adminId.isEmpty) return Stream.value([]);

    return _classroomsCollection
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ClassroomModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Streams a single classroom by ID
  static Stream<ClassroomModel?> getSingleClassroomStream(String classroomId) {
    if (classroomId.isEmpty) return Stream.value(null);

    return _classroomsCollection.doc(classroomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ClassroomModel.fromFirestore(doc);
    });
  }

  /// Updates classroom details (name, section, theme, etc.)
  static Future<void> updateClassroom(ClassroomModel classroom) async {
    await _classroomsCollection.doc(classroom.id).update({
      'name': classroom.name.trim(),
      'section': classroom.section.trim(),
      'themeIndex': classroom.themeIndex,
      'subjects': classroom.subjects,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a classroom
  static Future<void> deleteClassroom(String classroomId) async {
    if (classroomId.isEmpty) return;
    await _classroomsCollection.doc(classroomId).delete();
  }

  /// Adds a subject to a classroom
  static Future<void> addSubject({
    required String classroomId,
    required String subjectName,
  }) async {
    final cleanName = subjectName.trim();
    if (cleanName.isEmpty) return;

    await _classroomsCollection.doc(classroomId).update({
      'subjects': FieldValue.arrayUnion([cleanName]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a subject from a classroom
  static Future<void> removeSubject({
    required String classroomId,
    required String subjectName,
  }) async {
    await _classroomsCollection.doc(classroomId).update({
      'subjects': FieldValue.arrayRemove([subjectName.trim()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Assigns a student directly by email address
  static Future<UserModel> assignStudentByEmail({
    required String classroomId,
    required String studentEmail,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw Exception('Please provide a student email address.');
    }

    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No registered student found with email: $cleanEmail');
    }

    final studentDoc = query.docs.first;
    final studentData = studentDoc.data();
    final student = UserModel.fromMap(studentData);

    // Add student UID to classroom
    await _classroomsCollection.doc(classroomId).update({
      'studentUids': FieldValue.arrayUnion([student.uid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Also update student's profile to bind to the classroom's admin
    final classroomDoc = await _classroomsCollection.doc(classroomId).get();
    if (classroomDoc.exists) {
      final classroom = ClassroomModel.fromFirestore(classroomDoc);
      await _firestore.collection('users').doc(student.uid).update({
        'adminId': classroom.adminId,
        'classroomId': classroomId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    return student;
  }

  /// Removes a student from a classroom
  static Future<void> removeStudentFromClassroom({
    required String classroomId,
    required String studentUid,
  }) async {
    await _classroomsCollection.doc(classroomId).update({
      'studentUids': FieldValue.arrayRemove([studentUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches all student profiles enrolled in a list of UIDs
  static Future<List<UserModel>> getStudentsByUids(List<String> uids) async {
    if (uids.isEmpty) return [];

    // Firestore allows 'whereIn' batches of up to 30
    final List<UserModel> students = [];
    final chunks = <List<String>>[];

    for (int i = 0; i < uids.length; i += 30) {
      chunks.add(uids.sublist(i, min(i + 30, uids.length)));
    }

    for (final chunk in chunks) {
      final query = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final doc in query.docs) {
        students.add(UserModel.fromMap(doc.data()));
      }
    }

    return students;
  }

  /// Student Join Classroom by Code (Classroom Code or Instructor Code/Email)
  static Future<Map<String, String>> joinClassroom({
    required String studentUid,
    required String inputQuery,
  }) async {
    final query = inputQuery.trim();
    if (query.isEmpty) {
      throw Exception('Please enter a Classroom Code or Email.');
    }

    // 1. First, check if code matches a Classroom document directly
    final classroomQuery = await _classroomsCollection
        .where('code', isEqualTo: query.toUpperCase())
        .limit(1)
        .get();

    if (classroomQuery.docs.isNotEmpty) {
      final classroomDoc = classroomQuery.docs.first;
      final classroom = ClassroomModel.fromFirestore(classroomDoc);

      // Add student to classroom roster
      await classroomDoc.reference.update({
        'studentUids': FieldValue.arrayUnion([studentUid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update student profile
      await _firestore.collection('users').doc(studentUid).update({
        'adminId': classroom.adminId,
        'classroomId': classroom.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'adminId': classroom.adminId,
        'adminName': classroom.name,
        'classroomCode': classroom.code,
        'classroomId': classroom.id,
      };
    }

    // 2. Fallback: Check if it's an Instructor's general Classroom Code or Email
    final userByCode = await _firestore
        .collection('users')
        .where('classroomCode', isEqualTo: query.toUpperCase())
        .limit(1)
        .get();

    DocumentSnapshot? adminDoc;
    if (userByCode.docs.isNotEmpty) {
      adminDoc = userByCode.docs.first;
    } else {
      final userByEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: query.toLowerCase())
          .limit(1)
          .get();
      if (userByEmail.docs.isNotEmpty) {
        adminDoc = userByEmail.docs.first;
      }
    }

    if (adminDoc != null && adminDoc.exists) {
      final adminData = adminDoc.data() as Map<String, dynamic>? ?? {};
      final adminId = adminDoc.id;
      final adminName = (adminData['name'] ?? 'Instructor').toString();

      await _firestore.collection('users').doc(studentUid).update({
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'adminId': adminId,
        'adminName': adminName,
        'classroomCode': query.toUpperCase(),
      };
    }

    throw Exception('No classroom or instructor found with code: "$query"');
  }

  /// Auto-generates or retrieves a general fallback Classroom Code for an Admin
  static Future<String> getOrCreateClassroomCode(String adminUid) async {
    if (adminUid.isEmpty) return '';

    final userDocRef = _firestore.collection('users').doc(adminUid);
    final userSnap = await userDocRef.get();

    if (!userSnap.exists) return '';

    final data = userSnap.data() ?? {};
    final existingCode = (data['classroomCode'] ?? '').toString().trim();

    if (existingCode.isNotEmpty) {
      return existingCode;
    }

    final randomDigits = (100 + Random().nextInt(900)).toString();
    final newCode = 'EXM-$randomDigits';

    await userDocRef.set({
      'classroomCode': newCode,
    }, SetOptions(merge: true));

    return newCode;
  }
}
