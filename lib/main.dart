import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'screens/LoadingScreen1.dart';
import 'screens/SecretaryEmergencyDetail.dart'; // We will create this
import 'screens/DriverEmergencyList.dart'; // We will create this
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔹 Background handler (must be top-level)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print("Handling background message: ${message.messageId}");
}

/// 🔹 Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔹 Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🔹 Request permission (Android 13+ & iOS)
    await messaging.requestPermission();

    // 🔹 Get device token
    String? token = await messaging.getToken();
    print("FCM Token: $token");

    /// 🔹 Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        print("Notification tapped with payload: ${response.payload}");
        if (response.payload != null &&
            response.payload!.startsWith("EMERGENCY|")) {
          final parts = response.payload!.split("|");
          if (parts.length >= 2) {
            final emergencyId = parts[1];
            _handleEmergencyNavigation(emergencyId);
          }
        }
      },
    );

    /// 🔹 Foreground listener (SHOW POPUP)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received");

      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'bus_channel',
              'Bus Notifications',
              channelDescription: 'Bus app notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    /// 🔹 When user taps notification (app in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification opened from background");
      // Could also handle data payload here if sent via FCM directly
    });
  }

  void _handleEmergencyNavigation(String emergencyId) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    if (role == 'Bus Secretary') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => SecretaryEmergencyDetail(emergencyId: emergencyId),
        ),
      );
    } else if (role == 'Driver' || role == 'Bus Attendant') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const DriverEmergencyList()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: LoadingScreen1(),
    );
  }
}
