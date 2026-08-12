import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';
import '../shared/notification_list_page.dart';
import 'quick_scan_page.dart';

class PiketDashboardPage extends StatefulWidget {
  const PiketDashboardPage({super.key});
  @override
  State<PiketDashboardPage> createState() => _PiketDashboardPageState();
}

class _PiketDashboardPageState extends State<PiketDashboardPage> {
  int _tab = 0;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _PiketHomeTab(uid: _uid),
      QuickScanPage(piketId: _uid),
      _BukuPiketTab(uid: _uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Piket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationListPage())),
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
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner),  activeIcon: Icon(Icons.qr_code_scanner), label: 'Scan QR'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined),    activeIcon: Icon(Icons.book),    label: 'Buku Piket'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───
class _PiketHomeTab extends StatelessWidget {
  final String uid;
  const _PiketHomeTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard Guru Piket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 12),
                const Text('Piket Hari Ini', style: TextStyle(fontSize: 11, color: Colors.white60)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ringkasan hari ini
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection(FirebaseConstants.absences)
                .get(), // NO where - filter client-side
            builder: (_, snap) {
              final docs = (snap.data?.docs ?? [])
                  .where((d) => (d.data() as Map)['date_str'] == today).toList();
              final hadir     = docs.where((d) => (d.data() as Map)['status'] == 'HADIR').length;
              final terlambat = docs.where((d) => (d.data() as Map)['late'] == true).length;
              final alpha     = docs.where((d) => (d.data() as Map)['status'] == 'ALPHA').length;

              return Row(
                children: [
                  Expanded(child: _PiketStatCard('Hadir', hadir, AppTheme.secondary)),
                  const SizedBox(width: 10),
                  Expanded(child: _PiketStatCard('Terlambat', terlambat, AppTheme.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _PiketStatCard('Tidak Hadir', alpha, AppTheme.danger)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Aksi Cepat
          const Text('Aksi Cepat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _ActionCard(
                icon: Icons.qr_code_scanner,
                label: 'Scan QR\nSiswa',
                color: AppTheme.secondary,
                onTap: () {
                  // Navigate to Scan QR tab (index 1)
                  final state = context.findAncestorStateOfType<_PiketDashboardPageState>();
                  state?.setState(() => state._tab = 1);
                },
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.campaign_outlined,
                label: 'Broadcast\nDarurat',
                color: AppTheme.danger,
                onTap: () => _broadcastUrgency(context),
              )),
              const SizedBox(width: 10),
              Expanded(child: _ActionCard(
                icon: Icons.edit_note_outlined,
                label: 'Catat\nKejadian',
                color: AppTheme.primary,
                onTap: () => _addPiketLog(context, uid),
              )),
            ],
          ),
          const SizedBox(height: 20),

          // Log terbaru
          const Text('Log Piket Hari Ini', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection(FirebaseConstants.piketLog)
                .get(), // NO where - filter client-side
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final docs = snap.data!.docs
                  .where((d) => (d.data() as Map)['date_str'] == today).toList()
                ..sort((a, b) => (((b.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
                    .compareTo(((a.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
              if (docs.isEmpty) {
                return const AppCard(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('Belum ada catatan piket hari ini.',
                      style: TextStyle(color: AppTheme.textMuted))),
                ));
              }
              return Column(children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final type  = data['type'] as String? ?? '';
                final color = switch (type) {
                  'TERLAMBAT' => AppTheme.warning,
                  'IZIN_PULANG' => AppTheme.info,
                  'KEJADIAN' => AppTheme.danger,
                  _ => AppTheme.textMuted,
                };
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['student_name'] ?? 'Siswa',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(data['note'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      StatusBadge(label: type, color: color),
                    ],
                  ),
                );
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  void _broadcastUrgency(BuildContext ctx) {
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.campaign_outlined, color: AppTheme.danger),
            const SizedBox(width: 8),
            const Text('Broadcast Darurat', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pesan ini akan dikirim ke seluruh pengguna sekolah via FCM.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Pengumuman', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: bodyCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Isi Pesan', border: OutlineInputBorder(),
                    alignLabelWithHint: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Kirim Sekarang'),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.notifications)
                  .add({
                'title':      titleCtrl.text.trim(),
                'body':       bodyCtrl.text.trim(),
                'type':       'DARURAT',
                'topic':      FirebaseConstants.topicAllUsers,
                'sent_by':    uid,
                'created_at': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Broadcast darurat terkirim ke seluruh sekolah!'),
                    backgroundColor: AppTheme.danger,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _addPiketLog(BuildContext ctx, String uid) {
    final nameCtrl  = TextEditingController();
    final noteCtrl  = TextEditingController();
    String type     = 'TERLAMBAT';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx2, setSt) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Catat Kejadian Piket', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Tipe Kejadian'),
              items: const [
                DropdownMenuItem(value: 'TERLAMBAT', child: Text('Keterlambatan')),
                DropdownMenuItem(value: 'IZIN_PULANG', child: Text('Izin Pulang')),
                DropdownMenuItem(value: 'KEJADIAN', child: Text('Kejadian Khusus')),
              ],
              onChanged: (v) => setSt(() => type = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Siswa')),
            const SizedBox(height: 10),
            TextField(controller: noteCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Keterangan', alignLabelWithHint: true)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await FirebaseFirestore.instance
                      .collection(FirebaseConstants.piketLog)
                      .add({
                    'type':         type,
                    'student_name': nameCtrl.text.trim(),
                    'note':         noteCtrl.text.trim(),
                    'date_str':     today,
                    'recorded_by':  uid,
                    'created_at':   FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Kejadian dicatat!'), backgroundColor: AppTheme.secondary));
                  }
                },
                child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ─── BUKU PIKET TAB ───
class _BukuPiketTab extends StatelessWidget {
  final String uid;
  const _BukuPiketTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.piketLog)
          .orderBy('created_at', descending: true)
          .limit(50)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final type  = data['type'] as String? ?? '';
            final date  = (data['created_at'] as Timestamp?)?.toDate();
            final color = switch (type) {
              'TERLAMBAT'   => AppTheme.warning,
              'IZIN_PULANG' => AppTheme.info,
              'KEJADIAN'    => AppTheme.danger,
              _             => AppTheme.textMuted,
            };
            return AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      switch (type) {
                        'TERLAMBAT'   => Icons.access_time,
                        'IZIN_PULANG' => Icons.exit_to_app,
                        _             => Icons.report_problem_outlined,
                      },
                      color: color, size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['student_name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(data['note'] ?? '',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (date != null)
                          Text(DateFormat('d MMM yyyy, HH:mm').format(date),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  StatusBadge(label: type.replaceAll('_', ' '), color: color),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── HELPERS ───
class _PiketStatCard extends StatelessWidget {
  final String label; final int value; final Color color;
  const _PiketStatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), textAlign: TextAlign.center),
    ]),
  );
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext ctx) => InkWell(
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
        Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}
