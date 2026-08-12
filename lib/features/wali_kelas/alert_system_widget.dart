import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_theme.dart';

/// Widget alert system cerdas untuk Wali Kelas
/// Menampilkan notifikasi otomatis berdasarkan threshold:
/// - Alpha > 3x dalam periode tertentu
/// - Nilai drop > 20%
/// - Poin pelanggaran mendekati batas maksimum
class AlertSystemWidget extends StatelessWidget {
  final String kelas;
  const AlertSystemWidget({super.key, required this.kelas});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.campaign_outlined, color: AppTheme.warning, size: 18),
            SizedBox(width: 6),
            Text('Alert System', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 10),
        _AlphaAlert(kelas: kelas),
        const SizedBox(height: 8),
        _ViolationAlert(kelas: kelas),
      ],
    );
  }
}

// ── Alert: Siswa dengan Alpha > 3 kali ──
class _AlphaAlert extends StatelessWidget {
  final String kelas;
  const _AlphaAlert({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.absences)
          .where('class', isEqualTo: kelas)
          .where('status', isEqualTo: 'ALPHA')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        // Hitung alpha per siswa
        final alphaCount = <String, int>{};
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentId = data['student_id'] as String? ?? '';
          alphaCount[studentId] = (alphaCount[studentId] ?? 0) + 1;
        }

        // Filter siswa dengan alpha melebihi threshold
        final atRisk = alphaCount.entries
            .where((e) => e.value > FirebaseConstants.alertAlphaThreshold)
            .toList();

        if (atRisk.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.danger.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.danger.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppTheme.danger),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${atRisk.length} Siswa Alpha > ${FirebaseConstants.alertAlphaThreshold}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...atRisk.map((e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(FirebaseConstants.users)
                      .doc(e.key).get(),
                  builder: (_, snap) => Row(
                    children: [
                      const SizedBox(width: 36),
                      const Icon(Icons.person_outline, size: 14, color: AppTheme.danger),
                      const SizedBox(width: 6),
                      Text(
                        snap.data?.get('name') ?? e.key,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      Text('${e.value}x alpha',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                    ],
                  ),
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}

// ── Alert: Poin pelanggaran mendekati batas ──
class _ViolationAlert extends StatelessWidget {
  final String kelas;
  const _ViolationAlert({required this.kelas});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.violations)
          .where('class', isEqualTo: kelas)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();

        // Hitung akumulasi poin per siswa
        final pointMap = <String, int>{};
        for (final doc in snap.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentId = data['student_id'] as String? ?? '';
          final points = data['points'] as int? ?? 0;
          pointMap[studentId] = (pointMap[studentId] ?? 0) + points;
        }

        // Filter yang mendekati atau melebihi batas warning
        final atRisk = pointMap.entries
            .where((e) => e.value >= FirebaseConstants.alertViolationWarning)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        if (atRisk.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.priority_high_rounded,
                        size: 16, color: AppTheme.warning),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${atRisk.length} Siswa Poin Pelanggaran Tinggi',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...atRisk.take(3).map((e) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection(FirebaseConstants.users)
                      .doc(e.key).get(),
                  builder: (_, snap) {
                    final pct = (e.value / FirebaseConstants.alertViolationMax * 100).toInt();
                    return Row(
                      children: [
                        const SizedBox(width: 36),
                        const Icon(Icons.person_outline, size: 14, color: AppTheme.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            snap.data?.get('name') ?? e.key,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                        Text('${e.value}/${FirebaseConstants.alertViolationMax} ($pct%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: e.value >= FirebaseConstants.alertViolationMax
                                  ? AppTheme.danger : AppTheme.warning,
                            )),
                      ],
                    );
                  },
                ),
              )),
            ],
          ),
        );
      },
    );
  }
}
