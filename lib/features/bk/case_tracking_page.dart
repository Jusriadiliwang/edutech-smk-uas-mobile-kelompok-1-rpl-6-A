import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

class CaseTrackingPage extends StatelessWidget {
  final String bkId;
  const CaseTrackingPage({super.key, required this.bkId});

  static const _columns = [
    KonselingStatus.open,
    KonselingStatus.inProgress,
    KonselingStatus.resolved,
  ];

  static const _columnLabels = {
    KonselingStatus.open:       'Open',
    KonselingStatus.inProgress: 'On Going',
    KonselingStatus.resolved:   'Resolved',
  };

  static const _columnColors = {
    KonselingStatus.open:       AppTheme.danger,
    KonselingStatus.inProgress: AppTheme.warning,
    KonselingStatus.resolved:   AppTheme.secondary,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracking Kasus BK')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection(FirebaseConstants.counseling)
            .get(), // NO where - filter client-side
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

          final allDocs = snap.data!.docs
              .where((d) => (d.data() as Map)['bk_id'] == bkId).toList()
            ..sort((a, b) => (((b.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0)
                .compareTo(((a.data() as Map)['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? 0));

          // Grup per status
          final grouped = {
            for (final s in _columns)
              s: allDocs.where((d) => (d.data() as Map)['status'] == s).toList(),
          };

          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: _columns.map((status) {
              final docs = grouped[status] ?? [];
              final color = _columnColors[status]!;

              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kolom header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(_columnLabels[status]!,
                              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${docs.length}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Kartu kasus
                    Expanded(
                      child: docs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 36, color: AppTheme.textMuted),
                                  const SizedBox(height: 8),
                                  Text('Tidak ada kasus', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (_, i) {
                                final data = docs[i].data() as Map<String, dynamic>;
                                final category = data['category'] as String? ?? '';
                                final catColor = _getCatColor(category);
                                final createdAt = (data['created_at'] as Timestamp?)?.toDate();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.border),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4, offset: const Offset(0, 2)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Card header
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(0.07),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        ),
                                        child: Row(
                                          children: [
                                            StatusBadge(label: category, color: catColor),
                                            const Spacer(),
                                            if (status != KonselingStatus.resolved) ...[
                                              PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_horiz, size: 18, color: AppTheme.textMuted),
                                                itemBuilder: (_) => [
                                                  if (status == KonselingStatus.open)
                                                    const PopupMenuItem(value: 'progress', child: Text('→ On Going')),
                                                  if (status == KonselingStatus.inProgress)
                                                    const PopupMenuItem(value: 'resolve', child: Text('✓ Resolved')),
                                                ],
                                                onSelected: (action) {
                                                  final newStatus = action == 'progress'
                                                      ? KonselingStatus.inProgress
                                                      : KonselingStatus.resolved;
                                                  docs[i].reference.update({'status': newStatus});
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Card body
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            FutureBuilder<DocumentSnapshot>(
                                              future: FirebaseFirestore.instance
                                                  .collection(FirebaseConstants.users)
                                                  .doc(data['student_id']).get(),
                                              builder: (_, s) => Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor: catColor.withOpacity(0.15),
                                                    child: Text(
                                                      (s.data?.get('name') as String? ?? 'S')[0].toUpperCase(),
                                                      style: TextStyle(fontSize: 12, color: catColor, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    s.data?.get('name') ?? 'Siswa',
                                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              data['description'] ?? '',
                                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),

                                            // Notes
                                            if (data['notes'] != null && (data['notes'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF8FAFC),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text('📝 ${data['notes']}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],

                                            const SizedBox(height: 8),
                                            if (createdAt != null)
                                              Text(
                                                DateFormat('d MMM yyyy').format(createdAt),
                                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                              ),

                                            // Tombol tambah catatan
                                            if (status != KonselingStatus.resolved) ...[
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton.icon(
                                                  onPressed: () => _addNote(context, docs[i]),
                                                  icon: const Icon(Icons.note_add_outlined, size: 14),
                                                  label: const Text('Tambah Catatan', style: TextStyle(fontSize: 11)),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                                    foregroundColor: catColor,
                                                    side: BorderSide(color: catColor.withOpacity(0.4)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _addNote(BuildContext ctx, DocumentSnapshot doc) {
    final noteCtrl = TextEditingController(text: (doc.data() as Map)['notes'] ?? '');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Catatan Tindak Lanjut'),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Catatan penanganan kasus...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await doc.reference.update({'notes': noteCtrl.text.trim()});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Color _getCatColor(String cat) => switch (cat) {
    KasusBK.akademik    => AppTheme.primary,
    KasusBK.sosial      => AppTheme.secondary,
    KasusBK.pribadi     => AppTheme.accent,
    KasusBK.karir       => AppTheme.info,
    KasusBK.pelanggaran => AppTheme.danger,
    _                   => AppTheme.textMuted,
  };
}
