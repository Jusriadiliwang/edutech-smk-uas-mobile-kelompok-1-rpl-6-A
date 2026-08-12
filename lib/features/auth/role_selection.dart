import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/services/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../student/student_dashboard_page.dart';
import '../teacher/teacher_dashboard_page.dart';
import '../wali_kelas/wali_dashboard_page.dart';
import '../bk/bk_dashboard_page.dart';
import '../piket/piket_dashboard_page.dart';
import '../admin/admin_dashboard_page.dart';

/// Routing berdasarkan role — dashboard dirender LANGSUNG (tidak di-push),
/// sehingga signOut() di mana pun langsung kembali ke LoginPage via AuthWrapper.
class RoleSelection extends StatefulWidget {
  const RoleSelection({super.key});
  @override
  State<RoleSelection> createState() => _RoleSelectionState();
}

class _RoleSelectionState extends State<RoleSelection> {
  Widget? _dashboard;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.users).doc(uid).get();

      if (!doc.exists) {
        if (mounted) setState(() => _errorMsg = 'Akun belum terdaftar di sistem. Hubungi admin sekolah.');
        return;
      }

      final role = doc.data()?[FirebaseConstants.fieldRole] as String?;
      if (role == null) {
        if (mounted) setState(() => _errorMsg = 'Role tidak ditemukan. Hubungi admin sekolah.');
        return;
      }

      await FCMService.subscribeByRole(role);
      if (!mounted) return;

      Widget dest;
      switch (role) {
        case AppRoles.siswa:     dest = const StudentDashboardPage();
        case AppRoles.guruMapel: dest = const TeacherDashboardPage();
        case AppRoles.waliKelas: dest = const WaliDashboardPage();
        case AppRoles.guruBK:    dest = const BKDashboardPage();
        case AppRoles.guruPiket: dest = const PiketDashboardPage();
        case AppRoles.admin:     dest = const AdminDashboardPage();
        default:
          setState(() => _errorMsg = 'Role tidak dikenal: $role');
          return;
      }

      setState(() => _dashboard = dest);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Gagal memuat akun: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error
    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppTheme.danger),
                    const SizedBox(height: 16),
                    const Text('Tidak Dapat Masuk',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(_errorMsg!, textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Dashboard sudah dimuat — render langsung (BUKAN push route)
    if (_dashboard != null) return _dashboard!;

    // Loading splash
    return const Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_rounded, size: 64, color: Colors.white),
            SizedBox(height: 20),
            Text('EduTech SMK',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
            SizedBox(height: 8),
            Text('Memuat akun Anda...',
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            SizedBox(height: 40),
            SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
          ],
        ),
      ),
    );
  }
}
