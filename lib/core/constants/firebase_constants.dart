/// Nama-nama collection Firestore dan path Firebase Storage
class FirebaseConstants {
  FirebaseConstants._();

  // ── Firestore Collections ──
  static const String users         = 'users';
  static const String classes       = 'classes';
  static const String materials     = 'materials';
  static const String assignments   = 'assignments';
  static const String submissions   = 'submissions';
  static const String quizzes       = 'quizzes';
  static const String quizAnswers   = 'quiz_answers';
  static const String absences      = 'absences';
  static const String violations    = 'violations';
  static const String counseling    = 'counseling';
  static const String chats         = 'chats';
  static const String messages      = 'messages';
  static const String notifications = 'notifications';
  static const String announcements = 'announcements';
  static const String schedules     = 'schedules';
  static const String piketLog      = 'piket_log';

  // ── Firebase Storage Paths ──
  static const String storageMaterials   = 'materials';
  static const String storageSubmissions = 'submissions';
  static const String storagePiket       = 'piket';
  static const String storageProfile     = 'profile';

  // ── FCM Topics ──
  static const String topicAllUsers  = 'all_users';
  static const String topicSiswa     = 'role_siswa';
  static const String topicGuru      = 'role_guru';
  static const String topicWali      = 'role_wali';
  static const String topicBK        = 'role_bk';
  static const String topicPiket     = 'role_piket';

  // ── User Document Fields ──
  static const String fieldRole       = 'role';
  static const String fieldName       = 'name';
  static const String fieldEmail      = 'email';
  static const String fieldClass      = 'class';
  static const String fieldNISN       = 'nisn';
  static const String fieldSubjects   = 'subjects';
  static const String fieldFcmToken   = 'fcm_token';
  static const String fieldCreatedAt  = 'created_at';
  static const String fieldUpdatedAt  = 'updated_at';

  // ── Batas Alert Wali Kelas ──
  static const int alertAlphaThreshold      = 3;   // alpha > 3x → alert
  static const double alertNilaiDropPercent = 20.0; // drop > 20% → alert
  static const int alertViolationMax        = 100;  // poin maks pelanggaran
  static const int alertViolationWarning    = 75;   // warning di 75%
}
