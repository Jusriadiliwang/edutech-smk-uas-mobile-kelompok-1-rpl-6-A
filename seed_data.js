// Script seed data — jalankan SETELAH emulator aktif
// node seed_data.js
//
// Menggunakan firebase-admin agar bypass Firestore security rules

process.env.FIRESTORE_EMULATOR_HOST  = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

const { initializeApp }    = require('firebase-admin/app');
const { getAuth }          = require('firebase-admin/auth');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');

initializeApp({ projectId: 'demo-edutech-smk' });

const auth = getAuth();
const db   = getFirestore();

const accounts = [
  { email: 'siswa@demo.com',  password: 'demo1234', role: 'SISWA',      name: 'Ahmad Siswa',   kelas: 'XI RPL 1', nisn: '0012345678' },
  { email: 'guru@demo.com',   password: 'demo1234', role: 'GURU_MAPEL', name: 'Bu Sari Guru'   },
  { email: 'wali@demo.com',   password: 'demo1234', role: 'WALI_KELAS', name: 'Pak Budi Wali', kelas: 'XI RPL 1' },
  { email: 'bk@demo.com',     password: 'demo1234', role: 'GURU_BK',    name: 'Bu Dewi BK'     },
  { email: 'piket@demo.com',  password: 'demo1234', role: 'GURU_PIKET', name: 'Pak Rudi Piket' },
  { email: 'admin@demo.com',  password: 'demo1234', role: 'ADMIN',      name: 'Admin Sekolah'  },
];

async function main() {
  console.log('Seed data EduTech SMK...\n');
  console.log('Membuat akun pengguna...');

  for (const acc of accounts) {
    try {
      const user = await auth.createUser({ email: acc.email, password: acc.password, displayName: acc.name });
      await db.collection('users').doc(user.uid).set({
        email: acc.email,
        name:  acc.name,
        role:  acc.role,
        class: acc.kelas  || null,
        nisn:  acc.nisn   || null,
        created_at: Timestamp.now(),
      });
      console.log(`  [OK] ${acc.role.padEnd(12)} : ${acc.email}`);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        // Auth user exists — pastikan dokumen Firestore juga ada
        try {
          const existing = await auth.getUserByEmail(acc.email);
          await db.collection('users').doc(existing.uid).set({
            email: acc.email, name: acc.name, role: acc.role,
            class: acc.kelas || null, nisn: acc.nisn || null,
            created_at: Timestamp.now(),
          }, { merge: true });
          console.log(`  [--] ${acc.email} sudah ada (Firestore diperbarui)`);
        } catch (e2) {
          console.log(`  [!!] ${acc.email}: ${e2.message}`);
        }
      } else {
        console.log(`  [!!] ${acc.email}: ${e.message}`);
      }
    }
  }

  // Materi pembelajaran
  console.log('\nMembuat materi...');
  const materials = [
    { title: 'Pengenalan Flutter & Dart',  mapel: 'Mobile Development', class: 'XI RPL 1', type: 'PDF'   },
    { title: 'Widget Dasar Flutter',        mapel: 'Mobile Development', class: 'XI RPL 1', type: 'VIDEO' },
    { title: 'Integrasi Firebase',          mapel: 'Mobile Development', class: 'XI RPL 1', type: 'PDF'   },
  ];
  for (const m of materials) {
    await db.collection('materials').add({
      ...m, file_url: 'https://example.com/demo.pdf',
      uploaded_by: 'demo', created_at: Timestamp.now(),
    });
    console.log(`  [OK] ${m.title}`);
  }

  // Tugas
  console.log('\nMembuat tugas...');
  const dl = new Date(); dl.setDate(dl.getDate() + 7);
  await db.collection('assignments').add({
    title: 'Tugas 1: Hello World Flutter',
    mapel: 'Mobile Development', class: 'XI RPL 1',
    description: 'Buat aplikasi Flutter dengan teks "Hello EduTech SMK".',
    deadline: Timestamp.fromDate(dl),
    created_by: 'demo', created_at: Timestamp.now(),
  });
  console.log('  [OK] Tugas 1 berhasil');

  // Pengumuman
  console.log('\nMembuat pengumuman...');
  await db.collection('announcements').add({
    title: 'Selamat Datang di EduTech SMK!',
    body:  'Sistem LMS EduTech SMK telah aktif. Login dengan akun demo untuk mencoba semua fitur.',
    created_at: Timestamp.now(),
  });
  console.log('  [OK] Pengumuman berhasil');

  console.log('\n======================================');
  console.log('SEED DATA SELESAI!');
  console.log('======================================');
  console.log('Akun Demo (password: demo1234)');
  console.log('  siswa@demo.com   -> Role: Siswa');
  console.log('  guru@demo.com    -> Role: Guru Mapel');
  console.log('  wali@demo.com    -> Role: Wali Kelas');
  console.log('  bk@demo.com      -> Role: Guru BK');
  console.log('  piket@demo.com   -> Role: Guru Piket');
  console.log('  admin@demo.com   -> Role: Admin');
  console.log('======================================\n');

  process.exit(0);
}

main().catch(e => { console.error('Error:', e); process.exit(1); });
