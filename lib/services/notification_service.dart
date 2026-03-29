import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:bus_tracker/main.dart'; // To access flutterLocalNotificationsPlugin & navigatorKey

class NotificationService {
  static StreamSubscription? _subscription;
  static bool _isFirstLoad = true;

  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String message,
    required String busId,
    required String busName,
    String? payload,
  }) async {
    await FirebaseFirestore.instance.collection('Notifications').add({
      'title': title,
      'message': message,
      'toUserId': toUserId,
      'busId': busId,
      'busName': busName,
      'type': 'BUS_STATUS',
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  static void startListening(String userId) {
    _isFirstLoad = true;
    _subscription?.cancel();

    _subscription = FirebaseFirestore.instance
        .collection('Notifications')
        .where('toUserId', isEqualTo: userId)
        // .orderBy and .limit removed because they require a composite index that is not present.
        .snapshots()
        .listen((snapshot) {
          if (_isFirstLoad) {
            _isFirstLoad = false;
            return; // Ignore existing notifications on app load
          }

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'New Notification';
              final message = data['message'] ?? '';
              final payload = data['payload'];

              _showLocalNotification(title, message, payload);
            }
          }
        });
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<void> _showLocalNotification(
    String title,
    String body, [
    String? payload,
  ]) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'bus_channel',
          'Bus Notifications',
          channelDescription: 'Bus app notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // unique ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}
