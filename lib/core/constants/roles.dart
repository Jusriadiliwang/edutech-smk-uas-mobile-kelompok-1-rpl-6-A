/// Konstanta role pengguna sesuai spesifikasi tugas
class AppRoles {
  AppRoles._();

  static const String siswa      = 'SISWA';
  static const String guruMapel  = 'GURU_MAPEL';
  static const String waliKelas  = 'WALI_KELAS';
  static const String guruBK     = 'GURU_BK';
  static const String guruPiket  = 'GURU_PIKET';
  static const String admin      = 'ADMIN';

  static const List<String> allRoles = [
    siswa, guruMapel, waliKelas, guruBK, guruPiket, admin,
  ];

  static String displayName(String role) {
    switch (role) {
      case siswa:      return 'Siswa';
      case guruMapel:  return 'Guru Mata Pelajaran';
      case waliKelas:  return 'Wali Kelas';
      case guruBK:     return 'Guru BK';
      case guruPiket:  return 'Guru Piket';
      case admin:      return 'Admin / Kepala Sekolah';
      default:         return role;
    }
  }
}

/// Status absensi
class AbsensiStatus {
  AbsensiStatus._();
  static const String hadir  = 'HADIR';
  static const String alpha  = 'ALPHA';
  static const String izin   = 'IZIN';
  static const String sakit  = 'SAKIT';
}

/// Status tugas / kuis
class TugasStatus {
  TugasStatus._();
  static const String belumDikerjakan = 'BELUM';
  static const String sudahDikirim    = 'SUBMITTED';
  static const String sudahDinilai    = 'GRADED';
}

/// Status konseling BK
class KonselingStatus {
  KonselingStatus._();
  static const String pending  = 'PENDING';
  static const String approved = 'APPROVED';
  static const String open     = 'OPEN';
  static const String inProgress = 'IN_PROGRESS';
  static const String resolved = 'RESOLVED';
}

/// Kategori kasus BK
class KasusBK {
  KasusBK._();
  static const String akademik    = 'AKADEMIK';
  static const String sosial      = 'SOSIAL';
  static const String pribadi     = 'PRIBADI';
  static const String karir       = 'KARIR';
  static const String pelanggaran = 'PELANGGARAN';

  static const List<String> all = [
    akademik, sosial, pribadi, karir, pelanggaran,
  ];
}

/// Tipe materi
class MateriType {
  MateriType._();
  static const String pdf   = 'PDF';
  static const String video = 'VIDEO';
}
