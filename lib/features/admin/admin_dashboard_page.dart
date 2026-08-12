import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../../firebase_options.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _tab = 0;
  Map<String, dynamic>? _userData;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.users).doc(_uid).get();
    if (mounted) setState(() => _userData = doc.data());
  }

  void _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Anda yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final name = _userData?['name'] ?? 'Admin';
    final pages = [
      _BerandaTab(name: name),
      const _PenggunaTab(),
      const _PengumumanTab(),
      const _LaporanTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('EduTech SMK'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined),    activeIcon: Icon(Icons.dashboard),    label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline),        activeIcon: Icon(Icons.people),       label: 'Pengguna'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined),     activeIcon: Icon(Icons.campaign),     label: 'Pengumuman'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined),    activeIcon: Icon(Icons.bar_chart),    label: 'Laporan'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 1 — BERANDA
// ═══════════════════════════════════════════════
class _BerandaTab extends StatelessWidget {
  final String name;
  const _BerandaTab({required this.name});

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang, $name!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(now, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Admin / Kepala Sekolah',
                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Statistik Pengguna ──
          const Text('Statistik Pengguna', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(FirebaseConstants.users).snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              int siswa = 0, guru = 0, wali = 0, bk = 0, piket = 0;
              for (final d in docs) {
                final role = (d.data() as Map)['role'] ?? '';
                if (role == AppRoles.siswa)      siswa++;
                else if (role == AppRoles.guruMapel)  guru++;
                else if (role == AppRoles.waliKelas)  wali++;
                else if (role == AppRoles.guruBK)     bk++;
                else if (role == AppRoles.guruPiket)  piket++;
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Siswa',   value: siswa,  color: AppTheme.colorSiswa,  icon: Icons.school_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Guru',    value: guru,   color: AppTheme.colorGuru,   icon: Icons.person_outline)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Wali',    value: wali,   color: AppTheme.colorWali,   icon: Icons.supervisor_account_outlined)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _StatCard(label: 'Guru BK',    value: bk,    color: AppTheme.colorBK,    icon: Icons.psychology_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Guru Piket', value: piket, color: AppTheme.colorPiket,  icon: Icons.security_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _StatCard(label: 'Total',      value: docs.length, color: AppTheme.colorAdmin, icon: Icons.people_outline)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Ringkasan Konten ──
          const Text('Ringkasan Konten', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ContentStat(label: 'Materi',     collection: FirebaseConstants.materials,     color: AppTheme.danger,   icon: Icons.book_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _ContentStat(label: 'Tugas',      collection: FirebaseConstants.assignments,   color: AppTheme.warning,  icon: Icons.assignment_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _ContentStat(label: 'Pengumuman', collection: FirebaseConstants.announcements, color: AppTheme.secondary, icon: Icons.campaign_outlined)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Pengguna Terbaru ──
          const Text('Pengguna Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.users)
                .orderBy('created_at', descending: true)
                .limit(5)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const AppCard(child: Center(
                  child: Text('Belum ada pengguna.', style: TextStyle(color: AppTheme.textMuted)),
                ));
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final role = data['role'] as String? ?? '';
                  final color = _roleColor(role);
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            (data['name'] as String? ?? '?').isNotEmpty
                                ? (data['name'] as String)[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(data['email'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        StatusBadge(label: _roleShortName(role), color: color),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 2 — PENGGUNA
// ═══════════════════════════════════════════════
class _PenggunaTab extends StatefulWidget {
  const _PenggunaTab();
  @override
  State<_PenggunaTab> createState() => _PenggunaTabState();
}

class _PenggunaTabState extends State<_PenggunaTab> {
  String _filterRole = 'SEMUA';
  final _searchCtrl = TextEditingController();
  String _searchText = '';

  static const _roles = ['SEMUA', 'SISWA', 'GURU_MAPEL', 'WALI_KELAS', 'GURU_BK', 'GURU_PIKET', 'ADMIN'];

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
        // Search & Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau email...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () { _searchCtrl.clear(); setState(() => _searchText = ''); })
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final r = _roles[i];
                    final selected = _filterRole == r;
                    return FilterChip(
                      label: Text(r == 'SEMUA' ? 'Semua' : _roleShortName(r),
                          style: TextStyle(fontSize: 11, color: selected ? Colors.white : AppTheme.textSecondary)),
                      selected: selected,
                      onSelected: (_) => setState(() => _filterRole = r),
                      selectedColor: AppTheme.accent,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // User List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.users)
                .orderBy('name')
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              var docs = snap.data!.docs;

              // Filter role
              if (_filterRole != 'SEMUA') {
                docs = docs.where((d) => (d.data() as Map)['role'] == _filterRole).toList();
              }
              // Filter search
              if (_searchText.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map;
                  return (data['name'] as String? ?? '').toLowerCase().contains(_searchText) ||
                         (data['email'] as String? ?? '').toLowerCase().contains(_searchText);
                }).toList();
              }

              if (docs.isEmpty) {
                return const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 56, color: AppTheme.textMuted),
                    SizedBox(height: 12),
                    Text('Tidak ada pengguna ditemukan.', style: TextStyle(color: AppTheme.textMuted)),
                  ]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final role = data['role'] as String? ?? '';
                  final color = _roleColor(role);
                  return AppCard(
                    onTap: () => _showUserDetail(context, docs[i].id, data),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: color.withOpacity(0.15),
                          child: Text(
                            (data['name'] as String? ?? '?').isNotEmpty
                                ? (data['name'] as String)[0].toUpperCase() : '?',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(data['email'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              if ((data['class'] as String?) != null && (data['class'] as String).isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Kelas: ${data['class']}',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StatusBadge(label: _roleShortName(role), color: color),
                            const SizedBox(height: 4),
                            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Tambah Pengguna', style: TextStyle(color: Colors.white)),
        onPressed: () => _showTambahPengguna(context),
      ),
    );
  }

  // ── Form Tambah Pengguna ──────────────────────
  void _showTambahPengguna(BuildContext ctx) {
    final formKey   = GlobalKey<FormState>();
    final nameCtrl  = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl  = TextEditingController();
    final kelasCtrl = TextEditingController();
    final nisnCtrl  = TextEditingController();
    String selectedRole = AppRoles.siswa;
    bool loading = false;
    bool obscure = true;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Tambah Pengguna Baru',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Akun akan dibuat & link atur password dikirim ke Gmail.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  const SizedBox(height: 20),

                  // Nama
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap *',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email Gmail
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Gmail *',
                      hintText: 'nama@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Password sementara
                  TextFormField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password Sementara *',
                      hintText: 'Min. 6 karakter',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                        onPressed: () => setSheet(() => obscure = !obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password wajib diisi';
                      if (v.length < 6) return 'Minimal 6 karakter';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Role
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Role *',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                    items: AppRoles.allRoles.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(AppRoles.displayName(r)),
                    )).toList(),
                    onChanged: (v) => setSheet(() => selectedRole = v ?? AppRoles.siswa),
                  ),
                  const SizedBox(height: 12),

                  // Kelas (hanya untuk Siswa & Wali Kelas)
                  if (selectedRole == AppRoles.siswa || selectedRole == AppRoles.waliKelas) ...[
                    TextFormField(
                      controller: kelasCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Kelas',
                        hintText: 'Contoh: XI RPL 1',
                        prefixIcon: Icon(Icons.class_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // NISN (hanya untuk Siswa)
                  if (selectedRole == AppRoles.siswa) ...[
                    TextFormField(
                      controller: nisnCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'NISN',
                        hintText: '10 digit angka',
                        prefixIcon: Icon(Icons.numbers, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Info email
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.mail_outline, size: 16, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Link atur password akan dikirim otomatis ke Gmail yang dimasukkan.',
                            style: TextStyle(fontSize: 12, color: AppTheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: loading
                          ? const SizedBox(width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.person_add),
                      label: Text(loading ? 'Membuat akun...' : 'Buat Akun & Kirim Email'),
                      onPressed: loading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheet(() => loading = true);
                        try {
                          await _createUser(
                            ctx: ctx,
                            name:  nameCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            password: passCtrl.text.trim(),
                            role:  selectedRole,
                            kelas: kelasCtrl.text.trim(),
                            nisn:  nisnCtrl.text.trim(),
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                        } catch (e) {
                          setSheet(() => loading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Gagal: $e'), backgroundColor: AppTheme.danger));
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Buat user via secondary Firebase App ──────
  Future<void> _createUser({
    required BuildContext ctx,
    required String name,
    required String email,
    required String password,
    required String role,
    required String kelas,
    required String nisn,
  }) async {
    // Buat secondary Firebase App agar admin tidak ikut logout
    FirebaseApp? secondaryApp;
    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondary_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // Buat akun di Firebase Auth
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      final uid = cred.user!.uid;

      // Simpan data ke Firestore
      await FirebaseFirestore.instance.collection(FirebaseConstants.users).doc(uid).set({
        'name':       name,
        'email':      email,
        'role':       role,
        'class':      kelas.isNotEmpty ? kelas : null,
        'nisn':       nisn.isNotEmpty  ? nisn  : null,
        'created_at': DateTime.now(),
      });

      // Kirim email reset password agar user bisa set password sendiri
      await secondaryAuth.sendPasswordResetEmail(email: email);

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Text('Akun "$name" berhasil dibuat. Email dikirim ke $email.'),
          backgroundColor: AppTheme.secondary,
          duration: const Duration(seconds: 4),
        ));
      }
    } finally {
      await secondaryApp?.delete();
    }
  }

  void _showUserDetail(BuildContext context, String docId, Map<String, dynamic> data) {
    final role = data['role'] as String? ?? '';
    final color = _roleColor(role);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30, backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      (data['name'] as String? ?? '?').isNotEmpty
                          ? (data['name'] as String)[0].toUpperCase() : '?',
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 4),
                        StatusBadge(label: AppRoles.displayName(role), color: color),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _DetailRow(icon: Icons.email_outlined,    label: 'Email',  value: data['email'] ?? '-'),
              if ((data['class'] as String?) != null)
                _DetailRow(icon: Icons.class_outlined,  label: 'Kelas',  value: data['class'] ?? '-'),
              if ((data['nisn'] as String?) != null)
                _DetailRow(icon: Icons.badge_outlined,  label: 'NISN',   value: data['nisn'] ?? '-'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(context, docId, data['name'] ?? '-');
                  },
                  icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                  label: const Text('Hapus Pengguna', style: TextStyle(color: AppTheme.danger)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.danger)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Hapus "$name" dari sistem? Data Firestore akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.users).doc(docId).delete();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$name" berhasil dihapus.')));
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 3 — PENGUMUMAN
// ═══════════════════════════════════════════════
class _PengumumanTab extends StatelessWidget {
  const _PengumumanTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.announcements)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textMuted),
                SizedBox(height: 12),
                Text('Belum ada pengumuman.', style: TextStyle(color: AppTheme.textMuted)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final ts = data['created_at'] as dynamic;
              String tanggal = '';
              try { tanggal = DateFormat('d MMM yyyy, HH:mm').format(ts.toDate()); } catch (_) {}
              return AppCard(
                onTap: () => _showDeleteDialog(context, docs[i].id, data['title'] ?? ''),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('PENGUMUMAN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                        ),
                        const Spacer(),
                        Text(tanggal, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        const SizedBox(width: 4),
                        const Icon(Icons.delete_outline, size: 16, color: AppTheme.textMuted),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(data['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(data['body'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Pengumuman', style: TextStyle(color: Colors.white)),
        onPressed: () => _showBuatPengumuman(context),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String docId, String title) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengumuman?'),
        content: Text('"$title"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.announcements).doc(docId).delete();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showBuatPengumuman(BuildContext context) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Buat Pengumuman Baru',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Judul *', hintText: 'Masukkan judul pengumuman'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Isi Pengumuman *', hintText: 'Tulis isi pengumuman di sini...'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Publikasikan'),
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection(FirebaseConstants.announcements)
                      .add({
                        'title': titleCtrl.text.trim(),
                        'body': bodyCtrl.text.trim(),
                        'created_at': DateTime.now(),
                      });
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  TAB 4 — LAPORAN
// ═══════════════════════════════════════════════
class _LaporanTab extends StatelessWidget {
  const _LaporanTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Laporan Absensi ──
          const Text('Rekap Absensi Sekolah', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(FirebaseConstants.absences).snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              final hadir = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.hadir).length;
              final alpha = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.alpha).length;
              final izin  = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.izin).length;
              final sakit = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.sakit).length;
              final total = docs.length;
              final persen = total > 0 ? (hadir / total * 100).toStringAsFixed(1) : '0.0';

              return AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _LaporanStat(label: 'Hadir', value: hadir, color: AppTheme.secondary),
                        _LaporanStat(label: 'Alpha', value: alpha, color: AppTheme.danger),
                        _LaporanStat(label: 'Izin',  value: izin,  color: AppTheme.warning),
                        _LaporanStat(label: 'Sakit', value: sakit, color: AppTheme.info),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tingkat Kehadiran Global', style: TextStyle(color: AppTheme.textSecondary)),
                        Text('$persen%',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Laporan Pelanggaran ──
          const Text('Pelanggaran Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.violations)
                .orderBy('created_at', descending: true)
                .limit(10)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return AppCard(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline, color: AppTheme.secondary),
                          SizedBox(width: 8),
                          Text('Tidak ada catatan pelanggaran.', style: TextStyle(color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final ts = data['created_at'] as dynamic;
                  String tanggal = '';
                  try { tanggal = DateFormat('d MMM yyyy').format(ts.toDate()); } catch (_) {}
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['description'] ?? '-',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(tanggal, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        Text('${data['points'] ?? 0} poin',
                            style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Konten Summary ──
          const Text('Total Konten', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _ContentStat(label: 'Materi',     collection: FirebaseConstants.materials,     color: AppTheme.danger,   icon: Icons.book_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _ContentStat(label: 'Tugas',      collection: FirebaseConstants.assignments,   color: AppTheme.warning,  icon: Icons.assignment_outlined)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ContentStat(label: 'Submisi',    collection: FirebaseConstants.submissions,   color: AppTheme.primary,  icon: Icons.upload_file_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _ContentStat(label: 'Konseling',  collection: FirebaseConstants.counseling,    color: AppTheme.colorBK,  icon: Icons.psychology_outlined)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  HELPER WIDGETS & FUNCTIONS
// ═══════════════════════════════════════════════
Color _roleColor(String role) {
  switch (role) {
    case AppRoles.siswa:     return AppTheme.colorSiswa;
    case AppRoles.guruMapel: return AppTheme.colorGuru;
    case AppRoles.waliKelas: return AppTheme.colorWali;
    case AppRoles.guruBK:    return AppTheme.colorBK;
    case AppRoles.guruPiket: return AppTheme.colorPiket;
    case AppRoles.admin:     return AppTheme.colorAdmin;
    default:                 return AppTheme.textMuted;
  }
}

String _roleShortName(String role) {
  switch (role) {
    case AppRoles.siswa:     return 'Siswa';
    case AppRoles.guruMapel: return 'Guru';
    case AppRoles.waliKelas: return 'Wali';
    case AppRoles.guruBK:    return 'BK';
    case AppRoles.guruPiket: return 'Piket';
    case AppRoles.admin:     return 'Admin';
    default:                 return role;
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ContentStat extends StatelessWidget {
  final String label, collection;
  final Color color;
  final IconData icon;
  const _ContentStat({required this.label, required this.collection, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
                  Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LaporanStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _LaporanStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
