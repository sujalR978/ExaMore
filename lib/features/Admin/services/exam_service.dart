import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class ExamService {
  // FIX FOR LateInitializationError - Use getters, not final field
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  CollectionReference get _examsCollection => _firestore.collection('exams');
  CollectionReference get _questionBankCollection =>
      _firestore.collection('question_bank');

  static const int maxExamAttempts = 2;

  String _generateExamCode() {
    final randomDigits = (100 + Random().nextInt(900)).toString();
    final year = DateTime.now().year;
    return 'EXM-$year-$randomDigits';
  }

  Future<int> getRemainingAttempts({
    required String examId,
    required String studentId,
  }) async {
    final existingAttempts = await _examsCollection
        .doc(examId)
        .collection('submissions')
        .where('userId', isEqualTo: studentId)
        .get();
    return (maxExamAttempts - existingAttempts.docs.length).clamp(
      0,
      maxExamAttempts,
    );
  }

  Future<bool> canAttemptExam({
    required String examId,
    required String studentId,
    String? studentAdminId,
  }) async {
    final remaining = await getRemainingAttempts(
      examId: examId,
      studentId: studentId,
    );
    if (remaining <= 0) return false;
    if (studentAdminId != null && studentAdminId.isNotEmpty) {
      final examDoc = await _examsCollection.doc(examId).get();
      if (!examDoc.exists) return false;
      final data = examDoc.data() as Map<String, dynamic>? ?? {};
      final String examAdminId = (data['adminId'] ?? '').toString();
      if (examAdminId.isNotEmpty && examAdminId != studentAdminId) return false;
    }
    return true;
  }

  Future<String> createExamDraft(ExamModel exam, {String? adminId}) async {
    final docRef = _examsCollection.doc();
    final assignedAdminId = (adminId != null && adminId.isNotEmpty)
        ? adminId
        : exam.adminId;
    final finalExam = exam.copyWith(
      id: docRef.id,
      adminId: assignedAdminId,
      examCode: exam.examCode.isEmpty ? _generateExamCode() : exam.examCode,
      status: 'Draft',
      updatedAt: DateTime.now(),
      createdAt: exam.createdAt,
    );
    await docRef.set(finalExam.toMap());
    return docRef.id;
  }

  Future<void> updateExam(ExamModel exam) async {
    await _examsCollection.doc(exam.id).update({
      ...exam.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> publishExam(String examId) async {
    await _examsCollection.doc(examId).update({
      'status': 'Published',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> unpublishExam(String examId) async {
    await _examsCollection.doc(examId).update({
      'status': 'Draft',
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteExam(String examId) async {
    await _examsCollection.doc(examId).delete();
  }

  Future<void> addQuestionToExam(String examId, QuestionModel question) async {
    await _examsCollection.doc(examId).update({
      'questions': FieldValue.arrayUnion([question.toMap()]),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<String> createExamWithQuestions({
    required String title,
    required String category,
    required List<QuestionModel> questions,
    double passingScorePercentage = 50.0,
    String? adminId,
  }) async {
    final totalMarks = questions.fold<double>(
      0.0,
      (total, q) => total + q.marks,
    );
    final exam = ExamModel(
      id: '',
      examCode: '',
      title: title,
      category: category,
      adminId: adminId ?? '',
      durationMinutes: questions.length * 2,
      totalMarks: totalMarks > 0 ? totalMarks : 100,
      passingScorePercentage: passingScorePercentage,
      questions: questions,
      status: 'Draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return await createExamDraft(exam, adminId: adminId);
  }

  Stream<List<ExamModel>> getExamsStream({
    String? category,
    String? adminId,
    String role = 'admin',
  }) {
    Query query = _examsCollection;
    if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
      query = query.where('adminId', isEqualTo: adminId);
    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'All Subjects')
      query = query.where('category', isEqualTo: category);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<ExamModel> getExamStream(String examId) {
    return _examsCollection
        .doc(examId)
        .snapshots()
        .map((doc) => ExamModel.fromFirestore(doc));
  }

  Stream<List<ExamModel>> getPublishedExamsStream({
    String? category,
    String? adminId,
    String role = 'student',
  }) {
    Query query = _examsCollection.where('status', isEqualTo: 'Published');
    if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
      query = query.where('adminId', isEqualTo: adminId);
    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'All Subjects')
      query = query.where('category', isEqualTo: category);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<StudentSubmissionModel> getCandidateDetailStream({
    required String examId,
    required String submissionId,
  }) {
    return _examsCollection
        .doc(examId)
        .collection('submissions')
        .doc(submissionId)
        .snapshots()
        .map((doc) => StudentSubmissionModel.fromFirestore(doc));
  }

  Stream<List<StudentSubmissionModel>> getExamSubmissionsStream(String examId) {
    if (examId.isEmpty) return Stream.value(<StudentSubmissionModel>[]);
    return _examsCollection
        .doc(examId)
        .collection('submissions')
        .snapshots()
        .map((snapshot) {
          final list = <StudentSubmissionModel>[];
          for (var doc in snapshot.docs) {
            try {
              list.add(StudentSubmissionModel.fromFirestore(doc));
            } catch (e) {
              debugPrint("Error parsing ${doc.id}: $e");
            }
          }
          list.sort((a, b) {
            final scoreComp = b.marksObtained.compareTo(a.marksObtained);
            return scoreComp != 0
                ? scoreComp
                : a.submittedAt.compareTo(b.submittedAt);
          });
          return list;
        });
  }

  // FIXED: Was Stream<List>> and List>
  Stream<List<Map<String, dynamic>>> getAllRecentSubmissionsStream() {
    return _examsCollection.snapshots().asyncMap((examSnapshot) async {
      List<Map<String, dynamic>> allResults = [];
      for (var examDoc in examSnapshot.docs) {
        final subSnapshot = await _examsCollection
            .doc(examDoc.id)
            .collection('submissions')
            .orderBy('submittedAt', descending: true)
            .get();
        for (var subDoc in subSnapshot.docs) {
          allResults.add({
            'examId': examDoc.id,
            'submission': StudentSubmissionModel.fromFirestore(subDoc),
          });
        }
      }
      allResults.sort((a, b) {
        final subA = a['submission'] as StudentSubmissionModel;
        final subB = b['submission'] as StudentSubmissionModel;
        return subB.submittedAt.compareTo(subA.submittedAt);
      });
      return allResults;
    });
  }

  Stream<List<Map<String, dynamic>>> getRecentSubmissionsByAdminStream(
    String adminId,
  ) {
    return _examsCollection
        .where('adminId', isEqualTo: adminId)
        .snapshots()
        .asyncMap((examSnapshot) async {
          List<Map<String, dynamic>> allResults = [];
          for (var examDoc in examSnapshot.docs) {
            final subSnapshot = await _examsCollection
                .doc(examDoc.id)
                .collection('submissions')
                .orderBy('submittedAt', descending: true)
                .get();
            for (var subDoc in subSnapshot.docs) {
              allResults.add({
                'examId': examDoc.id,
                'submission': StudentSubmissionModel.fromFirestore(subDoc),
              });
            }
          }
          allResults.sort((a, b) {
            final subA = a['submission'] as StudentSubmissionModel;
            final subB = b['submission'] as StudentSubmissionModel;
            return subB.submittedAt.compareTo(subA.submittedAt);
          });
          return allResults;
        });
  }

  Future<StudentSubmissionModel> submitExamAttempt({
    required String examId,
    required ExamModel exam,
    required String studentId,
    required String studentName,
    String? studentAdminId,
    String? studentImageUrl,
    required Map<String, String> selectedAnswers,
  }) async {
    final examDocRef = _examsCollection.doc(examId);
    final submissionsRef = examDocRef.collection('submissions');
    if (studentAdminId != null &&
        studentAdminId.isNotEmpty &&
        exam.adminId.isNotEmpty &&
        exam.adminId != studentAdminId) {
      throw Exception(
        'Unauthorized: You are only allowed to attempt tests created by your assigned Admin.',
      );
    }
    final existingAttemptsQuery = await submissionsRef
        .where('userId', isEqualTo: studentId)
        .get();
    if (existingAttemptsQuery.docs.length >= maxExamAttempts)
      throw Exception('Maximum attempts reached.');
    final int currentAttemptNumber = existingAttemptsQuery.docs.length + 1;

    int correctCount = 0, incorrectCount = 0, unattemptedCount = 0;
    double totalMarksObtained = 0.0;
    for (var question in exam.questions) {
      final chosenOption = selectedAnswers[question.id];
      if (chosenOption == null || chosenOption.isEmpty) {
        unattemptedCount++;
      } else if (chosenOption == question.correctOptionId) {
        correctCount++;
        totalMarksObtained += question.marks;
      } else {
        incorrectCount++;
        totalMarksObtained -= exam.negativeMarking;
      }
    }
    if (totalMarksObtained < 0) totalMarksObtained = 0;
    final scorePercentage = exam.totalMarks > 0
        ? (totalMarksObtained / exam.totalMarks) * 100
        : 0.0;
    final isPassed = scorePercentage >= exam.passingScorePercentage;
    final submissionDocRef = submissionsRef.doc();
    final userAttemptRef = _firestore
        .collection('users')
        .doc(studentId)
        .collection('attempts')
        .doc(submissionDocRef.id);

    final submission = StudentSubmissionModel(
      id: submissionDocRef.id,
      studentName: studentName,
      studentId: studentId,
      studentImageUrl: studentImageUrl,
      examTitle: exam.title,
      scorePercentage: scorePercentage,
      marksObtained: totalMarksObtained,
      totalMarks: exam.totalMarks,
      correctAnswers: correctCount,
      incorrectAnswers: incorrectCount,
      unattemptedAnswers: unattemptedCount,
      isPassed: isPassed,
      isOnline: false,
      submittedAt: DateTime.now(),
      answers: selectedAnswers,
    );

    final submissionData = {
      'id': submissionDocRef.id,
      'userId': studentId,
      'studentId': studentId,
      'adminId': exam.adminId,
      'examId': examId,
      'attemptNumber': currentAttemptNumber,
      'studentName': submission.studentName,
      'studentImageUrl': submission.studentImageUrl,
      'examTitle': submission.examTitle,
      'scorePercentage': submission.scorePercentage,
      'marksObtained': submission.marksObtained,
      'totalMarks': submission.totalMarks,
      'correctAnswers': submission.correctAnswers,
      'incorrectAnswers': submission.incorrectAnswers,
      'unattemptedAnswers': submission.unattemptedAnswers,
      'isPassed': submission.isPassed,
      'isOnline': false,
      'submittedAt': Timestamp.fromDate(submission.submittedAt),
      'answers': selectedAnswers,
    };

    final batch = _firestore.batch();
    batch.set(submissionDocRef, submissionData);
    batch.set(userAttemptRef, submissionData);
    await batch.commit();
    try {
      await examDocRef.update({
        'submissionsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
    return submission;
  }

  Future<String> submitExam({
    required String examId,
    required StudentSubmissionModel submission,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User is not authenticated");
    final examDocRef = _examsCollection.doc(examId);
    final examSubmissionRef = examDocRef.collection('submissions').doc();
    final userAttemptRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('attempts')
        .doc(examSubmissionRef.id);
    final examSnap = await examDocRef.get();
    final examData = examSnap.data() as Map<String, dynamic>? ?? {};
    final data = submission.toMap();
    data['id'] = examSubmissionRef.id;
    data['userId'] = user.uid;
    data['studentId'] = user.uid;
    data['adminId'] = (examData['adminId'] ?? '').toString();
    data['examId'] = examId;
    data['submittedAt'] = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    batch.set(examSubmissionRef, data);
    batch.set(userAttemptRef, data);
    await batch.commit();
    try {
      await examDocRef.update({
        'submissionsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Warning: $e");
    }
    return examSubmissionRef.id;
  }

  Stream<List<QuestionModel>> getQuestionBankStream({
    String? category,
    String? adminId,
    String role = 'admin',
  }) {
    Query query = _questionBankCollection;
    if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
      query = query.where('adminId', isEqualTo: adminId);
    if (category != null &&
        category.isNotEmpty &&
        category != 'All Subjects' &&
        category != 'All')
      query = query.where('category', isEqualTo: category);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => QuestionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addQuestionToBank(
    QuestionModel question, {
    String? adminId,
  }) async {
    final docRef = _questionBankCollection.doc();
    final newQuestion = QuestionModel(
      id: docRef.id,
      questionText: question.questionText,
      marks: question.marks,
      options: question.options,
      correctOptionId: question.correctOptionId,
      type: question.type,
      category: question.category,
      difficulty: question.difficulty,
      adminId: (adminId != null && adminId.isNotEmpty)
          ? adminId
          : question.adminId,
      views: 0,
      estimatedTimeMinutes: question.estimatedTimeMinutes,
      createdAt: DateTime.now(),
    );
    await docRef.set(newQuestion.toMap());
  }

  // FIXED: Was Stream> and List>
  Stream<Map<String, dynamic>> getDashboardMetricsStream({
    String? adminId,
    String role = 'admin',
  }) {
    Query examQuery = _firestore.collection('exams');
    if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
      examQuery = examQuery.where('adminId', isEqualTo: adminId);
    return examQuery.snapshots().asyncMap((examSnap) async {
      final activeExamsCount = examSnap.docs
          .where(
            (doc) =>
                ((doc.data() as Map<String, dynamic>?)?['status'] ?? '')
                    .toString()
                    .toLowerCase() ==
                'published',
          )
          .length;
      int studentCount = 0;
      try {
        Query usersQuery = _firestore
            .collection('users')
            .where('role', isEqualTo: 'student');
        if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
          usersQuery = usersQuery.where('adminId', isEqualTo: adminId);
        studentCount = (await usersQuery.get()).docs.length;
      } catch (_) {
        studentCount = 0;
      }
      int bankCount = 0;
      try {
        Query bankQuery = _firestore.collection('question_bank');
        if (role != 'super_admin' && adminId != null && adminId.isNotEmpty)
          bankQuery = bankQuery.where('adminId', isEqualTo: adminId);
        bankCount = (await bankQuery.get()).docs.length;
      } catch (_) {
        bankCount = 0;
      }
      return {
        'totalStudents': studentCount,
        'activeExams': activeExamsCount,
        'totalQuizzesBank': bankCount,
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getRecentActivitiesStream() {
    return _firestore
        .collection('admin_activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<bool> toggleSaveExam({
    required String userId,
    required ExamModel exam,
  }) async {
    if (userId.isEmpty || exam.id.isEmpty) return false;
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_exams')
        .doc(exam.id);
    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.delete();
      return false;
    } else {
      final examData = exam.toMap();
      examData['id'] = exam.id;
      examData['savedAt'] = FieldValue.serverTimestamp();
      await docRef.set(examData);
      return true;
    }
  }

  Stream<List<Map<String, dynamic>>> getSavedExamsStream(String userId) {
    if (userId.isEmpty) return Stream.value(<Map<String, dynamic>>[]);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('saved_exams')
        .snapshots()
        .map((snapshot) {
          final list = <Map<String, dynamic>>[];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              final dynamic rawSavedAt = data['savedAt'] ?? data['createdAt'];
              final DateTime savedAt = rawSavedAt is Timestamp
                  ? rawSavedAt.toDate()
                  : DateTime.now();
              final ExamModel exam = ExamModel(
                id: doc.id,
                examCode: data['examCode'] ?? '',
                title: data['title'] ?? 'Assessment',
                category: data['category'] ?? 'General',
                adminId: data['adminId'] ?? '',
                durationMinutes:
                    (data['durationMinutes'] as num?)?.toInt() ?? 60,
                totalMarks: (data['totalMarks'] as num?)?.toDouble() ?? 100.0,
                passingScorePercentage:
                    (data['passingScorePercentage'] as num?)?.toDouble() ??
                    50.0,
                negativeMarking:
                    (data['negativeMarking'] as num?)?.toDouble() ?? 0.0,
                status: data['status'] ?? 'Published',
                questions: (data['questions'] as List<dynamic>? ?? [])
                    .map(
                      (q) => QuestionModel.fromMap(q as Map<String, dynamic>),
                    )
                    .toList(),
                submissionsCount:
                    (data['submissionsCount'] as num?)?.toInt() ?? 0,
                createdAt: data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                updatedAt: data['updatedAt'] is Timestamp
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : DateTime.now(),
              );
              list.add({'exam': exam, 'savedAt': savedAt});
            } catch (e) {
              debugPrint('Failed to parse ${doc.id}: $e');
            }
          }
          list.sort(
            (a, b) =>
                (a['savedAt'] as DateTime).compareTo(b['savedAt'] as DateTime) *
                -1,
          );
          return list;
        });
  }

  Stream<List<Map<String, dynamic>>> getUserExamAttemptsStream(String userId) {
    if (userId.isEmpty) return Stream.value(<Map<String, dynamic>>[]);
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('attempts')
        .snapshots()
        .map((snapshot) {
          final list = <Map<String, dynamic>>[];
          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();
              list.add({
                'examId': (data['examId'] ?? '').toString(),
                'submission': StudentSubmissionModel.fromFirestore(doc),
                'adminId': (data['adminId'] ?? '').toString(),
              });
            } catch (e) {
              debugPrint('Error ${doc.id}: $e');
            }
          }
          list.sort(
            (a, b) => (b['submission'] as StudentSubmissionModel).submittedAt
                .compareTo(
                  (a['submission'] as StudentSubmissionModel).submittedAt,
                ),
          );
          return list;
        });
  }

  Stream<Map<String, dynamic>> getUserPerformanceMetricsStream(String userId) {
    return getUserExamAttemptsStream(userId).map((attemptsList) {
      if (attemptsList.isEmpty) return {'overallProgress': 0, 'studyStreak': 0};
      double totalScore = 0.0;
      final Set<String> uniqueDays = {};
      for (var item in attemptsList) {
        final sub = item['submission'] as StudentSubmissionModel;
        totalScore += sub.scorePercentage;
        final d = sub.submittedAt;
        uniqueDays.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        );
      }
      int streak = 0;
      DateTime checkDate = DateTime.now();
      String todayKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (!uniqueDays.contains(todayKey))
        checkDate = checkDate.subtract(const Duration(days: 1));
      while (true) {
        final key =
            '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
        if (uniqueDays.contains(key)) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
      return {
        'overallProgress': (totalScore / attemptsList.length).round(),
        'studyStreak': streak,
      };
    });
  }
}
