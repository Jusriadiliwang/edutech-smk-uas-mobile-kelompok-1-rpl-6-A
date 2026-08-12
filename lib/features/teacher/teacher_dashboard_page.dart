import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../shared/chat_room_page.dart';
import '../shared/notification_list_page.dart';
import 'upload_material_page.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});
  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
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

  @override
  Widget build(BuildContext context) {
    final name = _userData?['name'] ?? 'Guru';

    final pages = [
      _TeacherHomeTab(uid: _uid, name: name),
      _MateriManageTab(uid: _uid),
      _TugasManageTab(uid: _uid),
      _AbsensiInputTab(uid: _uid),
      _StatistikTab(uid: _uid),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduTech SMK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationListPage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
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
          BottomNavigationBarItem(icon: Icon(Icons.how_to_reg_outlined), activeIcon: Icon(Icons.how_to_reg), label: 'Absensi'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Statistik'),
        ],
      ),
    );
  }
}

// ─── HOME TAB ───
class _TeacherHomeTab extends StatelessWidget {
  final String uid, name;
  const _TeacherHomeTab({required this.uid, required this.name});

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
                colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Mengajar, $name! 🎓',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now()),
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Menu Cepat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _QuickAction(
                icon: Icons.upload_file,
                label: 'Upload\nMateri',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => UploadMaterialPage(teacherId: uid))),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(
                icon: Icons.add_task,
                label: 'Buat\nTugas',
                color: const Color(0xFF2563EB),
                onTap: () => _showCreateAssignment(context, uid),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(
                icon: Icons.quiz_outlined,
                label: 'Buat\nKuis',
                color: const Color(0xFF10B981),
                onTap: () => _showCreateQuiz(context, uid),
              )),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(
                icon: Icons.chat_outlined,
                label: 'Chat\nSiswa',
                color: const Color(0xFFEC4899),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ChatRoomPage(chatId: 'guru_mapel', title: 'Chat Siswa'))),
              )),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Tugas Menunggu Penilaian', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.submissions)
                .where('status', isEqualTo: 'SUBMITTED')
                .orderBy('submitted_at', descending: true)
                .limit(5)
                .snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const AppCard(child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Semua tugas sudah dinilai ✓', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                ));
              }
              return Column(children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return AppCard(
                  onTap: () => _gradeSubmission(context, d.id, data),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_late_outlined, color: AppTheme.warning),
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
                              builder: (_, snap) => Text(
                                snap.data?.get('name') ?? 'Siswa',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text('Menunggu penilaian',
                                style: TextStyle(fontSize: 12, color: AppTheme.warning.withOpacity(0.8))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppTheme.textMuted),
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

  void _showCreateAssignment(BuildContext ctx, String uid) {
    final titleCtrl = TextEditingController();
    final descCtrl  = TextEditingController();
    final mapelCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    DateTime? deadline;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx2, setSt) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx2).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buat Tugas Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Tugas')),
            const SizedBox(height: 10),
            TextField(controller: mapelCtrl, decoration: const InputDecoration(labelText: 'Mata Pelajaran')),
            const SizedBox(height: 10),
            TextField(controller: kelasCtrl, decoration: const InputDecoration(labelText: 'Kelas (contoh: XI RPL 1)')),
            const SizedBox(height: 10),
            TextField(controller: descCtrl, maxLines: 3,
                decoration: const InputDecoration(labelText: 'Instruksi / Deskripsi', alignLabelWithHint: true)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: ctx2,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setSt(() => deadline = picked);
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(deadline != null
                  ? 'Deadline: ${DateFormat('d MMM yyyy').format(deadline!)}'
                  : 'Pilih Deadline'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isEmpty) return;
                  await FirebaseFirestore.instance
                      .collection(FirebaseConstants.assignments)
                      .add({
                    'title':       titleCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'mapel':       mapelCtrl.text.trim(),
                    'class':       kelasCtrl.text.trim(),
                    'deadline':    deadline != null ? Timestamp.fromDate(deadline!) : null,
                    'created_by':  uid,
                    'created_at':  FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Tugas berhasil dibuat!'), backgroundColor: AppTheme.secondary));
                  }
                },
                child: const Text('Simpan Tugas'),
              ),
            ),
          ],
        ),
      )),
    );
  }

  void _showCreateQuiz(BuildContext ctx, String uid) {
    final titleCtrl = TextEditingController();
    final mapelCtrl = TextEditingController();
    final kelasCtrl = TextEditingController();
    int duration = 30;
    final List<Map<String, dynamic>> questions = [];
    bool loading = false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          void addQuestion() {
            final qCtrl = TextEditingController();
            final List<TextEditingController> optCtrls = List.generate(4, (_) => TextEditingController());
            int answer = 0;
            showDialog(
              context: sheetCtx,
              builder: (_) => StatefulBuilder(
                builder: (dCtx, setD) => AlertDialog(
                  title: const Text('Tambah Pertanyaan'),
                  content: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(controller: qCtrl, maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Pertanyaan *')),
                      const SizedBox(height: 12),
                      ...List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Radio<int>(value: i, groupValue: answer,
                              onChanged: (v) => setD(() => answer = v!)),
                          Expanded(child: TextField(controller: optCtrls[i],
                              decoration: InputDecoration(labelText: 'Opsi ${String.fromCharCode(65 + i)}'))),
                        ]),
                      )),
                      const Text('Pilih radio button untuk jawaban benar',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ]),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Batal')),
                    ElevatedButton(
                      onPressed: () {
                        if (qCtrl.text.trim().isEmpty) return;
                        setSheet(() {
                          questions.add({
                            'question': qCtrl.text.trim(),
                            'options': optCtrls.map((c) => c.text.trim()).toList(),
                            'answer': answer,
                            'type': 'MC',
                          });
                        });
                        Navigator.pop(dCtx);
                      },
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Buat Kuis Baru', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                TextField(controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Judul Kuis *')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: mapelCtrl,
                      decoration: const InputDecoration(labelText: 'Mata Pelajaran *'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: kelasCtrl,
                      decoration: const InputDecoration(labelText: 'Kelas *'))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Durasi: ', style: TextStyle(fontSize: 13)),
                  DropdownButton<int>(
                    value: duration,
                    items: [15, 20, 30, 45, 60, 90].map((m) =>
                        DropdownMenuItem(value: m, child: Text('$m menit'))).toList(),
                    onChanged: (v) => setSheet(() => duration = v ?? 30),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${questions.length} pertanyaan',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  OutlinedButton.icon(
                    onPressed: addQuestion,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah Soal'),
                  ),
                ]),
                if (questions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...questions.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Text('${e.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Expanded(child: Text(e.value['question'] ?? '',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13))),
                      IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                          onPressed: () => setSheet(() => questions.removeAt(e.key))),
                    ]),
                  )),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading || questions.isEmpty ? null : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setSheet(() => loading = true);
                      await FirebaseFirestore.instance.collection(FirebaseConstants.quizzes).add({
                        'title':      titleCtrl.text.trim(),
                        'mapel':      mapelCtrl.text.trim(),
                        'class':      kelasCtrl.text.trim(),
                        'duration':   duration,
                        'questions':  questions,
                        'created_by': uid,
                        'created_at': DateTime.now(),
                      });
                      setSheet(() => loading = false);
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                          content: Text('Kuis berhasil dibuat!'),
                          backgroundColor: AppTheme.secondary,
                        ));
                      }
                    },
                    icon: loading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish),
                    label: Text(loading ? 'Menyimpan...' : 'Publikasikan Kuis'),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  void _gradeSubmission(BuildContext ctx, String subId, Map<String, dynamic> data) {
    final gradeCtrl    = TextEditingController();
    final feedbackCtrl = TextEditingController();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Beri Nilai', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data['answer_text'] != null && (data['answer_text'] as String).isNotEmpty) ...[
              const Text('Jawaban Siswa:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                child: Text(data['answer_text'], style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 12),
            ],
            TextField(controller: gradeCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nilai (0-100)')),
            const SizedBox(height: 10),
            TextField(controller: feedbackCtrl, maxLines: 2,
                decoration: const InputDecoration(labelText: 'Catatan / Feedback (opsional)',
                    alignLabelWithHint: true)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final grade = int.tryParse(gradeCtrl.text.trim());
                  if (grade == null || grade < 0 || grade > 100) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Masukkan nilai 0-100.')));
                    return;
                  }
                  await FirebaseFirestore.instance
                      .collection(FirebaseConstants.submissions).doc(subId)
                      .update({
                    'grade':    grade,
                    'feedback': feedbackCtrl.text.trim(),
                    'status':   'GRADED',
                    'graded_at': FieldValue.serverTimestamp(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Nilai berhasil disimpan!'), backgroundColor: AppTheme.secondary));
                  }
                },
                child: const Text('Simpan Nilai'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── MATERI MANAGE TAB ───
class _MateriManageTab extends StatelessWidget {
  final String uid;
  const _MateriManageTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.materials)
            .where('uploaded_by', isEqualTo: uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        d['type'] == 'PDF' ? Icons.picture_as_pdf : Icons.play_circle_outline,
                        color: AppTheme.danger,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${d['mapel']} — ${d['class']}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                      onPressed: () => docs[i].reference.delete(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => UploadMaterialPage(teacherId: uid))),
        icon: const Icon(Icons.add),
        label: const Text('Upload Materi'),
        backgroundColor: AppTheme.primary,
      ),
    );
  }
}

