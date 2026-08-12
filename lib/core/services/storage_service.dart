import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../constants/firebase_constants.dart';

class StorageService {
  StorageService._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _uuid = Uuid();

  /// Upload file ke Firebase Storage
  /// Mengembalikan download URL setelah upload selesai
  static Future<String> uploadFile({
    required File file,
    required String folder,
    String? customFileName,
    void Function(double progress)? onProgress,
  }) async {
    final fileName = customFileName ??
        '${_uuid.v4()}${path.extension(file.path)}';
    final ref = _storage.ref().child('$folder/$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: _getMimeType(file.path)),
    );

    // Monitor progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await uploadTask;
    return await ref.getDownloadURL();
  }

  /// Upload bytes (untuk web platform)
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String folder,
    required String fileName,
    String? contentType,
    void Function(double progress)? onProgress,
  }) async {
    final uniqueName = '${_uuid.v4()}_$fileName';
    final ref = _storage.ref().child('$folder/$uniqueName');

    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await uploadTask;
    return await ref.getDownloadURL();
  }

  /// Hapus file dari Firebase Storage berdasarkan URL
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File mungkin sudah dihapus atau tidak ditemukan
    }
  }

  /// Ambil download URL dari path storage
  static Future<String> getDownloadUrl(String storagePath) async {
    final ref = _storage.ref().child(storagePath);
    return await ref.getDownloadURL();
  }

  /// Upload foto profil pengguna
  static Future<String> uploadProfilePhoto({
    required File file,
    required String uid,
    void Function(double)? onProgress,
  }) {
    return uploadFile(
      file: file,
      folder: '${FirebaseConstants.storageProfile}/$uid',
      customFileName: 'photo.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload materi pembelajaran
  static Future<String> uploadMaterial({
    required File file,
    required String mapel,
    void Function(double)? onProgress,
  }) {
    return uploadFile(
      file: file,
      folder: '${FirebaseConstants.storageMaterials}/$mapel',
      onProgress: onProgress,
    );
  }

  /// Upload file submisi tugas siswa
  static Future<String> uploadSubmission({
    required File file,
    required String studentId,
    required String assignmentId,
    void Function(double)? onProgress,
  }) {
    return uploadFile(
      file: file,
      folder: '${FirebaseConstants.storageSubmissions}/$assignmentId/$studentId',
      onProgress: onProgress,
    );
  }

  /// Tentukan MIME type berdasarkan ekstensi file
  static String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    const types = {
      '.pdf':  'application/pdf',
      '.jpg':  'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png':  'image/png',
      '.mp4':  'video/mp4',
      '.mov':  'video/quicktime',
      '.avi':  'video/x-msvideo',
      '.doc':  'application/msword',
      '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xls':  'application/vnd.ms-excel',
      '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      '.zip':  'application/zip',
    };
    return types[ext] ?? 'application/octet-stream';
  }
}
