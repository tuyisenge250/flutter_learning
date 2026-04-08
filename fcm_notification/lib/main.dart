import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Must be a top-level function — called when app is in background/terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important FCM notifications.',
  importance: Importance.high,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (reads google-services.json automatically)
  await Firebase.initializeApp();

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Create the Android notification channel for foreground notifications
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(highImportanceChannel);

  // Prevent FCM from auto-displaying notifications while app is in foreground
  await FirebaseMessaging.instance
      .setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Notification',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FCMHomePage(),
    );
  }
}

class FCMHomePage extends StatefulWidget {
  const FCMHomePage({super.key});

  @override
  State<FCMHomePage> createState() => _FCMHomePageState();
}

class _FCMHomePageState extends State<FCMHomePage> {
  String _fcmToken = 'Fetching token...';
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    final messaging = FirebaseMessaging.instance;

    // 1. Request notification permission (required on Android 13+ and iOS)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission: ${settings.authorizationStatus}');

    // 2. Initialize flutter_local_notifications for foreground display
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    // 3. Get and display the FCM device token
    final token = await messaging.getToken();
    print('====== FCM TOKEN ======');
    print(token);
    print('=======================');
    setState(() {
      _fcmToken = token ?? 'Could not retrieve token';
    });

    // Refresh token automatically if it changes
    messaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      setState(() => _fcmToken = newToken);
    });

    // 4. Handle messages while app is in the FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      print('Foreground message: ${notification?.title} — ${notification?.body}');

      // Show it as a local notification banner
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              highImportanceChannel.id,
              highImportanceChannel.name,
              channelDescription: highImportanceChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }

      setState(() {
        _messages.insert(0,
            '[Foreground] ${notification?.title ?? 'No title'}: ${notification?.body ?? ''}');
      });
    });

    // 5. Handle notification tap when app was in the BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped (background): ${message.notification?.title}');
      setState(() {
        _messages.insert(0,
            '[Tapped] ${message.notification?.title ?? 'No title'}: ${message.notification?.body ?? ''}');
      });
    });

    // 6. Check if the app was launched from a terminated state via a notification
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App launched via notification: ${initialMessage.notification?.title}');
      setState(() {
        _messages.insert(0,
            '[Launch] ${initialMessage.notification?.title ?? 'No title'}: ${initialMessage.notification?.body ?? ''}');
      });
    }
  }

  void _copyToken() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_fcmToken, maxLines: 3, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('FCM Notification Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device FCM Token',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _fcmToken,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _copyToken,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Show Token'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Received Notifications',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _messages.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Text(
                        'Waiting for notifications...\n\n'
                        'Copy the token above and use it in Firebase Console:\n'
                        'Firebase → Cloud Messaging → New message → Send to device',
                        style: TextStyle(color: Colors.blueGrey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_messages[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
