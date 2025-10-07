// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // <-- Tạo màn hình đăng nhập/đăng ký

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _initIntl() async {
  final sys = Intl.systemLocale.replaceAll('_', '-'); // ví dụ "vi-VN"
  Intl.defaultLocale = sys;
  await initializeDateFormatting(sys);
}

Future<void> _initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // Timezone VN
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initIntl();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ❌ Không auto sign-in ẩn danh ở đây nữa.
  // Nếu muốn cho dùng thử ẩn danh, làm nút "Dùng thử" ở LoginScreen và gọi:
  // FirebaseAuth.instance.signInAnonymously();

  await _initNotifications();

  // Android 13+ xin quyền thông báo
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const DemNguocApp());
}

class DemNguocApp extends StatelessWidget {
  const DemNguocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đếm ngược sự kiện',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi'),
        Locale('en'),
      ],
      home: const AuthGate(),
    );
  }
}

/// Cổng xác thực: điều hướng giữa LoginScreen và HomeScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        return user == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}
