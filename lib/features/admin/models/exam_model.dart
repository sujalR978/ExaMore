import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionOption {
  final String id;
  final String text;
  final String? imageUrl;

  QuestionOption({required this.id, required this.text, this.imageUrl});

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'imageUrl': imageUrl};
  }

  factory QuestionOption.fromMap(Map<String, dynamic> map) {
    return QuestionOption(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }
}

class QuestionModel {
  final String id;
  final String questionText;
  final double marks;
  final List<QuestionOption> options;
  final String correctOptionId;
  final String type;
  final String category;
  final String difficulty;
  final String adminId; // <-- Creator/Admin UID for cohort isolation
  final int views;
  final int estimatedTimeMinutes;
  final DateTime createdAt;
  final String? imageUrl; // Question image (base64 or URL)

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.marks,
    required this.options,
    required this.correctOptionId,
    this.type = 'Multiple Choice',
    this.category = 'General',
    this.difficulty = 'Medium',
    this.adminId = '',
    this.views = 0,
    this.estimatedTimeMinutes = 2,
    this.imageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  QuestionModel sanitizeForStudent() {
    return QuestionModel(
      id: id,
      questionText: questionText,
      marks: marks,
      options: options,
      correctOptionId: '', // Stripped to prevent client-side answer key inspection
      type: type,
      category: category,
      difficulty: difficulty,
      adminId: adminId,
      views: views,
      estimatedTimeMinutes: estimatedTimeMinutes,
      imageUrl: imageUrl,
      createdAt: createdAt,
    );
  }

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
      'adminId': adminId,
      'views': views,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawOptions = map['options'];
    final List<QuestionOption> parsedOptions = [];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt is Map) {
          parsedOptions.add(
            QuestionOption.fromMap(Map<String, dynamic>.from(opt)),
          );
        }
      }
    }

    final rawCreatedAt = map['createdAt'];
    DateTime createdAtDate;
    if (rawCreatedAt is Timestamp) {
      createdAtDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAtDate = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else {
      createdAtDate = DateTime.now();
    }

    return QuestionModel(
      id: docId ?? map['id']?.toString() ?? '',
      questionText: map['questionText']?.toString() ?? '',
      marks: (map['marks'] as num?)?.toDouble() ??
          double.tryParse(map['marks']?.toString() ?? '') ??
          1.0,
      options: parsedOptions,
      correctOptionId: map['correctOptionId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'Multiple Choice',
      category: map['category']?.toString() ?? 'General',
      difficulty: map['difficulty']?.toString() ?? 'Medium',
      adminId: map['adminId']?.toString() ?? '',
      views: (map['views'] as num?)?.toInt() ?? 0,
      estimatedTimeMinutes: (map['estimatedTimeMinutes'] as num?)?.toInt() ?? 2,
      imageUrl: map['imageUrl'] as String?,
      createdAt: createdAtDate,
    );
  }
}

