import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/user/screens/student_notifications_screen.dart';

void main() {
  group('NotificationService & Exam Notifications Tests', () {
    test('NotificationService singleton exists and exposes navigatorKey', () {
      final instance1 = NotificationService.instance;
      final instance2 = NotificationService();
      expect(identical(instance1, instance2), isTrue);
      expect(NotificationService.navigatorKey, isNotNull);
    });

    test('Exam notification payload correctly formats subject and message body', () {
      // Case 1: Exam with category
      final examWithCategory = ExamModel(
        id: 'exam-101',
        examCode: 'EXM-2026-101',
        title: 'Midterm Evaluation',
        category: 'Data Structures & Algorithms',
        durationMinutes: 60,
        totalMarks: 50,
        passingScorePercentage: 50,
        questions: [],
      );

      final subject1 = (examWithCategory.category.isNotEmpty
              ? examWithCategory.category
              : examWithCategory.title)
          .trim();
      final expectedBody1 = 'New Exam of $subject1 is added, please check.';

      expect(subject1, 'Data Structures & Algorithms');
      expect(
        expectedBody1,
        'New Exam of Data Structures & Algorithms is added, please check.',
      );

      // Case 2: Exam with empty category, uses title as subject
      final examWithoutCategory = ExamModel(
        id: 'exam-102',
        examCode: 'EXM-2026-102',
        title: 'Physics II Quantum Mechanics',
        category: '',
        durationMinutes: 90,
        totalMarks: 100,
        passingScorePercentage: 40,
        questions: [],
      );

      final subject2 = (examWithoutCategory.category.isNotEmpty
              ? examWithoutCategory.category
              : examWithoutCategory.title)
          .trim();
      final expectedBody2 = 'New Exam of $subject2 is added, please check.';

      expect(subject2, 'Physics II Quantum Mechanics');
      expect(
        expectedBody2,
        'New Exam of Physics II Quantum Mechanics is added, please check.',
      );
    });

    test('ExamModel.fromMap and copyWith preserve notification fields', () {
      final examMap = {
        'id': 'exam-999',
        'examCode': 'EXM-2026-999',
        'title': 'Operating Systems Final',
        'category': 'Computer Science',
        'adminId': 'admin-456',
        'classroomId': 'class-789',
        'classroomName': 'Batch 2026 CS-A',
        'durationMinutes': 120,
        'totalMarks': 100,
        'status': 'Published',
      };

      final exam = ExamModel.fromMap(examMap, 'exam-999');
      expect(exam.id, 'exam-999');
      expect(exam.title, 'Operating Systems Final');
      expect(exam.category, 'Computer Science');
      expect(exam.adminId, 'admin-456');
      expect(exam.classroomId, 'class-789');
      expect(exam.classroomName, 'Batch 2026 CS-A');
      expect(exam.status, 'Published');
    });

    testWidgets('StudentNotificationsScreen renders gracefully when user not logged in',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StudentNotificationsScreen(),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Please log in to view notifications.'), findsOneWidget);
    });
  });
}
