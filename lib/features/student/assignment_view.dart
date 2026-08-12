import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';
import 'package:intl/intl.dart';

class AssignmentViewPage extends StatefulWidget {
  final String assignmentId;
  final Map<String, dynamic> assignmentData;
  final String studentId;

  const AssignmentViewPage({
    super.key,
    required this.assignmentId,
    required this.assignmentData,
    required this.studentId,
  });

  @override
  State<AssignmentViewPage> createState() => _AssignmentViewPageState();
}

class _AssignmentViewPageState extends State<AssignmentViewPage> {
  final _answerCtrl = TextEditingController();
  File? _selectedFile;
  String? _fileName;
  bool _submitting = false;
  double _uploadProgress = 0;
  DocumentSnapshot? _submission;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  Future<void> _loadSubmission() async {
    final query = await FirebaseFirestore.instance
        .collection(FirebaseConstants.submissions)
        .where('assignment_id', isEqualTo: widget.assignmentId)
        .where('student_id', isEqualTo: widget.studentId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty && mounted) {
      setState(() => _submission = query.docs.first);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'zip'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    if (_answerCtrl.text.trim().isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jawaban atau lampirkan file.')),
      );
      return;
    }

    setState(() { _submitting = true; _uploadProgress = 0; });

    try {
      String? fileUrl;
      if (_selectedFile != null) {
        fileUrl = await StorageService.uploadSubmission(
          file: _selectedFile!,
          studentId: widget.studentId,
          assignmentId: widget.assignmentId,
          onProgress: (p) => setState(() => _uploadProgress = p),
        );
      }

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.submissions)
          .add({
        'assignment_id': widget.assignmentId,
        'student_id':    widget.studentId,
        'answer_text':   _answerCtrl.text.trim(),
        'file_url':      fileUrl,
        'file_name':     _fileName,
        'status':        TugasStatus.sudahDikirim,
        'submitted_at':  FieldValue.serverTimestamp(),
      });

      await _loadSubmission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil dikumpulkan!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengumpulkan tugas: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.assignmentData;
    final deadline = (data['deadline'] as Timestamp?)?.toDate();
    final isSubmitted = _submission != null;
    final subData = _submission?.data() as Map<String, dynamic>?;
    final grade = subData?['grade'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['title'] ?? 'Detail Tugas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignment Info Card
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
                  Row(
                    children: [
                      StatusBadge(label: data['mapel'] ?? '', color: AppTheme.primary),
                      const SizedBox(width: 8),
                      if (isSubmitted)
                        StatusBadge(
                          label: grade != null ? 'DINILAI' : 'DIKUMPULKAN',
                          color: grade != null ? AppTheme.secondary : AppTheme.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(data['title'] ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(data['description'] ?? '',
                      style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                  if (deadline != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 16, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text('Deadline: ${DateFormat('d MMM yyyy, HH:mm').format(deadline)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: deadline.isBefore(DateTime.now())
                                  ? AppTheme.danger : AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Nilai (jika sudah dinilai)
            if (grade != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grade, color: AppTheme.secondary, size: 32),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nilai Anda', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        Text('$grade',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
                      ],
                    ),
                    const Spacer(),
                    if (subData?['feedback'] != null) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Catatan Guru', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            Text(subData!['feedback'],
                                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Submission Form
            if (!isSubmitted) ...[
              const Text('Kumpulkan Tugas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Text answer
              TextField(
                controller: _answerCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Jawaban Teks',
                  hintText: 'Tulis jawaban di sini...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),

              // File Upload
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedFile != null ? AppTheme.secondary : AppTheme.border,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile != null ? Icons.attach_file : Icons.upload_file_outlined,
                        color: _selectedFile != null ? AppTheme.secondary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fileName ?? 'Lampirkan File (PDF, DOCX, JPG, ZIP)',
                          style: TextStyle(
                            color: _selectedFile != null ? AppTheme.textPrimary : AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_submitting && _selectedFile != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _uploadProgress),
                const SizedBox(height: 4),
                Text('Upload: ${(_uploadProgress * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Text('Kumpulkan Tugas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else ...[
              // Already submitted
              AppCard(
                color: const Color(0xFFF0FDF4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.secondary),
                        SizedBox(width: 8),
                        Text('Tugas Sudah Dikumpulkan',
                            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                      ],
                    ),
                    if (subData?['answer_text'] != null && (subData!['answer_text'] as String).isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Jawaban Anda:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text(subData['answer_text'],
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                    if (subData?['file_name'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_file, size: 16, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(subData!['file_name'],
                              style: const TextStyle(fontSize: 12, color: AppTheme.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
