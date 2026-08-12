import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../shared/chat_room_page.dart';
import '../shared/notification_list_page.dart';
import 'alert_system_widget.dart';

class WaliDashboardPage extends StatefulWidget {
  const WaliDashboardPage({super.key});
  @override
  State<WaliDashboardPage> createState() => _WaliDashboardPageState();
}

class _WaliDashboardPageState extends State<WaliDashboardPage> {
  int _tab = 0;
  Map<String, dynamic>? _userData;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() { super.initState(); _loadUser(); }

  Future<void> _loadUser() async {
    final doc = await FirebaseFirestore.instance
        .collection(FirebaseConstants.users).doc(_uid).get();
    if (mounted) setState(() => _userData = doc.data());
  }

  @override
  Widget build(BuildContext context) {
    final kelas = _userData?['class'] ?? '';

    final pages = [
      _WaliHomeTab(uid: _uid, kelas: kelas),
      _AkademikTab(kelas: kelas),
      _AbsensiTab(kelas: kelas),
      _PelanggaranTab(kelas: kelas),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationListPage())),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          }),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),    activeIcon: Icon(Icons.home),    label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined),   activeIcon: Icon(Icons.school),  label: 'Akademik'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Absensi'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_outlined),  activeIcon: Icon(Icons.warning), label: 'Pelanggaran'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───
class _WaliHomeTab extends StatelessWidget {
  final String uid, kelas;
  const _WaliHomeTab({required this.uid, required this.kelas});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard Wali Kelas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Kelas Perwalian: $kelas', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(DateFormat('d MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Alert System
          AlertSystemWidget(kelas: kelas),

          const SizedBox(height: 20),
          const Text('Menu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _WaliMenuCard(
                icon: Icons.chat_outlined, label: 'Buku\nPenghubung',
                color: AppTheme.primary,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ChatRoomPage(chatId: 'wali_$kelas', title: 'Buku Penghubung'))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _WaliMenuCard(
                icon: Icons.picture_as_pdf_outlined, label: 'Export\nRapor PDF',
                color: AppTheme.danger,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur export PDF dalam pengembangan.'))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _WaliMenuCard(
                icon: Icons.notifications_active_outlined, label: 'Kirim\nNotifikasi',
                color: AppTheme.secondary,
                onTap: () => _sendNotif(context, kelas),
              )),
            ],
          ),

          const SizedBox(height: 20),
          const Text('Siswa Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.users)
                .where('class', isEqualTo: kelas)
                .where('role', isEqualTo: 'SISWA')
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final students = snap.data!.docs;
              return Column(
                children: students.map((s) {
                  final data = s.data() as Map<String, dynamic>;
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.warning.withOpacity(0.15),
                          child: Text(
                            (data['name'] as String? ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('NISN: ${data['nisn'] ?? '-'}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendNotif(BuildContext ctx, String kelas) {
    final msgCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Kirim Notifikasi ke Orang Tua'),
        content: TextField(controller: msgCtrl, maxLines: 3,
            decoration: const InputDecoration(hintText: 'Tulis pesan...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.notifications)
                  .add({
                'title': 'Pesan dari Wali Kelas',
                'body':  msgCtrl.text.trim(),
                'class': kelas,
                'type':  'wali',
                'created_at': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Notifikasi terkirim!'), backgroundColor: AppTheme.secondary));
              }
            },
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}

// ─── AKADEMIK TAB ───
class _AkademikTab extends StatelessWidget {
  final String kelas;
  const _AkademikTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    // Ambil dulu siswa yang ada di kelas ini, lalu tampilkan nilai mereka
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('class', isEqualTo: kelas)
          .where('role', isEqualTo: 'SISWA')
          .snapshots(),
      builder: (_, usersSnap) {
        if (!usersSnap.hasData) return const Center(child: CircularProgressIndicator());
        final students = usersSnap.data!.docs;
        if (students.isEmpty) {
          return const Center(child: Text('Belum ada siswa di kelas ini.', style: TextStyle(color: AppTheme.textMuted)));
        }
        final studentIds = students.map((s) => s.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('submissions')
              .where('student_id', whereIn: studentIds.take(10).toList())
              .where('status', isEqualTo: 'GRADED')
              .orderBy('graded_at', descending: true)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            final grades = docs.map((d) => (d.data() as Map)['grade'] as num? ?? 0).toList();
            final avg = grades.isEmpty ? 0.0 : grades.fold<num>(0, (a, b) => a + b) / grades.length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.school, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Kelas $kelas', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                      Text('Rata-rata dari ${docs.length} penilaian',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 10),
                if (docs.isEmpty)
                  const AppCard(child: Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Belum ada nilai siswa.', style: TextStyle(color: AppTheme.textMuted)))))
                else
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final grade = data['grade'] as num? ?? 0;
                    final color = grade >= 75 ? AppTheme.secondary : AppTheme.danger;
                    return AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        const Icon(Icons.assignment_turned_in_outlined, color: AppTheme.secondary),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users').doc(data['student_id']).get(),
                            builder: (_, s) => Text(
                              (s.data?.data() as Map?)?['name'] ?? 'Siswa',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('assignments').doc(data['assignment_id']).get(),
                            builder: (_, a) => Text(
                              (a.data?.data() as Map?)?['title'] ?? 'Tugas',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          ),
                        ])),
                        StatusBadge(label: '$grade', color: color),
                      ]),
                    );
                  }),
              ],
            );
          },
        );
      },
    );
  }
}

