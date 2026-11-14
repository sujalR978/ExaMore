import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Streams all classrooms where the student is enrolled (either in studentUids or directly assigned)
  static Stream<List<ClassroomModel>> getStudentEnrolledClassroomsStream({
    required String studentUid,
    String? currentClassroomId,
  }) {
    if (studentUid.isEmpty) return Stream.value(<ClassroomModel>[]);

    return _classroomsCollection.snapshots().map((snapshot) {
      final list = <ClassroomModel>[];
      for (var doc in snapshot.docs) {
        final c = ClassroomModel.fromFirestore(doc);
        final isEnrolled = c.studentUids.contains(studentUid);
        final isCurrent = currentClassroomId != null &&
            currentClassroomId.isNotEmpty &&
            c.id == currentClassroomId;
        if (isEnrolled || isCurrent) {
          list.add(c);
        }
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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

  /// Adds multiple subjects to a classroom at once
  static Future<void> addSubjects({
    required String classroomId,
    required List<String> subjectNames,
  }) async {
    final cleanList = subjectNames
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (cleanList.isEmpty) return;

    await _classroomsCollection.doc(classroomId).update({
      'subjects': FieldValue.arrayUnion(cleanList),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Adds a single subject to a classroom
  static Future<void> addSubject({
    required String classroomId,
    required String subjectName,
  }) async {
    await addSubjects(
      classroomId: classroomId,
      subjectNames: [subjectName],
    );
  }

  /// Edits an existing subject in a classroom
  static Future<void> editSubject({
    required String classroomId,
    required String oldSubjectName,
    required String newSubjectName,
  }) async {
    final oldName = oldSubjectName.trim();
    final newName = newSubjectName.trim();
    if (oldName.isEmpty || newName.isEmpty || oldName == newName) return;

    final docRef = _classroomsCollection.doc(classroomId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final List<dynamic> current = List.from(data['subjects'] ?? []);
      final index = current.indexOf(oldName);
      if (index != -1) {
        current[index] = newName;
      } else if (!current.contains(newName)) {
        current.add(newName);
      }
      final updated = current.toSet().toList();
      transaction.update(docRef, {
        'subjects': updated,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  /// Shares classroom invitation with link and code to WhatsApp, Telegram, etc.
  static Future<void> shareClassroomInvite(ClassroomModel classroom) async {
    final code = classroom.code;
    final name = classroom.name;
    final joinUrl = 'https://examore.web.app/join?code=$code';

    final message = '''🎓 You're invited to join "$name" on ExaMore!

Classroom Code: $code

📲 Tap to join directly:
$joinUrl

Or open the ExaMore app and enter code: $code''';

    await Share.share(
      message,
      subject: 'Invite: Join $name on ExaMore',
    );
  }

  /// Student Join Classroom by Code (Classroom Code, URL Link, or Instructor Email)
  static Future<Map<String, String>> joinClassroom({
    required String studentUid,
    required String inputQuery,
  }) async {
    String query = inputQuery.trim();
    if (query.isEmpty) {
      throw Exception('Please enter a Classroom Code or Invitation Link.');
    }

    // 1. Extract code if full URL or invitation link was passed (e.g. ?code=CLA-198 or examore://join?code=CLA-198)
    if (query.contains('code=')) {
      final uri = Uri.tryParse(query);
      if (uri != null && uri.queryParameters.containsKey('code')) {
        query = uri.queryParameters['code']!;
      } else {
        final match = RegExp(r'code=([A-Za-z0-9_-]+)', caseSensitive: false)
            .firstMatch(query);
        if (match != null) {
          query = match.group(1)!;
        }
      }
    } else {
      // 2. Extract code pattern like CLA-123 or EXM-123 if whole message is pasted
      final match = RegExp(r'\b(CLA-\d+|EXM-\d+)\b', caseSensitive: false)
          .firstMatch(query);
      if (match != null) {
        query = match.group(1)!;
      }
    }

    query = query.trim().toUpperCase();

    // 1. First, check if code matches a Classroom document directly
    final classroomQuery = await _classroomsCollection
        .where('code', isEqualTo: query)
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
