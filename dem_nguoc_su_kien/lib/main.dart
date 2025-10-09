import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Local noti + TZ
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Quốc tế hoá
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// App của bạn
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

// (tuỳ chọn) FCM
import 'package:firebase_messaging/firebase_messaging.dart';

// ===================== Local Notifications =====================
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// 🔔 Kênh có âm thanh "ding" (res/raw/ding.mp3)
const AndroidNotificationChannel kEventChannel = AndroidNotificationChannel(
  'su_kien_ding',                     // id kênh
  'Sự kiện (có âm)',                  // tên hiển thị
  description: 'Kênh thông báo sự kiện kèm âm thanh ding',
  importance: Importance.high,
  playSound: true,
  sound: RawResourceAndroidNotificationSound('ding'),
);

Future<void> _initIntl() async {
  final sys = Intl.systemLocale.replaceAll('_', '-'); // ví dụ "vi-VN"
  Intl.defaultLocale = sys;
  await initializeDateFormatting(sys);
}

Future<void> _initLocalNotifications() async {
  // Khởi tạo plugin
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (resp) {
      // Xử lý khi user bấm thông báo (nếu cần)
      // debugPrint('Tapped notification: ${resp.payload}');
    },
  );

  // Timezone
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

  // Tạo channel & xin quyền Android 13+
  final android = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (android != null) {
    await android.requestNotificationsPermission();
    await android.createNotificationChannel(kEventChannel);
  }
}

/// 👉 Bắn noti NGAY lập tức có âm thanh
Future<void> showNow({
  required String title,
  String? body,
}) async {
  await flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
    title,
    body,
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

/// 👉 Đặt lịch noti có âm thanh (dùng cho nhắc hẹn)
Future<void> scheduleAt({
  required String title,
  String? body,
  required DateTime at,
}) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    DateTime.now().millisecondsSinceEpoch & 0x7fffffff,
    title,
    body,
    tz.TZDateTime.from(at, tz.local),
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
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}

// ===================== (Tuỳ chọn) FCM =====================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Android background sẽ tự hiển thị nếu payload có "notification".
}

Future<void> _initFcm() async {
  final fcm = FirebaseMessaging.instance;

  // Đăng ký handler nền
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Quyền (Android auto-true; iOS/macOS cần popup)
  await fcm.requestPermission(alert: true, badge: true, sound: true);

  // Foreground: hiển thị bằng local-noti để đảm bảo có tiếng "ding"
  FirebaseMessaging.onMessage.listen((msg) async {
    final n = msg.notification;
    final android = n?.android;
    if (n != null && android != null) {
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

  // Khi user bấm thông báo mở app
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    // Điều hướng nếu cần
  });
}

// ===================== App =====================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initIntl();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await _initLocalNotifications(); // kênh + quyền + TZ
  await _initFcm();                // nếu bạn dùng FCM

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
      supportedLocales: const [Locale('vi'), Locale('en')],
      home: const AuthGate(),
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
