import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _nisnCtrl  = TextEditingController();
  final _kelasCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _nisnCtrl.dispose();
    _kelasCtrl.dispose(); _passCtrl.dispose(); _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      // Buat akun Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Simpan data ke Firestore
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .doc(cred.user!.uid)
          .set({
        'name':       _nameCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'role':       AppRoles.siswa,
        'class':      _kelasCtrl.text.trim().isNotEmpty ? _kelasCtrl.text.trim() : null,
        'nisn':       _nisnCtrl.text.trim().isNotEmpty  ? _nisnCtrl.text.trim()  : null,
        'created_at': DateTime.now(),
      });

      // Kirim email verifikasi
      await cred.user!.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registrasi berhasil! Cek email untuk verifikasi.'),
          backgroundColor: AppTheme.secondary,
          duration: Duration(seconds: 4),
        ));
        // Logout agar user login ulang setelah verifikasi
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'email-already-in-use' => 'Email sudah terdaftar. Gunakan email lain.',
          'invalid-email'        => 'Format email tidak valid.',
          'weak-password'        => 'Password terlalu lemah. Minimal 6 karakter.',
          _                      => 'Registrasi gagal: ${e.message}',
        };
      });
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Akun Siswa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF6366F1)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daftar Akun Siswa',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                            Text('EduTech SMK — LMS',
                                style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Form
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16, offset: const Offset(0, 4),
                        )],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nama
                          TextFormField(
                            controller: _nameCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap *',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nama wajib diisi' : null,
                          ),
                          const SizedBox(height: 14),

                          // Email
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              hintText: 'nama@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                              if (!v.contains('@')) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // NISN
                          TextFormField(
                            controller: _nisnCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'NISN',
                              hintText: '10 digit nomor induk siswa',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                            validator: (v) {
                              if (v != null && v.isNotEmpty && v.length != 10)
                                return 'NISN harus 10 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Kelas
                          TextFormField(
                            controller: _kelasCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Kelas',
                              hintText: 'Contoh: XI RPL 1',
                              prefixIcon: Icon(Icons.class_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              labelText: 'Password *',
                              hintText: 'Min. 6 karakter',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure1 ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password wajib diisi';
                              if (v.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Konfirmasi Password
                          TextFormField(
                            controller: _pass2Ctrl,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              labelText: 'Konfirmasi Password *',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure2 ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined, size: 20),
                                onPressed: () => setState(() => _obscure2 = !_obscure2),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
                              if (v != _passCtrl.text) return 'Password tidak cocok';
                              return null;
                            },
                          ),

                          // Error
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, size: 16, color: AppTheme.danger),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.danger,
                                        fontWeight: FontWeight.w500))),
                              ]),
                            ),
                          ],
                          const SizedBox(height: 20),

                          // Submit
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                                  : const Text('Daftar Sekarang',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Setelah mendaftar, link verifikasi akan dikirim ke email Anda. '
                          'Verifikasi email sebelum login.',
                          style: TextStyle(fontSize: 12, color: AppTheme.primary, height: 1.4),
                        )),
                      ]),
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
