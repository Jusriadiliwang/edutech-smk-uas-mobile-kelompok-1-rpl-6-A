import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';

/// Halaman scan QR untuk absensi cepat di pintu gerbang
/// Menggunakan qr_code_scanner package untuk kamera
class QuickScanPage extends StatefulWidget {
  final String piketId;
  const QuickScanPage({super.key, required this.piketId});

  @override
  State<QuickScanPage> createState() => _QuickScanPageState();
}

class _QuickScanPageState extends State<QuickScanPage> {
  final _nisnCtrl      = TextEditingController();
  String? _lastScanned;
  bool _scanning       = false;
  bool _processing     = false;
  List<Map<String, dynamic>> _recentScans = [];

  // Batas jam masuk (07:30 = terlambat)
  static const _batasJam = 7;
  static const _batasMenit = 30;

  bool get _isLate {
    final now = DateTime.now();
    return now.hour > _batasJam || (now.hour == _batasJam && now.minute > _batasMenit);
  }

  @override
  void dispose() {
    _nisnCtrl.dispose();
    super.dispose();
  }

  Future<void> _processStudent(String nisn) async {
    if (nisn.trim().isEmpty || _processing) return;
    setState(() => _processing = true);

    try {
      // Cari siswa berdasarkan NISN
      final query = await FirebaseFirestore.instance
          .collection(FirebaseConstants.users)
          .where(FirebaseConstants.fieldNISN, isEqualTo: nisn.trim())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          _showResult(false, 'NISN $nisn tidak ditemukan di sistem.');
        }
        return;
      }

      final studentDoc  = query.docs.first;
      final studentData = studentDoc.data();
      final studentName = studentData['name'] as String? ?? 'Siswa';
      final today       = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Cek apakah sudah absen hari ini
      final existing = await FirebaseFirestore.instance
          .collection(FirebaseConstants.absences)
          .where('student_id', isEqualTo: studentDoc.id)
          .where('date_str', isEqualTo: today)
          .where('type', isEqualTo: 'PIKET')
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          _showResult(false, '$studentName sudah absen hari ini.');
        }
        return;
      }

      // Catat absensi
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.absences)
          .add({
        'student_id':   studentDoc.id,
        'student_name': studentName,
        'class':        studentData['class'] ?? '',
        'nisn':         nisn.trim(),
        'date':         FieldValue.serverTimestamp(),
        'date_str':     today,
        'status':       AbsensiStatus.hadir,
        'late':         _isLate,
        'scan_time':    DateFormat('HH:mm').format(DateTime.now()),
        'marked_by':    widget.piketId,
        'type':         'PIKET',
      });

      // Jika terlambat, catat di buku piket
      if (_isLate) {
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.piketLog)
            .add({
          'type':         'TERLAMBAT',
          'student_name': studentName,
          'note':         'Masuk jam ${DateFormat('HH:mm').format(DateTime.now())}',
          'date_str':     today,
          'recorded_by':  widget.piketId,
          'created_at':   FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _lastScanned = nisn.trim();
        _recentScans.insert(0, {
          'name': studentName,
          'nisn': nisn.trim(),
          'time': DateFormat('HH:mm').format(DateTime.now()),
          'late': _isLate,
        });
        if (_recentScans.length > 20) _recentScans.removeLast();
      });

      if (mounted) {
        _showResult(true,
            _isLate
                ? '⚠️ $studentName — TERLAMBAT (${DateFormat('HH:mm').format(DateTime.now())})'
                : '✅ $studentName — HADIR (${DateFormat('HH:mm').format(DateTime.now())})');
      }
    } catch (e) {
      if (mounted) {
        _showResult(false, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showResult(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? (_isLate ? AppTheme.warning : AppTheme.secondary)
            : AppTheme.danger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status waktu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isLate ? AppTheme.warning.withOpacity(0.1) : AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isLate ? AppTheme.warning.withOpacity(0.3) : AppTheme.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isLate ? Icons.warning_amber_outlined : Icons.check_circle_outline,
                  color: _isLate ? AppTheme.warning : AppTheme.secondary,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLate ? 'Sudah Melewati Batas Masuk' : 'Dalam Waktu Masuk',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isLate ? AppTheme.warning : AppTheme.secondary,
                      ),
                    ),
                    Text(
                      'Batas: ${_batasJam.toString().padLeft(2, '0')}:${_batasMenit.toString().padLeft(2, '0')} WIB  |  Sekarang: ${DateFormat('HH:mm').format(DateTime.now())} WIB',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // QR Scanner Area (placeholder - perlu qr_code_scanner package)
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, size: 56, color: Colors.white),
                const SizedBox(height: 12),
                const Text('Kamera QR Scanner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                const Text('Integrasikan qr_code_scanner package\nuntuk scan kamera live',
                    style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _scanning = !_scanning),
                  icon: Icon(_scanning ? Icons.stop : Icons.play_arrow),
                  label: Text(_scanning ? 'Stop Scan' : 'Mulai Scan'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Input manual NISN
          const Text('Input Manual NISN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nisnCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (v) {
                    _processStudent(v);
                    _nisnCtrl.clear();
                  },
                  decoration: const InputDecoration(
                    labelText: 'Masukkan NISN Siswa',
                    hintText: '0012345678',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _processing ? null : () {
                    _processStudent(_nisnCtrl.text);
                    _nisnCtrl.clear();
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                  child: _processing
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Absen', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Hasil scan terbaru
          if (_recentScans.isNotEmpty) ...[
            const Text('Scan Terbaru', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ..._recentScans.take(10).map((scan) => AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: (scan['late'] as bool? ?? false)
                          ? AppTheme.warning.withOpacity(0.1)
                          : AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      (scan['late'] as bool? ?? false)
                          ? Icons.access_time : Icons.check_circle_outline,
                      color: (scan['late'] as bool? ?? false) ? AppTheme.warning : AppTheme.secondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('NISN: ${scan['nisn']}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(scan['time'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      if (scan['late'] as bool? ?? false)
                        const Text('TERLAMBAT', style: TextStyle(fontSize: 9, color: AppTheme.warning, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}