class ExamModel {
  final String id;
  final String examCode; //'EXM-2024-089'
  final String title;
  final String category;
  final String adminId; // Creator/Admin UID for 3-tier role filtering
  final int durationMinutes;
  final double totalMarks;
  final double negativeMarking;
  final double passingScorePercentage; // 65%
  final bool shuffleQuestions;
  final bool showResultsImmediately;
  final String status; // 'Draft' or 'Published'
  final int allowedAttempts; // 1, 2, 3...
  final DateTime? startDate;
  final DateTime? endDate; // Closes at (Timeslot end)
  final int enrolledCount;
  final int submissionsCount;
  final List<QuestionModel> questions;
  final String? classroomId;
  final String? classroomName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExamModel({
    required this.id,
    required this.examCode,
    required this.title,
    required this.category,
    this.adminId = '',
    this.classroomId,
    this.classroomName,
    required this.durationMinutes,
    required this.totalMarks,
    this.negativeMarking = 0.0,
    this.passingScorePercentage = 60.0,
    this.shuffleQuestions = false,
    this.showResultsImmediately = false,
    this.status = 'Draft',
    this.allowedAttempts = 1,
    this.startDate,
    this.endDate,
    this.enrolledCount = 0,
    this.submissionsCount = 0,
    this.questions = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isScheduled =>
      startDate != null && DateTime.now().isBefore(startDate!);
  bool get isClosed => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isCurrentlyOpen => !isScheduled && !isClosed;

  ExamModel sanitizeForStudent() {
    return ExamModel(
      id: id,
      examCode: examCode,
      title: title,
      category: category,
      adminId: adminId,
      classroomId: classroomId,
      classroomName: classroomName,
      durationMinutes: durationMinutes,
      totalMarks: totalMarks,
      negativeMarking: negativeMarking,
      passingScorePercentage: passingScorePercentage,
      shuffleQuestions: shuffleQuestions,
      showResultsImmediately: showResultsImmediately,
      status: status,
      allowedAttempts: allowedAttempts,
      startDate: startDate,
      endDate: endDate,
      enrolledCount: enrolledCount,
      submissionsCount: submissionsCount,
      questions: questions.map((q) => q.sanitizeForStudent()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examCode': examCode,
      'title': title,
      'category': category,
      'adminId': adminId,
      'classroomId': classroomId,
      'classroomName': classroomName,
      'durationMinutes': durationMinutes,
      'totalMarks': totalMarks,
      'negativeMarking': negativeMarking,
      'passingScorePercentage': passingScorePercentage,
      'shuffleQuestions': shuffleQuestions,
      'showResultsImmediately': showResultsImmediately,
      'status': status,
      'allowedAttempts': allowedAttempts,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'enrolledCount': enrolledCount,
      'submissionsCount': submissionsCount,
      'questions': questions.map((q) => q.toMap()).toList(),
      'questionCount': questions.length,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ExamModel.fromMap(Map<String, dynamic> data, [String? docId]) {
    return ExamModel(
      id: docId ?? data['id'] ?? '',
      examCode: data['examCode'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? 'General',
      adminId: data['adminId'] ?? '',
      classroomId: data['classroomId'] as String?,
      classroomName: data['classroomName'] as String?,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      totalMarks: (data['totalMarks'] as num?)?.toDouble() ?? 0.0,
      negativeMarking: (data['negativeMarking'] as num?)?.toDouble() ?? 0.0,
      passingScorePercentage:
          (data['passingScorePercentage'] as num?)?.toDouble() ?? 0.0,
      shuffleQuestions: data['shuffleQuestions'] ?? false,
      showResultsImmediately: data['showResultsImmediately'] ?? false,
      status: data['status'] ?? 'Draft',
      allowedAttempts: (data['allowedAttempts'] as num?)?.toInt() ?? 1,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      enrolledCount: (data['enrolledCount'] as num?)?.toInt() ?? 0,
      submissionsCount: (data['submissionsCount'] as num?)?.toInt() ?? 0,
      questions: (data['questions'] as List<dynamic>? ?? []).map((q) {
        if (q is Map) {
          return QuestionModel.fromMap(Map<String, dynamic>.from(q));
        }
        return null;
      }).whereType<QuestionModel>().toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory ExamModel.fromFirestore(DocumentSnapshot doc) {
    return ExamModel.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id);
  }

  ExamModel copyWith({
    String? id,
    String? examCode,
    String? title,
    String? category,
    String? adminId,
    String? classroomId,
    String? classroomName,
    int? durationMinutes,
    double? totalMarks,
    double? negativeMarking,
    double? passingScorePercentage,
    bool? shuffleQuestions,
    bool? showResultsImmediately,
    String? status,
    int? allowedAttempts,
    DateTime? startDate,
    DateTime? endDate,
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
      adminId: adminId ?? this.adminId,
      classroomId: classroomId ?? this.classroomId,
      classroomName: classroomName ?? this.classroomName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalMarks: totalMarks ?? this.totalMarks,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      passingScorePercentage:
          passingScorePercentage ?? this.passingScorePercentage,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      showResultsImmediately:
          showResultsImmediately ?? this.showResultsImmediately,
      status: status ?? this.status,
      allowedAttempts: allowedAttempts ?? this.allowedAttempts,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
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
  final Map<String, dynamic> answers;

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
    this.answers = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentName': studentName,
      'studentId': studentId,
      'studentImageUrl': studentImageUrl,
      'examTitle': examTitle,
      'scorePercentage': scorePercentage,
      'marksObtained': marksObtained,
      'totalMarks': totalMarks,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unattemptedAnswers': unattemptedAnswers,
      'isPassed': isPassed,
      'isOnline': isOnline,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'answers': answers,
    };
  }

  factory StudentSubmissionModel.fromMap(
    Map<String, dynamic> data, [
    String? docId,
  ]) {
    return StudentSubmissionModel(
      id: docId ?? data['id'] ?? '',
      studentName: data['studentName'] ?? 'Anonymous Student',
      studentId:
          data['studentId'] ??
          (docId != null && docId.length >= 6
              ? docId.substring(0, 6).toUpperCase()
              : 'UNKNOWN'),
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
      submittedAt: (data['submittedAt'] is Timestamp)
          ? (data['submittedAt'] as Timestamp).toDate()
          : (data['submittedAt'] is String
                ? DateTime.tryParse(data['submittedAt']) ?? DateTime.now()
                : DateTime.now()),
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
    );
  }

  factory StudentSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentSubmissionModel.fromMap(data, doc.id);
  }
}

class BulkUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadQuestionsBatch(List<QuestionModel> questions) async {
    if (questions.isEmpty) return;

    final WriteBatch batch = _firestore.batch();
    final CollectionReference bankCollection = _firestore.collection(
      'question_bank',
    );

    for (final question in questions) {
      final docRef = bankCollection.doc();

      final Map<String, dynamic> data = {
        'id': docRef.id,
        'questionText': question.questionText,
        'marks': question.marks,
        'options': question.options.map((o) => o.toMap()).toList(),
        'correctOptionId': question.correctOptionId,
        'type': question.type,
        'category': question.category,
        'difficulty': question.difficulty,
        'views': 0,
        'estimatedTimeMinutes': question.estimatedTimeMinutes,
        'createdAt': FieldValue.serverTimestamp(),
      };

      batch.set(docRef, data);
    }

    await batch.commit();
  }
}