// ─── ABSENSI TAB ───
class _AbsensiTab extends StatelessWidget {
  final String kelas;
  const _AbsensiTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absences)
          .where('class', isEqualTo: kelas)
          .orderBy('date', descending: true)
          .limit(100)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        final alpha = docs.where((d) => (d.data() as Map)['status'] == 'ALPHA').length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _AbsStatCard('Total\nCatatan', docs.length, AppTheme.primary)),
                  const SizedBox(width: 10),
                  Expanded(child: _AbsStatCard('Hadir',  docs.where((d) => (d.data() as Map)['status'] == 'HADIR').length, AppTheme.secondary)),
                  const SizedBox(width: 10),
                  Expanded(child: _AbsStatCard('Alpha', alpha, AppTheme.danger)),
                  const SizedBox(width: 10),
                  Expanded(child: _AbsStatCard('Izin/Sakit', docs.where((d) => ['IZIN','SAKIT'].contains((d.data() as Map)['status'])).length, AppTheme.warning)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? '';
                  final date   = (data['date'] as Timestamp?)?.toDate();
                  final color  = {'HADIR': AppTheme.secondary, 'ALPHA': AppTheme.danger,
                      'IZIN': AppTheme.warning, 'SAKIT': AppTheme.info}[status] ?? AppTheme.textMuted;
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection(FirebaseConstants.users)
                              .doc(data['student_id']).get(),
                          builder: (_, s) => Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.data?.get('name') ?? 'Siswa',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              if (date != null)
                                Text(DateFormat('d MMM yyyy').format(date),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          )),
                        ),
                        StatusBadge(label: status, color: color),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── PELANGGARAN TAB ───
class _PelanggaranTab extends StatelessWidget {
  final String kelas;
  const _PelanggaranTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.violations)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text('${data['points']}',
                            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.danger, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection(FirebaseConstants.users)
                                .doc(data['student_id']).get(),
                            builder: (_, s) => Text(s.data?.get('name') ?? 'Siswa',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Text(data['description'] ?? '',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (date != null)
                            Text(DateFormat('d MMM yyyy').format(date),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    StatusBadge(label: '${data['points']} poin', color: AppTheme.danger),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addViolation(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pelanggaran'),
        backgroundColor: AppTheme.danger,
      ),
    );
  }

  void _addViolation(BuildContext ctx) {
    final studentCtrl = TextEditingController();
    final descCtrl    = TextEditingController();
    final pointsCtrl  = TextEditingController(text: '5');

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catat Pelanggaran', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(controller: studentCtrl, decoration: const InputDecoration(labelText: 'ID/UID Siswa')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi Pelanggaran')),
            const SizedBox(height: 10),
            TextField(controller: pointsCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Poin Pelanggaran')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection(FirebaseConstants.violations)
                      .add({
                    'student_id':  studentCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'points':      int.tryParse(pointsCtrl.text) ?? 5,
                    'date':        FieldValue.serverTimestamp(),
                    'reported_by': FirebaseAuth.instance.currentUser?.uid,
                    'class':       kelas,
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Pelanggaran dicatat!'), backgroundColor: AppTheme.secondary));
                  }
                },
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HELPERS ───
class _WaliMenuCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _WaliMenuCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap, borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _AbsStatCard extends StatelessWidget {
  final String label; final int value; final Color color;
  const _AbsStatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
    ]),
  );
}
