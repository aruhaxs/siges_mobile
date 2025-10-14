import 'dart:async';
import 'dart:convert';
import 'package:apk_sukorame/src/admin/screens/event_list_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:apk_sukorame/src/admin/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:apk_sukorame/firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:apk_sukorame/src/auth/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'src/admin/config/supabase_config.dart';
import 'src/services/theme_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Menangani notifikasi background: ${message.messageId}");
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifikasi Penting',
  description: 'Channel ini digunakan untuk notifikasi prioritas tinggi.',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await initializeDateFormatting('id_ID', null);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        final Map<String, dynamic> messageMap =
            jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationClick(messageMap['data']);
      }
    },
  );

  await _setupFCM();

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeManager(),
      child: const MyApp(),
    ),
  );
}


void _handleNotificationClick(Map<String, dynamic> data) {
  debugPrint("Data payload diterima: $data");
  if (data['eventType'] == 'jadwal_kegiatan') {
    final event = Event.fromFcmPayload(data);

    final DatabaseReference eventsRef = FirebaseDatabase.instance.ref("events");
    eventsRef.push().set(event.toJson()).then((_) {
      debugPrint("Event berhasil disimpan ke database.");
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const EventListScreen(),
        ),
      );
    }).catchError((error) {
      debugPrint("Gagal menyimpan event: $error");
    });
  }
}

Future<void> _setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  final String? fcmToken = await messaging.getToken();
  debugPrint("FCM Token: $fcmToken");

  await FirebaseMessaging.instance.subscribeToTopic('DESU');
  debugPrint("Berhasil subscribe ke topic DESU");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
              android: AndroidNotificationDetails(channel.id, channel.name,
                  channelDescription: channel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high)),
          payload: jsonEncode(message.toMap()));
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleNotificationClick(message.data);
  });

  messaging.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      _handleNotificationClick(message.data);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'DeSu',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.teal,
            brightness: Brightness.light,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.teal,
            brightness: Brightness.dark,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          themeMode: themeManager.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}