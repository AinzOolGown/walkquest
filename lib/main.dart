import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'firebase_options.dart';
import 'auth/auth_wrapper.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tz.initializeTimeZones();

  await NotificationService.init();
  await NotificationService.requestPermission();

  try {
    await NotificationService.scheduleRepeatingReminder();
  } catch (e) {
    debugPrint("Notification scheduling failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color adventureBlue = Color(0xFF1565C0);
  static const Color gold = Color(0xFFFFB300);
  static const Color dangerRed = Color(0xFFC62828);
  static const Color background = Color(0xFFF4F7F2);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WalkQuest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: adventureBlue,
          tertiary: gold,
          error: dangerRed,
          background: background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shadowColor: Colors.black26,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD8E4D4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFD8E4D4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 2,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}