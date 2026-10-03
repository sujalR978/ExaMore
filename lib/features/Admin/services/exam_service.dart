import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class ExamService {
  final CollectionReference _examsCollection = FirebaseFirestore.instance
      .collection('exams');

  // Generate clean IDs like EXM-2026-089
  String _generateExamCode() {
    final randomDigits = (100 + Random().nextInt(900)).toString();
    final year = DateTime.now().year;
    return 'EXM-$year-$randomDigits';
  }

  // Create new exam draft
  Future<String> createExamDraft(ExamModel exam) async {
    final docRef = _examsCollection.doc();
    final finalExam = exam.copyWith(
      id: docRef.id,
      examCode: exam.examCode.isEmpty ? _generateExamCode() : exam.examCode,
      status: 'Draft',
      updatedAt: DateTime.now(),
    );
    await docRef.set(finalExam.toMap());
    return docRef.id;
  }

  // Update existing exam
  Future<void> updateExam(ExamModel exam) async {
    await _examsCollection.doc(exam.id).update({
      ...exam.toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  // Publish exam
  Future<void> publishExam(String examId) async {
    await _examsCollection.doc(examId).update({
      'status': 'Published',
      'updatedAt': Timestamp.now(),
    });
  }

  // Append a single question to an existing exam
  Future<void> addQuestionToExam(String examId, QuestionModel question) async {
    await _examsCollection.doc(examId).update({
      'questions': FieldValue.arrayUnion([question.toMap()]),
      'updatedAt': Timestamp.now(),
    });
  }

  // Stream active & draft exams (with optional category filter)
  Stream<List<ExamModel>> getExamsStream({String? category}) {
    Query query = _examsCollection.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExamModel.fromFirestore(doc)).toList();
    });
  }

  // Stream a single exam by ID
  Stream<ExamModel> getExamStream(String examId) {
    return _examsCollection.doc(examId).snapshots().map((doc) {
      return ExamModel.fromFirestore(doc);
    });
  }

  // Delete an exam
  Future<void> deleteExam(String examId) async {
    await _examsCollection.doc(examId).delete();
  }

  Stream<List<StudentSubmissionModel>> getExamSubmissionsStream(String examId) {
    return _examsCollection
        .doc(examId)
        .collection('submissions')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => StudentSubmissionModel.fromFirestore(doc))
              .toList();

          // Sort by score or date in memory
          list.sort((a, b) => b.scorePercentage.compareTo(a.scorePercentage));
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

  // Stream all student submissions across all exams
  Stream<List<Map<String, dynamic>>> getAllRecentSubmissionsStream() {
    return FirebaseFirestore.instance
        .collectionGroup('submissions')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            // Parent document represents the exam
            final examId = doc.reference.parent.parent?.id ?? '';
            final model = StudentSubmissionModel.fromFirestore(doc);
            return {'examId': examId, 'submission': model};
          }).toList();

          // Sort in memory (newest first) to avoid requiring a Firestore composite index
          list.sort((a, b) {
            final aTime =
                (a['submission'] as StudentSubmissionModel).submittedAt;
            final bTime =
                (b['submission'] as StudentSubmissionModel).submittedAt;
            return bTime.compareTo(aTime);
          });

          return list;
        });
  }

  final CollectionReference _questionBankCollection = FirebaseFirestore.instance
      .collection('question_bank');

  // Stream question bank questions with category filtering
  Stream<List<QuestionModel>> getQuestionBankStream({String? category}) {
    Query query = _questionBankCollection.orderBy(
      'createdAt',
      descending: true,
    );

    if (category != null && category.isNotEmpty && category != 'All Subjects') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => QuestionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              docId: doc.id,
            ),
          )
          .toList();
    });
  }

  // Add question directly to bank
  Future<void> addQuestionToBank(QuestionModel question) async {
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
      views: 0,
      estimatedTimeMinutes: question.estimatedTimeMinutes,
      createdAt: DateTime.now(),
    );
    await docRef.set(newQuestion.toMap());
  }

  // Create an exam pre-populated with selected bank questions
  Future<String> createExamWithQuestions({
    required String title,
    required String category,
    required List<QuestionModel> questions,
  }) async {
    final totalMarks = questions.fold<double>(0.0, (sum, q) => sum + q.marks);
    final exam = ExamModel(
      id: '',
      examCode: '',
      title: title,
      category: category,
      durationMinutes: questions.length * 2,
      totalMarks: totalMarks > 0 ? totalMarks : 100,
      questions: questions,
      status: 'Draft',
    );
    return await createExamDraft(exam);
  }

  // Get true live counts directly from your Firestore collections
  Stream<Map<String, int>> getDashboardMetricsStream() {
    final firestore = FirebaseFirestore.instance;

    return firestore.collection('exams').snapshots().asyncMap((examSnap) async {
      // 1. Published/Active Exams
      final activeExamsCount = examSnap.docs
          .where(
            (doc) =>
                (doc.data()['status'] ?? '').toString().toLowerCase() ==
                'published',
          )
          .length;

      // 2. Exact user count from Firestore
      int studentCount = 0;
      try {
        final usersSnap = await firestore.collection('users').get();
        studentCount = usersSnap.docs.length;
      } catch (_) {
        studentCount = 0;
      }

      // 3. Question Bank items count
      int bankCount = 0;
      try {
        final bankSnap = await firestore.collection('question_bank').get();
        bankCount = bankSnap.docs.length;
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

  // Stream recent administrative activities
  Stream<List<Map<String, dynamic>>> getRecentActivitiesStream() {
    return FirebaseFirestore.instance
        .collection('admin_activities')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<ExamModel>> getPublishedExamsStream({String? category}) {
    // Query only with where() — remove orderBy() from the Firestore query
    Query query = _examsCollection.where('status', isEqualTo: 'Published');

    if (category != null &&
        category.isNotEmpty &&
        category != 'All' &&
        category != 'All Subjects') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ExamModel.fromFirestore(doc))
          .toList();

      // Sort in memory by createdAt descending
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // 2. Submit student exam answers & calculate score automatically
  Future<StudentSubmissionModel> submitExamAttempt({
    required String examId,
    required ExamModel exam,
    required String studentId,
    required String studentName,
    String? studentImageUrl,
    required Map<String, String> selectedAnswers,
  }) async {
    int correctCount = 0;
    int incorrectCount = 0;
    int unattemptedCount = 0;
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

    final examDocRef = _examsCollection.doc(examId);

    // 1. Generate a unique submission document ID for each attempt
    final submissionDocRef = examDocRef.collection('submissions').doc();

    final submission = StudentSubmissionModel(
      id: submissionDocRef.id, // Unique attempt ID
      studentName: studentName,
      studentId: studentId, // Student's user ID
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
    );

    // 2. Save each attempt as its own document
    await submissionDocRef.set({
      'id': submissionDocRef.id,
      'userId': studentId, // Added to query by user across attempts
      'studentId': studentId,
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
      'selectedAnswers': selectedAnswers,
    });

    // Increment total submissions count
    await examDocRef.update({'submissionsCount': FieldValue.increment(1)});

    return submission;
  }

  // Toggle bookmark/save exam for a student
  // Toggle bookmark / saved exam
  // Toggle bookmark / save exam
  Future<bool> toggleSaveExam({
    required String userId,
    required ExamModel exam,
  }) async {
    if (userId.isEmpty || exam.id.isEmpty) {
      debugPrint('Cannot save exam: userId or exam.id is empty');
      return false;
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_exams')
        .doc(exam.id);

    final snapshot = await docRef.get();
    if (snapshot.exists) {
      await docRef.delete();
      return false; // Removed
    } else {
      // Explicitly write the exam data and ensure the ID and timestamps are valid
      final examData = exam.toMap();
      examData['id'] = exam.id;
      examData['savedAt'] = FieldValue.serverTimestamp();

      await docRef.set(examData);
      return true; // Saved
    }
  }

  // Stream bookmarked exams safely
  Stream<List<Map<String, dynamic>>> getSavedExamsStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_exams')
        .snapshots()
        .map((snapshot) {
          final list = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            try {
              final data = doc.data();

              // 1. Safe extraction of saved timestamp
              final dynamic rawSavedAt = data['savedAt'] ?? data['createdAt'];
              final DateTime savedAt = rawSavedAt is Timestamp
                  ? rawSavedAt.toDate()
                  : DateTime.now();

              // 2. Safe parsing of ExamModel with doc.id fallback
              final ExamModel exam = ExamModel(
                id: doc.id,
                examCode: data['examCode'] ?? '',
                title: data['title'] ?? 'Assessment',
                category: data['category'] ?? 'General',
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
              );

              list.add({'exam': exam, 'savedAt': savedAt});
            } catch (e) {
              debugPrint('Failed to parse saved exam ${doc.id}: $e');
            }
          }

          // In-memory sort (newest first)
          list.sort((a, b) {
            final aDate = a['savedAt'] as DateTime;
            final bDate = b['savedAt'] as DateTime;
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

  // Stream all attempts/submissions made by a specific student across all exams
  // Stream all attempts/submissions made by a specific student across all exams
  Stream<List<Map<String, dynamic>>> getUserExamAttemptsStream(String userId) {
    return FirebaseFirestore.instance
        .collectionGroup('submissions')
        .snapshots()
        .map((snapshot) {
          final list = <Map<String, dynamic>>[];

          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Match by the student's ID inside the document
            final matchesUser =
                data['userId'] == userId ||
                data['studentId'] == userId ||
                doc.id == userId;

            if (matchesUser) {
              final examId = doc.reference.parent.parent?.id ?? '';
              final submission = StudentSubmissionModel.fromFirestore(doc);
              list.add({'examId': examId, 'submission': submission});
            }
          }

          // Sort newest submission first
          list.sort((a, b) {
            final aDate =
                (a['submission'] as StudentSubmissionModel).submittedAt;
            final bDate =
                (b['submission'] as StudentSubmissionModel).submittedAt;
            return bDate.compareTo(aDate);
          });

          return list;
        });
  }

  // Calculate dynamic overall progress percentage and study streak days
  Stream<Map<String, int>> getUserPerformanceMetricsStream(String userId) {
    return getUserExamAttemptsStream(userId).map((attemptsList) {
      if (attemptsList.isEmpty) {
        return {'overallProgress': 0, 'studyStreak': 0};
      }

      // 1. Calculate Average Score (Overall Progress)
      double totalScorePercentage = 0.0;
      final Set<String> uniqueDays = {};

      for (var item in attemptsList) {
        final submission = item['submission'] as StudentSubmissionModel;
        totalScorePercentage += submission.scorePercentage;

        // Group by calendar date (yyyy-MM-dd)
        final d = submission.submittedAt;
        final dateKey =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        uniqueDays.add(dateKey);
      }

      final avgProgress = (totalScorePercentage / attemptsList.length).round();

      // 2. Calculate Consecutive Active Days (Study Streak)
      int streak = 0;
      DateTime checkDate = DateTime.now();

      // Check if user did an exam today; if not, check if they did one yesterday to keep streak active
      String todayKey =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (!uniqueDays.contains(todayKey)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

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

      return {'overallProgress': avgProgress, 'studyStreak': streak};
    });
  }

  // Stream all submissions across all exams for Admin Results Screen
  Stream<List<StudentSubmissionModel>> getAllSubmissionsStream() {
    return FirebaseFirestore.instance
        .collectionGroup(
          'submissions',
        ) // Removed .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => StudentSubmissionModel.fromFirestore(doc))
              .toList();

          // Sort newest first in Dart memory
          list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return list;
        });
  }
}
