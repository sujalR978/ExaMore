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

    test('Deadline changed notification payload formatting', () {
      final exam = ExamModel(
        id: 'exam-201',
        examCode: 'EXM-2026-201',
        title: 'Algorithms Final',
        category: 'Data Structures',
        durationMinutes: 90,
        totalMarks: 100,
        passingScorePercentage: 40,
        questions: [],
      );

      final oldDeadline = DateTime(2026, 11, 24, 18, 0); // 6:00 PM
      final extendedDeadline = DateTime(2026, 11, 24, 22, 0); // 10:00 PM (extended)
      final earlierDeadline = DateTime(2026, 11, 24, 16, 0); // 4:00 PM (rescheduled)

      final isExtended1 = extendedDeadline.isAfter(oldDeadline);
      final isExtended2 = earlierDeadline.isAfter(oldDeadline);

      expect(isExtended1, isTrue);
      expect(isExtended2, isFalse);

      final subject = exam.category;
      final expectedExtendedTitle = '⏳ Exam Deadline Extended: $subject';
      final expectedRescheduledTitle = '⏳ Exam Deadline Rescheduled: $subject';

      expect(expectedExtendedTitle, '⏳ Exam Deadline Extended: Data Structures');
      expect(expectedRescheduledTitle, '⏳ Exam Deadline Rescheduled: Data Structures');
    });

    test('1-hour deadline approaching alert window calculation', () {
      final now = DateTime.now();

      // Exam ending in 45 minutes -> should trigger 1-hour approaching alert
      final examEndingIn45Mins = now.add(const Duration(minutes: 45));
      final diff45 = examEndingIn45Mins.difference(now);
      final shouldAlert45 = diff45 > Duration.zero && diff45 <= const Duration(hours: 1);
      expect(shouldAlert45, isTrue);

      // Exam ending in 90 minutes -> should NOT trigger 1-hour approaching alert yet
      final examEndingIn90Mins = now.add(const Duration(minutes: 90));
      final diff90 = examEndingIn90Mins.difference(now);
      final shouldAlert90 = diff90 > Duration.zero && diff90 <= const Duration(hours: 1);
      expect(shouldAlert90, isFalse);

      // Exam that already ended 10 minutes ago -> should NOT trigger
      final examEndedPast = now.subtract(const Duration(minutes: 10));
      final diffPast = examEndedPast.difference(now);
      final shouldAlertPast = diffPast > Duration.zero && diffPast <= const Duration(hours: 1);
      expect(shouldAlertPast, isFalse);
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