// ─── TUGAS MANAGE TAB ───
class _TugasManageTab extends StatelessWidget {
  final String uid;
  const _TugasManageTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.assignments)
          .where('created_by', isEqualTo: uid)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final deadline = (d['deadline'] as Timestamp?)?.toDate();
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StatusBadge(label: d['mapel'] ?? '', color: AppTheme.primary),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                        onPressed: () => docs[i].reference.delete(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (deadline != null) ...[
                    const SizedBox(height: 4),
                    Text('Deadline: ${DateFormat('d MMM yyyy').format(deadline)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── ABSENSI INPUT TAB ───
class _AbsensiInputTab extends StatefulWidget {
  final String uid;
  const _AbsensiInputTab({required this.uid});
  @override
  State<_AbsensiInputTab> createState() => _AbsensiInputTabState();
}

class _AbsensiInputTabState extends State<_AbsensiInputTab> {
  String _kelas = '';
  final Map<String, String> _statusMap = {};
  List<DocumentSnapshot> _students = [];
  bool _loading = false;
  bool _saving = false;

  Future<void> _loadStudents() async {
    if (_kelas.trim().isEmpty) return;
    setState(() => _loading = true);
    final snap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.users)
        .where('class', isEqualTo: _kelas.trim())
        .get();
    setState(() {
      _students = snap.docs;
      _statusMap.clear();
      for (final s in snap.docs) {
        _statusMap[s.id] = AbsensiStatus.hadir;
      }
      _loading = false;
    });
  }

  Future<void> _saveAbsensi() async {
    setState(() => _saving = true);
    final batch = FirebaseFirestore.instance.batch();
    final now   = Timestamp.now();
    for (final entry in _statusMap.entries) {
      final ref = FirebaseFirestore.instance.collection(FirebaseConstants.absences).doc();
      batch.set(ref, {
        'student_id': entry.key,
        'class':      _kelas,
        'date':       now,
        'status':     entry.value,
        'marked_by':  widget.uid,
      });
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Absensi berhasil disimpan!'), backgroundColor: AppTheme.secondary));
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Kelas (contoh: XI RPL 1)',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  onChanged: (v) => _kelas = v,
                  onSubmitted: (_) => _loadStudents(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loadStudents,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                child: const Text('Muat'),
              ),
            ],
          ),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _students.length,
            itemBuilder: (_, i) {
              final s = _students[i].data() as Map<String, dynamic>;
              final sid = _students[i].id;
              final status = _statusMap[sid] ?? AbsensiStatus.hadir;
              return AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryLight,
                      child: Text(
                        (s['name'] as String? ?? 'S')[0].toUpperCase(),
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                    ...{
                      AbsensiStatus.hadir: ('H', AppTheme.secondary),
                      AbsensiStatus.alpha: ('A', AppTheme.danger),
                      AbsensiStatus.izin:  ('I', AppTheme.warning),
                      AbsensiStatus.sakit: ('S', AppTheme.info),
                    }.entries.map((e) => GestureDetector(
                      onTap: () => setState(() => _statusMap[sid] = e.key),
                      child: Container(
                        width: 32, height: 32, margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: status == e.key ? e.value.$2 : e.value.$2.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: e.value.$2.withOpacity(0.4)),
                        ),
                        child: Center(
                          child: Text(e.value.$1,
                              style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800,
                                color: status == e.key ? Colors.white : e.value.$2,
                              )),
                        ),
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
        ),
        if (_students.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveAbsensi,
                child: _saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Simpan Absensi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── STATISTIK TAB ───
class _StatistikTab extends StatelessWidget {
  final String uid;
  const _StatistikTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Distribusi Nilai
          const Text('Distribusi Nilai Siswa', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(FirebaseConstants.submissions)
                .where('status', isEqualTo: TugasStatus.sudahDinilai)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return AppCard(child: Center(
                  child: Padding(padding: const EdgeInsets.all(20),
                    child: Text('Belum ada nilai.', style: const TextStyle(color: AppTheme.textMuted)))));
              }
              final grades = docs.map((d) => (d.data() as Map)['grade'] as num? ?? 0).toList();
              final avg = grades.fold<num>(0, (a, b) => a + b) / grades.length;
              final atas90  = grades.where((g) => g >= 90).length;
              final atas75  = grades.where((g) => g >= 75 && g < 90).length;
              final atas60  = grades.where((g) => g >= 60 && g < 75).length;
              final bawah60 = grades.where((g) => g < 60).length;

              return Column(children: [
                // Rata-rata card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(children: [
                    const Icon(Icons.grade, color: Colors.white, size: 32),
                    const SizedBox(width: 16),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Rata-rata Nilai', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(avg.toStringAsFixed(1),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                      Text('dari ${docs.length} penilaian',
                          style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                // Grade distribution bars
                AppCard(
                  child: Column(children: [
                    _GradeBar(label: 'A (≥90)', count: atas90, total: docs.length, color: AppTheme.secondary),
                    const SizedBox(height: 8),
                    _GradeBar(label: 'B (75-89)', count: atas75, total: docs.length, color: AppTheme.primary),
                    const SizedBox(height: 8),
                    _GradeBar(label: 'C (60-74)', count: atas60, total: docs.length, color: AppTheme.warning),
                    const SizedBox(height: 8),
                    _GradeBar(label: 'D (<60)', count: bawah60, total: docs.length, color: AppTheme.danger),
                  ]),
                ),
              ]);
            },
          ),
          const SizedBox(height: 20),

          // Rekap Absensi
          const Text('Rekap Absensi Kelas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(FirebaseConstants.absences)
                .where('teacher_id', isEqualTo: uid).snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              final hadir = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.hadir).length;
              final alpha = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.alpha).length;
              final izin  = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.izin).length;
              final sakit = docs.where((d) => (d.data() as Map)['status'] == AbsensiStatus.sakit).length;
              final total = docs.length;
              final persen = total > 0 ? (hadir / total * 100).toStringAsFixed(1) : '0.0';

              return AppCard(
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _AbsStat(label: 'Hadir', value: hadir, color: AppTheme.secondary),
                    _AbsStat(label: 'Alpha', value: alpha, color: AppTheme.danger),
                    _AbsStat(label: 'Izin',  value: izin,  color: AppTheme.warning),
                    _AbsStat(label: 'Sakit', value: sakit, color: AppTheme.info),
                  ]),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Tingkat Kehadiran', style: TextStyle(color: AppTheme.textSecondary)),
                    Text('$persen%',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
                  ]),
                ]),
              );
            },
          ),
          const SizedBox(height: 20),

          // Kuis yang dibuat
          const Text('Kuis Saya', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(FirebaseConstants.quizzes)
                .where('created_by', isEqualTo: uid)
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (_, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return AppCard(child: Center(child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    const Icon(Icons.quiz_outlined, size: 40, color: AppTheme.textMuted),
                    const SizedBox(height: 8),
                    const Text('Belum ada kuis.', style: TextStyle(color: AppTheme.textMuted)),
                  ]),
                )));
              }
              return Column(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final qCount = (data['questions'] as List?)?.length ?? 0;
                  return AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.quiz, color: AppTheme.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${data['mapel']} • Kelas ${data['class']} • $qCount soal',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ])),
                      // Lihat jawaban siswa
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection(FirebaseConstants.quizAnswers)
                            .where('quiz_id', isEqualTo: d.id).snapshots(),
                        builder: (_, aSnap) {
                          final count = aSnap.data?.docs.length ?? 0;
                          return StatusBadge(label: '$count siswa', color: AppTheme.primary);
                        },
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GradeBar extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _GradeBar({required this.label, required this.count, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 12))),
      Expanded(
        child: Stack(children: [
          Container(height: 18, decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(height: 18, decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4))),
          ),
        ]),
      ),
      const SizedBox(width: 8),
      Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _AbsStat extends StatelessWidget {
  final String label; final int value; final Color color;
  const _AbsStat({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
  ]);
}

// ─── HELPERS ───
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
