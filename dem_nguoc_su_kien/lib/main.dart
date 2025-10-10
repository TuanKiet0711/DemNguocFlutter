import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'language_controller.dart';
import 'i18n/app_localizations.dart';

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel kEventChannel = AndroidNotificationChannel(
  'su_kien_ding',
  'Sự kiện (có âm)',
  description: 'Kênh thông báo sự kiện kèm âm thanh ding',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('ding'),
);

Future<void> _initIntl() async {
  final sys = Intl.systemLocale.replaceAll('_', '-');
  Intl.defaultLocale = sys;
  await initializeDateFormatting(sys);
}

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
  final android = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (android != null) {
    await android.requestNotificationsPermission();
    await android.createNotificationChannel(kEventChannel);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _initFcm() async {
  final fcm = FirebaseMessaging.instance;
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await fcm.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onMessage.listen((msg) async {
    final n = msg.notification;
    if (n != null) {
      await flutterLocalNotificationsPlugin.show(
        msg.hashCode,
        n.title ?? 'Thông báo',
        n.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            kEventChannel.id,
            kEventChannel.name,
            channelDescription: kEventChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            sound: const RawResourceAndroidNotificationSound('ding'),
            enableVibration: true,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initIntl();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _initLocalNotifications();
  await _initFcm();
  await LanguageController.I.init();

  runApp(const DemNguocApp());
}

class DemNguocApp extends StatelessWidget {
  const DemNguocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageController.I,
      builder: (_, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Đếm ngược sự kiện',
          theme: ThemeData(primarySwatch: Colors.teal, brightness: Brightness.light),
          locale: LanguageController.I.locale,
          supportedLocales: const [Locale('vi'), Locale('en')],
          localizationsDelegates: const [
            AppLoc.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        return user == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}
