import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      // AuthWrapper akan otomatis redirect setelah login berhasil
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'user-not-found'    => 'Akun tidak ditemukan. Periksa email Anda.',
          'wrong-password'    => 'Password salah. Coba lagi.',
          'invalid-credential'=> 'Email atau password salah.',
          'invalid-email'     => 'Format email tidak valid.',
          'user-disabled'     => 'Akun Anda telah dinonaktifkan.',
          'too-many-requests' => 'Terlalu banyak percobaan. Tunggu sebentar.',
          'network-request-failed' => 'Tidak ada koneksi internet. Periksa jaringan.',
          _                   => 'Error [${e.code}]: ${e.message}',
        };
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Masukkan email terlebih dahulu untuk reset password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email reset password telah dikirim.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Gagal mengirim email reset password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // ── Logo & Title ──
                    Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.school_rounded,
                              size: 38, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'EduTech SMK',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Learning Management System',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // ── Form Card ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Masuk ke Akun Anda',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Gunakan email dan password yang diberikan sekolah.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMuted,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'nama@sekolah.ac.id',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                              if (!v.contains('@')) return 'Format email tidak valid';
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined
                                           : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                              if (v.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),

                          // Error message
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.danger.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 16, color: AppTheme.danger),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.danger,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _forgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                              ),
                              child: const Text('Lupa password?',
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Login Button
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text('Masuk',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Info ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16,
                              color: AppTheme.textMuted),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Akun dibuat oleh admin sekolah. Hubungi TU jika belum memiliki akun.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Daftar akun siswa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Siswa baru? ',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterPage())),
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: const Text('Daftar di sini',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
