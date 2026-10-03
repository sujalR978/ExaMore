import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionOption {
  final String id;
  final String text;

  QuestionOption({required this.id, required this.text});

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text};
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(id: map['id'] ?? '', text: map['text'] ?? '');
  }
}

class QuestionModel {
  final String id;
  final String questionText;
  final double marks;
  final List<QuestionOption> options;
  final String correctOptionId;
  final String type; // 'Multiple Choice', 'Short Answer', 'Essay'
  final String category; // 'Mathematics', 'Science', etc.
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final int views;
  final int estimatedTimeMinutes;
  final DateTime createdAt;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.marks,
    required this.options,
    required this.correctOptionId,
    this.type = 'Multiple Choice',
    this.category = 'General',
    this.difficulty = 'Medium',
    this.views = 0,
    this.estimatedTimeMinutes = 2,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'marks': marks,
      'options': options.map((o) => o.toMap()).toList(),
      'correctOptionId': correctOptionId,
      'type': type,
      'category': category,
      'difficulty': difficulty,
      'views': views,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return QuestionModel(
      id: docId ?? map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      marks: (map['marks'] as num?)?.toDouble() ?? 1.0,
      options: (map['options'] as List<dynamic>? ?? [])
          .map((o) => QuestionOption.fromMap(o as Map<String, dynamic>))
          .toList(),
      correctOptionId: map['correctOptionId'] ?? '',
      type: map['type'] ?? 'Multiple Choice',
      category: map['category'] ?? 'General',
      difficulty: map['difficulty'] ?? 'Medium',
      views: (map['views'] as num?)?.toInt() ?? 0,
      estimatedTimeMinutes: (map['estimatedTimeMinutes'] as num?)?.toInt() ?? 2,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
class ExamModel {
  final String id;
  final String examCode; // e.g., 'EXM-2024-089'
  final String title;
  final String category;
  final int durationMinutes;
  final double totalMarks;
  final double negativeMarking;
  final double passingScorePercentage; // e.g., 65%
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final String status; // 'Draft' or 'Published'
  final DateTime? startDate;
  final int enrolledCount;
  final int submissionsCount;
  final List<QuestionModel> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamModel({
    required this.id,
    required this.examCode,
    required this.title,
    required this.category,
    required this.durationMinutes,
    required this.totalMarks,
    this.negativeMarking = 0.0,
    this.passingScorePercentage = 60.0,
    this.shuffleQuestions = false,
    this.showResultsImmediately = false,
    this.status = 'Draft',
    this.startDate,
    this.enrolledCount = 0,
    this.submissionsCount = 0,
    this.questions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'examCode': examCode,
      'title': title,
      'category': category,
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks,
      'negativeMarking': negativeMarking,
      'passingScorePercentage': passingScorePercentage,
      'shuffleQuestions': shuffleQuestions,
      'showResultsImmediately': showResultsImmediately,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'enrolledCount': enrolledCount,
      'submissionsCount': submissionsCount,
      'questions': questions.map((q) => q.toMap()).toList(),
      'questionCount': questions.length,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ExamModel(
      id: doc.id,
      examCode: data['examCode'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'General',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      totalMarks: (data['totalMarks'] as num?)?.toDouble() ?? 0.0,
      negativeMarking: (data['negativeMarking'] as num?)?.toDouble() ?? 0.0,
      passingScorePercentage:
          (data['passingScorePercentage'] as num?)?.toDouble() ?? 0.0,
      shuffleQuestions: data['shuffleQuestions'] ?? false,
      showResultsImmediately: data['showResultsImmediately'] ?? false,
      status: data['status'] ?? 'Draft',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 0,
      submissionsCount: (data['submissionsCount'] as num?)?.toInt() ?? 0,
      questions: (data['questions'] as List<dynamic>? ?? [])
          .map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ExamModel copyWith({
    String? id,
    String? examCode,
    String? title,
    String? category,
    int? durationMinutes,
    double? totalMarks,
    double? negativeMarking,
    double? passingScorePercentage,
    bool? shuffleQuestions,
    bool? showResultsImmediately,
    String? status,
    DateTime? startDate,
    int? enrolledCount,
    int? submissionsCount,
    List<QuestionModel>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamModel(
      id: id ?? this.id,
      examCode: examCode ?? this.examCode,
      title: title ?? this.title,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      passingScorePercentage:
          passingScorePercentage ?? this.passingScorePercentage,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showResultsImmediately:
          showResultsImmediately ?? this.showResultsImmediately,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      submissionsCount: submissionsCount ?? this.submissionsCount,
      questions: questions ?? this.questions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
}
class StudentSubmissionModel {
  final String id;
  final String studentName;
  final String studentId;
  final String? studentImageUrl;
  final String examTitle;
  final double scorePercentage;
  final double marksObtained;
  final double totalMarks;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unattemptedAnswers;
  final bool isPassed;
  final bool isOnline;
  final DateTime submittedAt;

  StudentSubmissionModel({
    required this.id,
    required this.studentName,
    required this.studentId,
    this.studentImageUrl,
    this.examTitle = 'Exam Assessment',
    required this.scorePercentage,
    required this.marksObtained,
    this.totalMarks = 100.0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.unattemptedAnswers = 0,
    required this.isPassed,
    this.isOnline = true,
    required this.submittedAt,
  });

  factory StudentSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentSubmissionModel(
      id: doc.id,
      studentName: data['studentName'] ?? 'Anonymous Student',
      studentId: data['studentId'] ?? doc.id.substring(0, 6).toUpperCase(),
      studentImageUrl: data['studentImageUrl'],
      examTitle: data['examTitle'] ?? 'Exam Assessment',
      scorePercentage: (data['scorePercentage'] as num?)?.toDouble() ?? 0.0,
      marksObtained: (data['marksObtained'] as num?)?.toDouble() ?? 0.0,
      totalMarks: (data['totalMarks'] as num?)?.toDouble() ?? 100.0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      incorrectAnswers: (data['incorrectAnswers'] as num?)?.toInt() ?? 0,
      unattemptedAnswers: (data['unattemptedAnswers'] as num?)?.toInt() ?? 0,
      isPassed: data['isPassed'] ?? false,
      isOnline: data['isOnline'] ?? false,
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
}
