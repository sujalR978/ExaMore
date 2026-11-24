import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
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
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'examore_channel',
    'ExaMore Exam Alerts',
    description: 'Notifications for published exams, deadline adjustments, and reminders',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  bool _isInitialized = false;
  String? _lastToken;

  String? get fcmToken => _lastToken;

  /// Initialize Firebase Messaging, local notifications, permissions, and listeners
  Future<void> initialize({GlobalKey<NavigatorState>? navKey}) async {
    if (_isInitialized) return;
    _isInitialized = true;
    if (navKey != null) navigatorKey = navKey;

    try {
      // 1. Initialize Flutter Local Notifications for native OS tray alerts
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleNotificationNavigation({'examId': payload});
          }
        },
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_channel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 2. Request FCM notification permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('FCM Permission status: ${settings.authorizationStatus}');

      // 3. Configure foreground notification presentation
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 5. Retrieve initial token & persist to Firestore
      final token = await _fcm.getToken();
      if (token != null) {
        _lastToken = token;
        await updateUserToken(token);
      }

      // 6. Listen for token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _lastToken = newToken;
        updateUserToken(newToken);
      });

      // 7. Listen for incoming foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleForegroundMessage(message);
      });

      // 8. Listen for notification click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationNavigation(message.data);
      });

      // 9. Handle notification that launched the app from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }

      // 10. Start periodic monitoring for approaching deadlines (1 hour alert)
      startDeadlineMonitoring();
    } catch (e) {
      debugPrint('FCM initialization warning (may be test/unsupported environment): $e');
    }
  }

  Timer? _deadlineMonitoringTimer;

  /// Starts automated periodic monitoring for exams closing within 1 hour
  void startDeadlineMonitoring() {
    _deadlineMonitoringTimer?.cancel();
    checkAndDispatchUpcomingDeadlines();
    _deadlineMonitoringTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => checkAndDispatchUpcomingDeadlines(),
    );
  }

  /// Cancels background deadline monitoring
  void stopDeadlineMonitoring() {
    _deadlineMonitoringTimer?.cancel();
    _deadlineMonitoringTimer = null;
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

  StreamSubscription? _userNotificationsSubscription;
  DateTime? _listenerStartTime;

  /// Starts real-time listening to user's notifications collection
  /// to trigger immediate native system tray notifications on the device
  void listenToUserNotifications(String userId) {
    if (userId.isEmpty) return;
    _userNotificationsSubscription?.cancel();
    _listenerStartTime = DateTime.now().subtract(const Duration(seconds: 5));

    _userNotificationsSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final rawCreatedAt = data['createdAt'];
          DateTime? createdAt;
          if (rawCreatedAt is Timestamp) {
            createdAt = rawCreatedAt.toDate();
          }

          if (createdAt != null &&
              _listenerStartTime != null &&
              createdAt.isAfter(_listenerStartTime!)) {
            final title = data['title']?.toString() ?? 'Exam Update';
            final body = data['body']?.toString() ?? '';
            final examId = data['examId']?.toString();
            final type = data['type']?.toString();

            showNativeNotification(
              title: title,
              body: body,
              examId: examId,
              type: type,
            );
          }
        }
      }
    }, onError: (e) {
      debugPrint('Error listening to user notifications: $e');
    });
  }

  /// Displays a real native Android/iOS system notification in the status bar
  Future<void> showNativeNotification({
    required String title,
    required String body,
    String? examId,
    String? type,
  }) async {
    try {
      final int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        id: notificationId,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: examId,
      );
    } catch (e) {
      debugPrint('Error displaying native notification: $e');
    }
  }

  /// Generic dispatcher: targets relevant students, writes in-app inbox docs, and queues FCM push
  Future<void> _dispatchNotification({
    required ExamModel exam,
    required String title,
    required String body,
    required String type, // 'new_exam', 'deadline_changed', 'deadline_approaching'
    Map<String, dynamic>? extraData,
  }) async {
    final subject = (exam.category.isNotEmpty ? exam.category : exam.title).trim();

    try {
      // 0. Trigger native OS system notification immediately on the current device
      await showNativeNotification(
        title: title,
        body: body,
        examId: exam.id,
        type: type,
      );

      // 1. Target students for this exam
      List<QueryDocumentSnapshot> studentDocs = [];
      if (exam.adminId.isNotEmpty) {
        final adminSpecific = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('adminId', isEqualTo: exam.adminId)
            .get();
        studentDocs = adminSpecific.docs;
      }

      if (studentDocs.isEmpty) {
        final allStudents = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .get();
        studentDocs = allStudents.docs;
      }

      final List<String> targetTokens = [];
      final List<String> studentIds = [];

      for (var doc in studentDocs) {
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

      // If testing in an environment where no student accounts exist yet, also add current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (studentIds.isEmpty && currentUser != null) {
        studentIds.add(currentUser.uid);
      }

      // 2. Global notification document in 'notifications' collection
      final globalNotificationRef = _firestore.collection('notifications').doc();
      final notificationPayload = {
        'id': globalNotificationRef.id,
        'title': title,
        'body': body,
        'subject': subject,
        'examId': exam.id,
        'examTitle': exam.title,
        'examCode': exam.examCode,
        'adminId': exam.adminId,
        'classroomId': exam.classroomId ?? '',
        'classroomName': exam.classroomName ?? '',
        'targetTokensCount': targetTokens.length,
        'targetStudentsCount': studentIds.length,
        'type': type,
        ...?extraData,
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
          'title': title,
          'body': body,
          'subject': subject,
          'examId': exam.id,
          'examTitle': exam.title,
          'examCode': exam.examCode,
          'adminId': exam.adminId,
          'type': type,
          ...?extraData,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      // 4. Save to fcm_dispatch collection (for FCM Cloud Functions / HTTP v1 relay)
      await _firestore.collection('fcm_dispatch').add({
        'title': title,
        'body': body,
        'tokens': targetTokens,
        'topic': exam.classroomId?.isNotEmpty == true
            ? 'classroom_${exam.classroomId}'
            : (exam.adminId.isNotEmpty ? 'admin_${exam.adminId}' : 'all_students'),
        'data': {
          'examId': exam.id,
          'subject': subject,
          'type': type,
          ...?extraData,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'queued',
      });

      debugPrint('Dispatched "$type" notification for "${exam.title}" to ${studentIds.length} students.');
    } catch (e) {
      debugPrint('Error dispatching "$type" notification: $e');
    }
  }

  /// 1) When any new Exam is getting published
  Future<void> sendNewExamNotification(ExamModel exam) async {
    final subject = (exam.category.isNotEmpty ? exam.category : exam.title).trim();
    const notificationTitle = 'New Exam Available!';
    final notificationBody = 'New Exam of $subject is added, please check.';

    await _dispatchNotification(
      exam: exam,
      title: notificationTitle,
      body: notificationBody,
      type: 'new_exam',
    );
  }

  /// 2) When any deadline is changed (extended or rescheduled)
  Future<void> sendDeadlineChangedNotification({
    required ExamModel exam,
    required DateTime oldDeadline,
    required DateTime newDeadline,
  }) async {
    final bool isExtended = newDeadline.isAfter(oldDeadline);
    final String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(newDeadline);

    final String title = isExtended ? '⏳ Exam Deadline Extended!' : '📅 Exam Deadline Updated';
    final String body = 'Deadline for "${exam.title}" has been ${isExtended ? 'extended' : 'rescheduled'} to $formattedDate. Please check the updated schedule.';

    await _dispatchNotification(
      exam: exam,
      title: title,
      body: body,
      type: 'deadline_changed',
      extraData: {
        'oldDeadline': Timestamp.fromDate(oldDeadline),
        'newDeadline': Timestamp.fromDate(newDeadline),
        'isExtended': isExtended,
      },
    );
  }

  /// 3) When an exam deadline is approaching (1 hour earlier)
  Future<void> sendDeadlineApproachingNotification(ExamModel exam) async {
    final String closeTimeStr = exam.endDate != null
        ? DateFormat('hh:mm a').format(exam.endDate!)
        : 'soon';

    final String title = '⏰ 1 Hour Left: ${exam.title}';
    final String body = 'Deadline approaching! "${exam.title}" closes in 1 hour at $closeTimeStr. Please submit your exam before it closes!';

    await _dispatchNotification(
      exam: exam,
      title: title,
      body: body,
      type: 'deadline_approaching',
      extraData: {
        if (exam.endDate != null) 'endDate': Timestamp.fromDate(exam.endDate!),
      },
    );
  }

  /// Automated monitor: checks all published exams and sends 1-hour approaching alerts
  Future<void> checkAndDispatchUpcomingDeadlines() async {
    try {
      final snapshot = await _firestore
          .collection('exams')
          .where('status', isEqualTo: 'Published')
          .get();

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawEnd = data['endDate'];
        if (rawEnd == null) continue;

        DateTime? endDate;
        if (rawEnd is Timestamp) {
          endDate = rawEnd.toDate();
        } else if (rawEnd is String) {
          endDate = DateTime.tryParse(rawEnd);
        }
        if (endDate == null) continue;

        final difference = endDate.difference(now);

        // Approaching deadline check: closes in > 0 minutes and <= 60 minutes (1 hour)
        if (difference > Duration.zero && difference <= const Duration(hours: 1)) {
          final alertDocId = '${doc.id}_1hour';
          final alertRef = _firestore.collection('exam_deadline_alerts').doc(alertDocId);
          final alertDoc = await alertRef.get();

          // Deduplicate: send only once per exam
          if (!alertDoc.exists) {
            await alertRef.set({
              'examId': doc.id,
              'examTitle': data['title'] ?? '',
              'endDate': Timestamp.fromDate(endDate),
              'sentAt': FieldValue.serverTimestamp(),
            });

            final exam = ExamModel.fromFirestore(doc);
            await sendDeadlineApproachingNotification(exam);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in checkAndDispatchUpcomingDeadlines: $e');
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
    final type = message.data['type']?.toString() ?? 'new_exam';

    // Show native system notification in device tray
    showNativeNotification(
      title: title,
      body: body,
      examId: message.data['examId']?.toString(),
      type: type,
    );

    final context = navigatorKey.currentContext;
    if (context == null) return;

    Color bg;
    IconData icon;
    if (type == 'deadline_approaching') {
      bg = const Color(0xFFDC2626); // Alert red
      icon = Icons.alarm_rounded;
    } else if (type == 'deadline_changed') {
      bg = const Color(0xFFD97706); // Amber
      icon = Icons.edit_calendar_rounded;
    } else {
      bg = const Color(0xFF7C3AED); // Brand purple
      icon = Icons.notifications_active_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
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
          textColor: Colors.white,
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
