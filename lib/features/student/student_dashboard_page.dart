import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../shared/chat_room_page.dart';
import '../shared/notification_list_page.dart';
import 'assignment_view.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});
  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
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
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
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
    final name = _userData?['name'] ?? 'Siswa';
    final kelas = _userData?['class'] ?? '-';

    final pages = [
      _HomeTab(uid: _uid, name: name, kelas: kelas),
      _MateriTab(kelas: kelas),
      _TugasTab(uid: _uid, kelas: kelas),
      _JadwalTab(kelas: kelas),
      _AbsensiTab(uid: _uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('EduTech SMK'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationListPage())),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined),    activeIcon: Icon(Icons.home),    label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined),    activeIcon: Icon(Icons.book),    label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Absensi'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───
class _HomeTab extends StatelessWidget {
  final String uid, name, kelas;
  const _HomeTab({required this.uid, required this.name, required this.kelas});

  @override
  Widget build(BuildContext context) {
    final now = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF6366F1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Belajar, $name! 👋',
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
                  child: Text('Kelas $kelas',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats
          const Text('Ringkasan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuickStatCard(label: 'Tugas\nMenunggu', value: '3',
                  color: AppTheme.warning, icon: Icons.assignment_late_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _QuickStatCard(label: 'Nilai\nRata-rata', value: '85',
                  color: AppTheme.secondary, icon: Icons.grade_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _QuickStatCard(label: 'Kehadiran\nBulan Ini', value: '95%',
                  color: AppTheme.primary, icon: Icons.how_to_reg_outlined)),
            ],
          ),
          const SizedBox(height: 20),

          // Menu Fitur
          const Text('Fitur Utama', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10,
            children: [
              _FeatureCard(icon: Icons.forum_outlined, label: 'Forum\nDiskusi',
                  color: const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatRoomPage(chatId: 'forum_umum', title: 'Forum Diskusi')))),
              _FeatureCard(icon: Icons.chat_outlined, label: 'Chat\nGuru',
                  color: const Color(0xFF2563EB),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatRoomPage(chatId: 'guru_mapel', title: 'Chat Guru')))),
              _FeatureCard(icon: Icons.psychology_outlined, label: 'Konseling\nBK',
                  color: const Color(0xFFEC4899),
                  onTap: () {}),
              _FeatureCard(icon: Icons.warning_amber_outlined, label: 'Poin\nPelanggaran',
                  color: const Color(0xFFEF4444),
                  onTap: () => _showViolations(context, uid)),
              _FeatureCard(icon: Icons.campaign_outlined, label: 'Pengumuman',
                  color: const Color(0xFF10B981),
                  onTap: () {}),
              _FeatureCard(icon: Icons.notifications_outlined, label: 'Notifikasi',
                  color: const Color(0xFF6366F1),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationListPage()))),
            ],
          ),
          const SizedBox(height: 20),

          // Pengumuman Terbaru
          const Text('Pengumuman Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.announcements)
                .orderBy('created_at', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const AppCard(child: Center(
                  child: Text('Belum ada pengumuman.', style: TextStyle(color: AppTheme.textMuted)),
                ));
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('PENGUMUMAN',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(data['body'] ?? '',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
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

  void _showViolations(BuildContext ctx, String uid) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.violations)
            .where('student_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final totalPoin = docs.fold<int>(0, (sum, d) => sum + ((d.data() as Map)['points'] as int? ?? 0));
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Poin Pelanggaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: totalPoin > 75 ? AppTheme.danger.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$totalPoin / 100 poin',
                          style: TextStyle(fontWeight: FontWeight.w700,
                              color: totalPoin > 75 ? AppTheme.danger : AppTheme.warning)),
                    ),
                  ],
                ),
                const Divider(height: 20),
                if (docs.isEmpty)
                  const Text('Belum ada catatan pelanggaran.', style: TextStyle(color: AppTheme.textMuted))
                else
                  ...docs.take(5).map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(data['description'] ?? ''),
                      trailing: Text('${data['points']} poin',
                          style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── MATERI TAB ───
class _MateriTab extends StatelessWidget {
  final String kelas;
  const _MateriTab({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.materials)
          .where('class', isEqualTo: kelas)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 56, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('Belum ada materi.', style: TextStyle(color: AppTheme.textMuted)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isPdf = (data['type'] ?? '') == MateriType.pdf;
            return AppCard(
              onTap: () {/* Buka PDF/Video viewer */},
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isPdf ? AppTheme.danger.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(isPdf ? Icons.picture_as_pdf : Icons.play_circle_outline,
                        color: isPdf ? AppTheme.danger : AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(data['mapel'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(label: isPdf ? 'PDF' : 'VIDEO',
                                color: isPdf ? AppTheme.danger : AppTheme.primary),
                          ],
                        ),
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

// ─── TUGAS TAB ───
class _TugasTab extends StatelessWidget {
  final String uid, kelas;
  const _TugasTab({required this.uid, required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.assignments)
          .where('class', isEqualTo: kelas)
          .orderBy('deadline')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined, size: 56, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('Belum ada tugas.', style: TextStyle(color: AppTheme.textMuted)),
            ],
          ));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final deadline = (data['deadline'] as Timestamp?)?.toDate();
            final isOverdue = deadline != null && deadline.isBefore(DateTime.now());
            return AppCard(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AssignmentViewPage(
                    assignmentId: docs[i].id,
                    assignmentData: data,
                    studentId: uid,
                  ))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(label: data['mapel'] ?? '', color: AppTheme.primary),
                      const Spacer(),
                      if (isOverdue)
                        const StatusBadge(label: 'TERLAMBAT', color: AppTheme.danger),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(data['description'] ?? '',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        deadline != null
                            ? 'Deadline: ${DateFormat('d MMM yyyy, HH:mm').format(deadline)}'
                            : 'Tidak ada deadline',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? AppTheme.danger : AppTheme.textMuted,
                          fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── JADWAL TAB ───
class _JadwalTab extends StatelessWidget {
  final String kelas;
  const _JadwalTab({required this.kelas});

  static const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat'];

  @override
  Widget build(BuildContext context) {
    final today = _days[DateTime.now().weekday - 1 < 5 ? DateTime.now().weekday - 1 : 0];
    return DefaultTabController(
      length: _days.length,
      initialIndex: _days.indexOf(today) < 0 ? 0 : _days.indexOf(today),
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primary,
              tabs: _days.map((d) => Tab(text: d)).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: _days.map((day) => StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(FirebaseConstants.schedules)
                    .where('class', isEqualTo: kelas)
                    .where('day', isEqualTo: day)
                    .orderBy('start_time')
                    .snapshots(),
                builder: (_, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Text('Tidak ada jadwal $day.',
                          style: const TextStyle(color: AppTheme.textMuted)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(d['start_time'] ?? '',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                  Text(d['end_time'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['subject'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(d['teacher'] ?? '',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  Text('Ruang ${d['room'] ?? '-'}',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ABSENSI TAB ───
class _AbsensiTab extends StatelessWidget {
  final String uid;
  const _AbsensiTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absences)
          .where('student_id', isEqualTo: uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        final hadir  = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.hadir).length;
        final alpha  = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.alpha).length;
        final izin   = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.izin).length;
        final sakit  = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.sakit).length;
        final total  = docs.length;
        final persen = total > 0 ? (hadir / total * 100).toStringAsFixed(1) : '0.0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Rekap Kehadiran', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _AbsensiStat(label: 'Hadir', value: hadir, color: AppTheme.secondary),
                        _AbsensiStat(label: 'Alpha', value: alpha, color: AppTheme.danger),
                        _AbsensiStat(label: 'Izin',  value: izin,  color: AppTheme.warning),
                        _AbsensiStat(label: 'Sakit', value: sakit, color: AppTheme.info),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Persentase Kehadiran', style: TextStyle(color: AppTheme.textSecondary)),
                        Text('$persen%',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Riwayat Absensi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 10),
              ...docs.take(30).map((d) {
                final data = d.data() as Map<String, dynamic>;
                final date = (data['date'] as Timestamp?)?.toDate();
                final status = data['status'] as String? ?? '';
                final color = {
                  AbsensiStatus.hadir: AppTheme.secondary,
                  AbsensiStatus.alpha: AppTheme.danger,
                  AbsensiStatus.izin:  AppTheme.warning,
                  AbsensiStatus.sakit: AppTheme.info,
                }[status] ?? AppTheme.textMuted;

                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['mapel'] ?? 'Semua Mapel',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (date != null)
                              Text(DateFormat('d MMM yyyy').format(date),
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      StatusBadge(label: status, color: color),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ─── HELPER WIDGETS ───
class _QuickStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _QuickStatCard({required this.label, required this.value, required this.color, required this.icon});

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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }
}

class _AbsensiStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _AbsensiStat({required this.label, required this.value, required this.color});

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
