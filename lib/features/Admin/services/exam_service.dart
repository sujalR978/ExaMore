import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        .orderBy('scorePercentage', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StudentSubmissionModel.fromFirestore(doc))
              .toList(),
        );
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
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Parent document represents the exam
            final examId = doc.reference.parent.parent?.id ?? '';
            final model = StudentSubmissionModel.fromFirestore(doc);
            return {'examId': examId, 'submission': model};
          }).toList();
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
}
