import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:prep_mate/features/user/screens/exam_detail_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message received: ${message.messageId}');
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isInitialized = false;
  String? _lastToken;

  String? get fcmToken => _lastToken;

  /// Initialize Firebase Messaging, request permissions, and register listeners
  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    if (navKey != null) navigatorKey = navKey;

    try {
      // 1. Request notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 2. Configure foreground notification presentation
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 4. Retrieve initial token & persist to Firestore
      final token = await _fcm.getToken();
      if (token != null) {
        _lastToken = token;
        await updateUserToken(token);
      }

      // 5. Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
        updateUserToken(newToken);
      });

      // 6. Listen for incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 7. Listen for notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationNavigation(message.data);
      });

      // 8. Handle notification that launched the app from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }
    } catch (e) {
      debugPrint('FCM initialization warning (may be test/unsupported environment): $e');
    }
  }

  /// Updates the current authenticated user's FCM token in their Firestore user doc
  Future<void> updateUserToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Saved FCM token for user ${user.uid}');
    } catch (e) {
      debugPrint('Failed to save FCM token in Firestore: $e');
    }
  }

  /// Subscribes the student to relevant exam notification topics
  Future<void> subscribeStudentTopics({
    String? studentClassroomId,
    String? adminId,
  }) async {
    try {
      await _fcm.subscribeToTopic('all_students');
      if (studentClassroomId != null && studentClassroomId.isNotEmpty) {
        await _fcm.subscribeToTopic('classroom_$studentClassroomId');
      }
      if (adminId != null && adminId.isNotEmpty) {
        await _fcm.subscribeToTopic('admin_$adminId');
      }
    } catch (e) {
      debugPrint('Failed to subscribe to FCM topics: $e');
    }
  }

  /// Triggers a notification whenever an Admin creates/publishes a new exam.
  /// User requirement:
  /// "whenever Admin creates new exam then send the notification to the student user that New Exam of particular subject is added please check."
  Future<void> sendNewExamNotification(ExamModel exam) async {
    final subject = (exam.category.isNotEmpty ? exam.category : exam.title).trim();
    const notificationTitle = 'New Exam Available!';
    final notificationBody = 'New Exam of $subject is added, please check.';

    try {
      // 1. Target students for this exam
      Query query = _firestore.collection('users').where('role', isEqualTo: 'student');

      // If tied to a specific instructor/admin
      if (exam.adminId.isNotEmpty) {
        query = query.where('adminId', isEqualTo: exam.adminId);
      }

      final studentDocs = await query.get();
      final List<String> targetTokens = [];
      final List<String> studentIds = [];

      for (var doc in studentDocs.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        studentIds.add(doc.id);

        final token = (data['fcmToken'] ?? '').toString();
        if (token.isNotEmpty) {
          targetTokens.add(token);
        }

        final tokensList = (data['fcmTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
        for (var t in tokensList) {
          if (t.isNotEmpty && !targetTokens.contains(t)) {
            targetTokens.add(t);
          }
        }
      }

      // 2. Global notification document in 'notifications' collection
      final globalNotificationRef = _firestore.collection('notifications').doc();
      final notificationPayload = {
        'id': globalNotificationRef.id,
        'title': notificationTitle,
        'body': notificationBody,
        'subject': subject,
        'examId': exam.id,
        'examTitle': exam.title,
        'examCode': exam.examCode,
        'adminId': exam.adminId,
        'classroomId': exam.classroomId ?? '',
        'classroomName': exam.classroomName ?? '',
        'targetTokensCount': targetTokens.length,
        'targetStudentsCount': studentIds.length,
        'type': 'new_exam',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await globalNotificationRef.set(notificationPayload);

      // 3. Dispatch in-app notification to each student's personal notification inbox
      final batch = _firestore.batch();
      for (final studentId in studentIds) {
        final userNotifRef = _firestore
            .collection('users')
            .doc(studentId)
            .collection('notifications')
            .doc();

        batch.set(userNotifRef, {
          'id': userNotifRef.id,
          'title': notificationTitle,
          'body': notificationBody,
          'subject': subject,
          'examId': exam.id,
          'examTitle': exam.title,
          'examCode': exam.examCode,
          'adminId': exam.adminId,
          'type': 'new_exam',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // 4. Save to fcm_dispatch collection (for FCM Cloud Functions / HTTP v1 relay)
      await _firestore.collection('fcm_dispatch').add({
        'title': notificationTitle,
        'body': notificationBody,
        'tokens': targetTokens,
        'topic': exam.classroomId?.isNotEmpty == true
            ? 'classroom_${exam.classroomId}'
            : (exam.adminId.isNotEmpty ? 'admin_${exam.adminId}' : 'all_students'),
        'data': {
          'examId': exam.id,
          'subject': subject,
          'type': 'new_exam',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'queued',
      });

      debugPrint('Dispatched New Exam notification for "$subject" to ${studentIds.length} students.');
    } catch (e) {
      debugPrint('Error dispatching new exam notification: $e');
    }
  }

  /// Stream of current user's in-app notifications
  Stream<List<Map<String, dynamic>>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Mark single notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  /// Handles in-app heads-up notification when app is in the foreground
  void _handleForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'ExaMore';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    final context = navigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF7C3AED),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: const Color(0xFFA78BFA),
          onPressed: () => _handleNotificationNavigation(message.data),
        ),
      ),
    );
  }

  /// Navigates to the corresponding exam when a notification is clicked
  void _handleNotificationNavigation(Map<String, dynamic> data) async {
    final examId = data['examId']?.toString();
    if (examId == null || examId.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      final doc = await _firestore.collection('exams').doc(examId).get();
      if (doc.exists && doc.data() != null) {
        final exam = ExamModel.fromMap(doc.data()!, doc.id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ExamdetailPage(exam: exam)),
        );
      }
    } catch (_) {}
  }
}
