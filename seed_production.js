// seed_production.js — Seed demo data ke Firebase PRODUCTION
// Jalankan SETELAH login firebase dan punya akun admin di production
// node seed_production.js
//
// PENTING: Script ini menggunakan Firebase REST API (tidak butuh service account)
// Setelah admin login di browser, dapatkan idToken dari browser console:
// firebase.auth().currentUser.getIdToken(true).then(t => console.log(t))

const https = require('https');

const PROJECT_ID = 'edutech-smk-app-71383';
const API_KEY    = 'AIzaSyBcj_KPcqvcdHGsD28PmWrzna94pAkfN1Y';

// ── Helper: REST API Firestore ──────────────────────────────
function firestoreSet(collection, docId, data, idToken) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(toFirestoreFields(data));
    const path = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
    const options = {
      hostname: 'firestore.googleapis.com',
      path: path,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
        'Content-Length': Buffer.byteLength(body),
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => res.statusCode < 300 ? resolve(JSON.parse(data)) : reject(new Error(`${res.statusCode}: ${data}`)));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function firestoreAdd(collection, data, idToken) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ fields: toFirestoreFields(data).fields });
    const path = `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}`;
    const options = {
      hostname: 'firestore.googleapis.com',
      path: path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
        'Content-Length': Buffer.byteLength(body),
      },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => res.statusCode < 300 ? resolve(JSON.parse(data)) : reject(new Error(`${res.statusCode}: ${data}`)));
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') fields[key] = { stringValue: value };
    else if (typeof value === 'number') fields[key] = { integerValue: String(value) };
    else if (typeof value === 'boolean') fields[key] = { booleanValue: value };
    else if (value === null) fields[key] = { nullValue: 'NULL_VALUE' };
    else if (value instanceof Date) fields[key] = { timestampValue: value.toISOString() };
    else if (Array.isArray(value)) fields[key] = { arrayValue: { values: value.map(v => Object.values(toFirestoreFields({ v })[0])[0]) } };
  }
  return { fields };
}

// ── Login with Email/Password ──────────────────────────────
function loginWithPassword(email, password) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ email, password, returnSecureToken: true });
    const options = {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:signInWithPassword?key=${API_KEY}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.idToken) resolve(parsed);
        else reject(new Error(parsed.error?.message || 'Login failed'));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Register user ──────────────────────────────────────────
