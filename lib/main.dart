import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'features/auth/login_page.dart';
import 'features/auth/role_selection.dart';

// Set true saat menggunakan Firebase Emulator (lokal)
// Set false saat menggunakan Firebase production
const bool useEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // init locale Indonesia

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Gunakan Firebase Emulator jika useEmulator = true
  if (useEmulator) {
    const host = 'localhost';
    try {
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      debugPrint('✅ Firebase Emulator aktif');
    } catch (e) {
      debugPrint('⚠️ Emulator tidak tersedia, pakai Firebase production: $e');
    }
  }

  // Inisialisasi FCM (skip di emulator/web)
  if (!kIsWeb && !useEmulator) {
    await FCMService.initialize();
  }

  runApp(const EduTechApp());
}

class EduTechApp extends StatelessWidget {
  const EduTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduTech SMK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper utama — mendengarkan status autentikasi Firebase
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const RoleSelection();
        }
        return const LoginPage();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2563EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'EduTech SMK',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Learning Management System',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
