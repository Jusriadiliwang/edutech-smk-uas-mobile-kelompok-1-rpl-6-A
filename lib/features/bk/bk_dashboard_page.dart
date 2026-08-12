import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../shared/chat_room_page.dart';
import '../shared/notification_list_page.dart';
import 'case_tracking_page.dart';

class BKDashboardPage extends StatefulWidget {
  const BKDashboardPage({super.key});
  @override
  State<BKDashboardPage> createState() => _BKDashboardPageState();
}

class _BKDashboardPageState extends State<BKDashboardPage> {
  int _tab = 0;
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _BKHomeTab(uid: _uid),
      _KonselingTab(uid: _uid),
      CaseTrackingPage(bkId: _uid),
      _ChatBKTab(uid: _uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK — Guru BK'),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),       activeIcon: Icon(Icons.home),           label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Konseling'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), activeIcon: Icon(Icons.track_changes),  label: 'Kasus'),
          BottomNavigationBarItem(icon: Icon(Icons.lock_outlined),       activeIcon: Icon(Icons.lock),           label: 'Chat BK'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───
class _BKHomeTab extends StatelessWidget {
  final String uid;
  const _BKHomeTab({required this.uid});

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
                colors: [Color(0xFFEC4899), Color(0xFFD946EF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dashboard Guru BK', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.counseling)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              final open = docs.where((d) => (d.data() as Map)['status'] == KonselingStatus.open).length;
              final inProg = docs.where((d) => (d.data() as Map)['status'] == KonselingStatus.inProgress).length;
              final done = docs.where((d) => (d.data() as Map)['status'] == KonselingStatus.resolved).length;
              return Row(
                children: [
                  Expanded(child: _BKStatCard('Total\nKasus', docs.length, AppTheme.colorBK)),
                  const SizedBox(width: 10),
                  Expanded(child: _BKStatCard('Open', open, AppTheme.danger)),
                  const SizedBox(width: 10),
                  Expanded(child: _BKStatCard('On Going', inProg, AppTheme.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _BKStatCard('Resolved', done, AppTheme.secondary)),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Kasus per Kategori
          const Text('Kasus per Kategori', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...KasusBK.all.map((cat) => _CategoryRow(category: cat)),

          const SizedBox(height: 20),
          const Text('Booking Konseling Menunggu Konfirmasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection(FirebaseConstants.counseling)
              .where('bk_id', isEqualTo: uid)
              .where('status', isEqualTo: KonselingStatus.pending)
              .snapshots(),
            builder: (_, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs
                ..sort((a, b) => (((b.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
                    .compareTo(((a.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
              if (docs.isEmpty) {
                return const AppCard(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: Text('Tidak ada booking menunggu.',
                      style: TextStyle(color: AppTheme.textMuted))),
                ));
              }
              return Column(children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.colorBK.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.psychology_outlined, color: AppTheme.colorBK),
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
                            Text(data['topic'] ?? '',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => d.reference.update({'status': KonselingStatus.approved}),
                            child: const Text('Setuju', style: TextStyle(color: AppTheme.secondary, fontSize: 12)),
                          ),
                          TextButton(
                            onPressed: () => d.reference.update({'status': 'REJECTED'}),
                            child: const Text('Tolak', style: TextStyle(color: AppTheme.danger, fontSize: 12)),
                          ),
                        ],
                      ),
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
}

// ─── KONSELING TAB ───
class _KonselingTab extends StatelessWidget {
  final String uid;
  const _KonselingTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.counseling)
            .where('bk_id', isEqualTo: uid)
            .snapshots(),
        builder: (_, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs
            ..sort((a, b) => (((b.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
                .compareTo(((a.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final status = data['status'] as String? ?? '';
              final statusColor = {
                KonselingStatus.pending:    AppTheme.textMuted,
                KonselingStatus.approved:   AppTheme.primary,
                KonselingStatus.open:       AppTheme.warning,
                KonselingStatus.inProgress: AppTheme.info,
                KonselingStatus.resolved:   AppTheme.secondary,
              }[status] ?? AppTheme.textMuted;
              final category = data['category'] as String? ?? '';
              final catColor = _getCategoryColor(category);

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusBadge(label: category, color: catColor),
                        const SizedBox(width: 6),
                        StatusBadge(label: status, color: statusColor),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatRoomPage(
                                chatId: 'bk_${data['student_id']}',
                                title: 'Chat Confidential BK',
                                isConfidential: true,
                              ))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection(FirebaseConstants.users)
                          .doc(data['student_id']).get(),
                      builder: (_, s) => Text(s.data?.get('name') ?? 'Siswa',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const SizedBox(height: 4),
                    Text(data['description'] ?? '',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.colorBK,
        icon: const Icon(Icons.add),
        label: const Text('Buat Kasus'),
        onPressed: () => _createCase(context, uid),
      ),
    );
  }

  void _createCase(BuildContext ctx, String bkId) {
    final studentCtrl = TextEditingController();
    final descCtrl    = TextEditingController();
    String category   = KasusBK.akademik;

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
            const Text('Buat Kasus Konseling', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(controller: studentCtrl,
                decoration: const InputDecoration(labelText: 'UID/ID Siswa')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Kategori Kasus'),
              items: KasusBK.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setSt(() => category = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi Kasus', alignLabelWithHint: true)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colorBK),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection(FirebaseConstants.counseling).add({
                    'student_id':  studentCtrl.text.trim(),
                    'bk_id':       bkId,
                    'category':    category,
                    'description': descCtrl.text.trim(),
                    'status':      KonselingStatus.open,
                    'created_at':  FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Kasus berhasil dibuat!'), backgroundColor: AppTheme.secondary));
                  }
                },
                child: const Text('Simpan Kasus', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      )),
    );
  }
}

// ─── CHAT BK TAB ───
class _ChatBKTab extends StatelessWidget {
  final String uid;
  const _ChatBKTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.counseling)
          .where('bk_id', isEqualTo: uid)
          .where('status', whereIn: [KonselingStatus.open, KonselingStatus.inProgress, KonselingStatus.approved])
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 48, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('Belum ada sesi chat konseling aktif.', style: TextStyle(color: AppTheme.textMuted)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return AppCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    chatId: 'bk_${data['student_id']}',
                    title: 'Chat Confidential BK',
                    isConfidential: true,
                  ))),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.colorBK.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppTheme.colorBK),
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
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        StatusBadge(label: 'CONFIDENTIAL', color: AppTheme.colorBK),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted),
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
Color _getCategoryColor(String cat) => switch (cat) {
  KasusBK.akademik    => AppTheme.primary,
  KasusBK.sosial      => AppTheme.secondary,
  KasusBK.pribadi     => AppTheme.accent,
  KasusBK.karir       => AppTheme.info,
  KasusBK.pelanggaran => AppTheme.danger,
  _                   => AppTheme.textMuted,
};

class _BKStatCard extends StatelessWidget {
  final String label; final int value; final Color color;
  const _BKStatCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(children: [
      Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
    ]),
  );
}

class _CategoryRow extends StatelessWidget {
  final String category;
  const _CategoryRow({required this.category});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.counseling)
          .where('category', isEqualTo: category)
          .snapshots(),
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        final color = _getCategoryColor(category);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(category, style: const TextStyle(fontSize: 13))),
              Text('$count kasus',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        );
      },
    );
  }
}
