import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/storage_service.dart';

class UploadMaterialPage extends StatefulWidget {
  final String teacherId;
  const UploadMaterialPage({super.key, required this.teacherId});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  final _formKey    = GlobalKey<FormState>();
  final _titleCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _mapelCtrl  = TextEditingController();
  final _kelasCtrl  = TextEditingController();
  String _type      = MateriType.pdf;
  File? _file;
  String? _fileName;
  double _progress  = 0;
  bool _uploading   = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _mapelCtrl.dispose();
    _kelasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final ext = _type == MateriType.pdf
        ? ['pdf']
        : ['mp4', 'mov', 'avi', 'mkv'];

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _file     = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih file terlebih dahulu.')));
      return;
    }

    setState(() { _uploading = true; _progress = 0; });

    try {
      final fileUrl = await StorageService.uploadMaterial(
        file: _file!,
        mapel: _mapelCtrl.text.trim(),
        onProgress: (p) => setState(() => _progress = p),
      );

      await FirebaseFirestore.instance
          .collection(FirebaseConstants.materials)
          .add({
        'title':       _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'mapel':       _mapelCtrl.text.trim(),
        'class':       _kelasCtrl.text.trim(),
        'type':        _type,
        'file_url':    fileUrl,
        'file_name':   _fileName,
        'uploaded_by': widget.teacherId,
        'created_at':  FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materi berhasil diupload!'),
            backgroundColor: AppTheme.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Materi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tipe materi
              const Text('Tipe Materi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _TypeCard(
                    label: 'PDF / Dokumen',
                    icon: Icons.picture_as_pdf_outlined,
                    color: AppTheme.danger,
                    selected: _type == MateriType.pdf,
                    onTap: () => setState(() { _type = MateriType.pdf; _file = null; _fileName = null; }),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _TypeCard(
                    label: 'Video',
                    icon: Icons.play_circle_outline,
                    color: AppTheme.primary,
                    selected: _type == MateriType.video,
                    onTap: () => setState(() { _type = MateriType.video; _file = null; _fileName = null; }),
                  )),
                ],
              ),
              const SizedBox(height: 20),

              // Form fields
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Materi *', hintText: 'Contoh: Dasar-dasar Pemrograman Dart'),
                validator: (v) => v?.trim().isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _mapelCtrl,
                decoration: const InputDecoration(labelText: 'Mata Pelajaran *', hintText: 'Contoh: Mobile Development'),
                validator: (v) => v?.trim().isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _kelasCtrl,
                decoration: const InputDecoration(labelText: 'Kelas Tujuan *', hintText: 'Contoh: XI RPL 1'),
                validator: (v) => v?.trim().isEmpty == true ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Deskripsi / Ringkasan Materi',
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 20),

              // File picker
              const Text('File *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _file != null ? AppTheme.secondary.withOpacity(0.05) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _file != null ? AppTheme.secondary : AppTheme.border,
                      width: _file != null ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _file != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                        size: 40,
                        color: _file != null ? AppTheme.secondary : AppTheme.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _fileName ?? 'Ketuk untuk memilih file',
                        style: TextStyle(
                          color: _file != null ? AppTheme.textPrimary : AppTheme.textMuted,
                          fontWeight: _file != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _type == MateriType.pdf ? 'Format: PDF' : 'Format: MP4, MOV, AVI',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),

              // Upload Progress
              if (_uploading) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: AppTheme.border,
                      color: AppTheme.primary,
                    )),
                    const SizedBox(width: 10),
                    Text('${(_progress * 100).toInt()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Sedang mengupload ke Firebase Storage...',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton.icon(
                  onPressed: _uploading ? null : _upload,
                  icon: _uploading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : const Icon(Icons.cloud_upload_outlined, size: 20),
                  label: Text(_uploading ? 'Mengupload...' : 'Upload ke Firebase',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({required this.label, required this.icon, required this.color,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.border, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? color : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: selected ? color : AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}
