import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text('Baca Semua', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.notifications)
            .orderBy('created_at', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 64, color: AppTheme.textMuted),
                  SizedBox(height: 16),
                  Text('Belum ada notifikasi.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textMuted)),
                  SizedBox(height: 8),
                  Text('Notifikasi tugas baru, nilai, dan\naktivitas sekolah akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final type    = data['type'] as String? ?? '';
              final isRead  = (data['read_by'] as List? ?? []).contains(uid);
              final created = (data['created_at'] as Timestamp?)?.toDate();

              final typeConfig = _getTypeConfig(type);

              return InkWell(
                onTap: () => _markRead(docs[i], uid),
                child: Container(
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : AppTheme.primaryLight,
                    border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: typeConfig.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(typeConfig.icon, color: typeConfig.color, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: TextStyle(
                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: typeConfig.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? '',
                              style: const TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary, height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                StatusBadge(label: type, color: typeConfig.color),
                                const Spacer(),
                                if (created != null)
                                  Text(
                                    _formatTime(created),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markRead(DocumentSnapshot doc, String uid) async {
    final readBy = List<String>.from((doc.data() as Map)['read_by'] ?? []);
    if (!readBy.contains(uid)) {
      readBy.add(uid);
      await doc.reference.update({'read_by': readBy});
    }
  }

  Future<void> _markAllRead(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection(FirebaseConstants.notifications)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      final readBy = List<String>.from((doc.data())['read_by'] ?? []);
      if (!readBy.contains(uid)) {
        readBy.add(uid);
        batch.update(doc.reference, {'read_by': readBy});
      }
    }
    await batch.commit();
  }

  String _formatTime(DateTime time) {
    final now  = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1)  return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24)   return '${diff.inHours}j lalu';
    if (diff.inDays < 7)     return '${diff.inDays}h lalu';
    return DateFormat('d MMM').format(time);
  }

  _NotifConfig _getTypeConfig(String type) {
    return switch (type.toUpperCase()) {
      'TUGAS' || 'ASSIGNMENT' => _NotifConfig(Icons.assignment_outlined, AppTheme.primary),
      'NILAI' || 'GRADE'      => _NotifConfig(Icons.grade_outlined, AppTheme.secondary),
      'ABSENSI'               => _NotifConfig(Icons.how_to_reg_outlined, AppTheme.info),
      'PELANGGARAN'           => _NotifConfig(Icons.warning_amber_outlined, AppTheme.danger),
      'KONSELING' || 'BK'     => _NotifConfig(Icons.psychology_outlined, AppTheme.colorBK),
      'DARURAT'               => _NotifConfig(Icons.campaign_outlined, AppTheme.danger),
      'PENGUMUMAN'            => _NotifConfig(Icons.notifications_outlined, AppTheme.warning),
      'WALI'                  => _NotifConfig(Icons.supervisor_account_outlined, AppTheme.colorWali),
      _                       => _NotifConfig(Icons.notifications_outlined, AppTheme.primary),
    };
  }
}

class _NotifConfig {
  final IconData icon;
  final Color color;
  const _NotifConfig(this.icon, this.color);
}
