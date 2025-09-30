import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/course.dart';

/// Service for handling local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  static Future<void> initialize() async {
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestIOSPermissions();
    }
  }

  /// Request permissions for iOS notifications
  static Future<void> _requestIOSPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Schedule a notification for class reminder
  static Future<void> scheduleClassReminder(
    Course course,
    DateTime reminderTime,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'class_reminders',
            'Class Reminders',
            channelDescription: 'Notifications for upcoming classes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.zonedSchedule(
        course.id.hashCode, // Use course ID hash as notification ID
        'Upcoming Class',
        '${course.name} starts in 15 minutes at ${course.location}',
        _convertToTZDateTime(reminderTime),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'class_reminder:${course.id}',
      );
    } catch (e) {
      debugPrint('Failed to schedule class reminder: $e');
    }
  }

  /// Schedule notification for assignment due date
  static Future<void> scheduleAssignmentReminder(
    String assignmentId,
    String assignmentTitle,
    String courseName,
    DateTime dueDate,
  ) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'assignment_reminders',
            'Assignment Reminders',
            channelDescription: 'Notifications for assignment due dates',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule 24 hours before due date
      final reminderTime = dueDate.subtract(const Duration(hours: 24));

      if (reminderTime.isAfter(DateTime.now())) {
        await _notifications.zonedSchedule(
          assignmentId.hashCode,
          'Assignment Due Soon',
          '$assignmentTitle for $courseName is due tomorrow',
          _convertToTZDateTime(reminderTime),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'assignment_reminder:$assignmentId',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule assignment reminder: $e');
    }
  }

  /// Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'general',
            'General Notifications',
            channelDescription: 'General app notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Setup recurring weekly class reminders
  static Future<void> setupWeeklyClassReminders(List<Course> courses) async {
    // Cancel existing class reminders
    final pending = await getPendingNotifications();
    for (final notification in pending) {
      if (notification.payload?.startsWith('class_reminder:') == true) {
        await cancelNotification(notification.id);
      }
    }

    // Schedule new reminders for each course
    for (final course in courses) {
      await _scheduleWeeklyReminder(course);
    }
  }

  /// Schedule weekly reminder for a specific course
  static Future<void> _scheduleWeeklyReminder(Course course) async {
    try {
      // Calculate next occurrence of this class
      final now = DateTime.now();
      final nextClass = _getNextClassTime(course, now);

      if (nextClass != null) {
        // Schedule reminder 15 minutes before class
        final reminderTime = nextClass.subtract(const Duration(minutes: 15));

        if (reminderTime.isAfter(now)) {
          await scheduleClassReminder(course, reminderTime);
        }
      }
    } catch (e) {
      debugPrint('Failed to schedule weekly reminder for ${course.name}: $e');
    }
  }

  /// Get next class time for a course (simplified - assumes weekly recurring)
  static DateTime? _getNextClassTime(Course course, DateTime from) {
    // This is a simplified implementation
    // In a real app, you'd parse the course schedule properly

    // For now, assume classes are weekly at the same time
    // You'd need to implement proper schedule parsing based on your Course model

    return null; // TODO: Implement proper schedule calculation
  }

  /// Convert DateTime to TZDateTime (simplified for local timezone)
  static dynamic _convertToTZDateTime(DateTime dateTime) {
    // This is a placeholder - in a real app you'd use the timezone package
    // For now, return the DateTime as-is since flutter_local_notifications
    // can handle DateTime in some cases
    return dateTime;
  }

  /// Show sync completion notification
  static Future<void> showSyncCompletedNotification(int itemsSynced) async {
    if (itemsSynced > 0) {
      await showNotification(
        id: 999,
        title: 'Sync Complete',
        body: 'Synced $itemsSynced items to cloud',
        payload: 'sync_complete',
      );
    }
  }

  /// Show offline mode notification
  static Future<void> showOfflineModeNotification() async {
    await showNotification(
      id: 998,
      title: 'Offline Mode',
      body: 'You\'re offline. Changes will sync when connection is restored.',
      payload: 'offline_mode',
    );
  }
}

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