function registerUser(email, password) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ email, password, returnSecureToken: true });
    const options = {
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/accounts:signUp?key=${API_KEY}`,
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(body) },
    };
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        const parsed = JSON.parse(data);
        if (parsed.localId) resolve(parsed);
        else reject(new Error(parsed.error?.message || 'Register failed'));
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

async function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

async function main() {
  console.log('=== Seed Production EduTech SMK ===\n');

  // 1. Login sebagai admin
  console.log('Login sebagai admin@gmail.com...');
  let adminToken;
  try {
    const result = await loginWithPassword('admin@gmail.com', 'kelompok1');
    adminToken = result.idToken;
    console.log('  [OK] Login berhasil\n');
  } catch (e) {
    console.error('  [X] Gagal login:', e.message);
    process.exit(1);
  }

  // 2. Daftarkan demo accounts
  console.log('Membuat demo accounts...');
  const demoAccounts = [
    { email: 'siswa@demo.com',  password: 'demo1234', role: 'SISWA',      name: 'Ahmad Siswa',   kelas: 'XI RPL 1', nisn: '0012345678' },
    { email: 'guru@demo.com',   password: 'demo1234', role: 'GURU_MAPEL', name: 'Bu Sari Guru'   },
    { email: 'wali@demo.com',   password: 'demo1234', role: 'WALI_KELAS', name: 'Pak Budi Wali', kelas: 'XI RPL 1' },
    { email: 'bk@demo.com',     password: 'demo1234', role: 'GURU_BK',    name: 'Bu Dewi BK'     },
    { email: 'piket@demo.com',  password: 'demo1234', role: 'GURU_PIKET', name: 'Pak Rudi Piket' },
  ];

  for (const acc of demoAccounts) {
    try {
      const reg = await registerUser(acc.email, acc.password);
      // Set Firestore document pakai admin token
      await firestoreSet('users', reg.localId, {
        email: acc.email, name: acc.name, role: acc.role,
        class: acc.kelas || null, nisn: acc.nisn || null,
      }, adminToken);
      console.log(`  [OK] ${acc.role.padEnd(12)}: ${acc.email}`);
    } catch (e) {
      if (e.message.includes('EMAIL_EXISTS')) {
        console.log(`  [--] ${acc.email} sudah ada`);
      } else {
        console.log(`  [!!] ${acc.email}: ${e.message}`);
      }
    }
    await sleep(500);
  }

  // 3. Tambah pengumuman
  console.log('\nMembuat pengumuman...');
  const annTexts = [
    { title: 'Selamat Datang di EduTech SMK!', body: 'Sistem LMS EduTech SMK telah aktif. Login dengan akun demo untuk mencoba semua fitur.' },
    { title: 'Jadwal UTS Semester Ganjil', body: 'UTS akan dilaksanakan tanggal 20-25 Agustus 2026. Harap mempersiapkan diri dengan baik.' },
    { title: 'Pengumpulan Tugas Akhir', body: 'Batas pengumpulan tugas akhir Mobile Development adalah 30 Agustus 2026 pukul 23:59.' },
  ];
  for (const ann of annTexts) {
    try {
      await firestoreAdd('announcements', { ...ann, created_at: new Date() }, adminToken);
      console.log(`  [OK] ${ann.title.substring(0, 40)}`);
    } catch (e) { console.log(`  [!!] ${e.message}`); }
  }

  // 4. Tambah jadwal
  console.log('\nMembuat jadwal kelas XI RPL 1...');
  const schedules = [
    { day: 'Senin',  subject: 'Mobile Development', teacher: 'Bu Sari Guru', start_time: '07:00', end_time: '09:00', room: 'Lab Komputer 1', class: 'XI RPL 1' },
    { day: 'Senin',  subject: 'Matematika',         teacher: 'Pak Ahmad',    start_time: '09:00', end_time: '11:00', room: '11A',          class: 'XI RPL 1' },
    { day: 'Selasa', subject: 'Bahasa Indonesia',   teacher: 'Bu Rahma',     start_time: '07:00', end_time: '09:00', room: '11A',          class: 'XI RPL 1' },
    { day: 'Selasa', subject: 'Mobile Development', teacher: 'Bu Sari Guru', start_time: '10:00', end_time: '12:00', room: 'Lab Komputer 1', class: 'XI RPL 1' },
    { day: 'Rabu',   subject: 'PKK',                teacher: 'Pak Budi',     start_time: '07:00', end_time: '09:00', room: '11A',          class: 'XI RPL 1' },
    { day: 'Kamis',  subject: 'Basis Data',         teacher: 'Bu Ani',       start_time: '07:00', end_time: '09:00', room: 'Lab Komputer 2', class: 'XI RPL 1' },
    { day: 'Jumat',  subject: 'Olahraga',           teacher: 'Pak Dedi',     start_time: '07:00', end_time: '09:00', room: 'Lapangan',     class: 'XI RPL 1' },
  ];
  for (const s of schedules) {
    try {
      await firestoreAdd('schedules', s, adminToken);
      console.log(`  [OK] ${s.day} - ${s.subject}`);
    } catch (e) { console.log(`  [!!] ${e.message}`); }
    await sleep(200);
  }

  console.log('\n=== SEED PRODUCTION SELESAI! ===');
  console.log('Demo accounts (password: demo1234):');
  console.log('  siswa@demo.com   → Siswa (XI RPL 1)');
  console.log('  guru@demo.com    → Guru Mapel');
  console.log('  wali@demo.com    → Wali Kelas (XI RPL 1)');
  console.log('  bk@demo.com      → Guru BK');
  console.log('  piket@demo.com   → Guru Piket');
  console.log('\nAdmin: admin@gmail.com / kelompok1');
  process.exit(0);
}

main().catch(e => { console.error('Error:', e); process.exit(1); });
