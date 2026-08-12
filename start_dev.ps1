# ============================================================
#  start_dev.ps1 — EduTech SMK Development Starter
#  Jalankan dari folder edutech_smk:  .\start_dev.ps1
# ============================================================

$projectDir = Split-Path -LiteralPath $MyInvocation.MyCommand.Path
$dataDir    = Join-Path $projectDir "emulator-data"

function Write-Step { param([string]$msg) Write-Host "" ; Write-Host ">>> $msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$msg) Write-Host "  [OK] $msg"  -ForegroundColor Green  }
function Write-Warn { param([string]$msg) Write-Host "  [!]  $msg"  -ForegroundColor Yellow }
function Write-Err  { param([string]$msg) Write-Host "  [X]  $msg"  -ForegroundColor Red    }

function Test-Port {
    param([int]$Port)
    $null -ne (netstat -ano 2>$null | Select-String "\:$Port\s+\S+\s+LISTENING")
}

function Stop-Port {
    param([int]$Port)
    $match = netstat -ano 2>$null | Select-String "\:$Port\s+\S+\s+LISTENING" | Select-Object -First 1
    if ($match) {
        $pid_ = ($match.Line.Trim() -split '\s+')[-1]
        if ($pid_ -match '^\d+$') {
            Stop-Process -Id ([int]$pid_) -Force -ErrorAction SilentlyContinue
            Write-Warn "Port $Port dibebaskan (PID $pid_)"
        }
    }
}

# ── 1. Cek apakah emulator sudah jalan ──────────────────────
Write-Step "Cek status Firebase Emulator"

if ((Test-Port 9099) -and (Test-Port 8080)) {
    Write-OK "Emulator sudah berjalan (Auth:9099, Firestore:8080)"
} else {
    # Bebaskan port yang konflik
    Write-Step "Membebaskan port konflik"
    foreach ($p in @(9099, 8080, 9199, 4400, 4500, 5000)) {
        if (Test-Port $p) { Stop-Port $p }
    }
    Start-Sleep -Seconds 1

    # Buat folder data persisten
    if (-not (Test-Path -LiteralPath $dataDir)) {
        New-Item -ItemType Directory -Path $dataDir | Out-Null
        Write-OK "Folder emulator-data dibuat"
    }

    # ── 2. Start emulator di window baru ────────────────────
    Write-Step "Menjalankan Firebase Emulator (window baru)"

    # Simpan helper script ke TEMP (path tanpa spasi agar bisa di-pass ke powershell.exe)
    $helperScript = "$env:TEMP\edutech_emu.ps1"
    $hasData = Test-Path (Join-Path $dataDir "firebase-export-metadata.json")
    if ($hasData) {
        $emuArgs = "--import=`"$dataDir`" --export-on-exit=`"$dataDir`""
    } else {
        $emuArgs = "--export-on-exit=`"$dataDir`""
    }
    @"
Set-Location -LiteralPath '$projectDir'
Write-Host 'Firebase Emulator starting...' -ForegroundColor Cyan
firebase emulators:start $emuArgs
"@ | Set-Content -LiteralPath $helperScript -Encoding UTF8

    Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $helperScript

    # ── 3. Tunggu emulator siap ─────────────────────────────
    Write-Step "Menunggu emulator Auth siap (maks 90 detik)"
    $elapsed = 0
    while (-not (Test-Port 9099)) {
        Start-Sleep -Seconds 3; $elapsed += 3
        Write-Host "`r  ...${elapsed}s" -NoNewline
        if ($elapsed -ge 90) {
            Write-Host ""
            Write-Err "Emulator tidak kunjung siap. Cek window emulator di atas."
            Read-Host "`nTekan Enter untuk keluar"
            exit 1
        }
    }
    Write-Host ""
    Write-OK "Auth Emulator siap (9099)"

    # Tunggu Firestore juga
    $elapsed = 0
    while (-not (Test-Port 8080)) {
        Start-Sleep -Seconds 2; $elapsed += 2
        if ($elapsed -ge 30) { break }
    }
    Write-OK "Firestore Emulator siap (8080)"
    Start-Sleep -Seconds 2
}

# ── 4. Seed data ─────────────────────────────────────────────
Write-Step "Menjalankan seed data"
& node "$projectDir\seed_data.js"
if ($LASTEXITCODE -ne 0) {
    Write-Warn "Seed selesai dengan warning (lihat output di atas)"
}

# ── 5. Start Flutter web (buka Chrome otomatis) ─────────────
Write-Step "Menjalankan Flutter Web (Chrome)"

Write-Host ""
Write-Host "  Login dengan:" -ForegroundColor White
Write-Host "    Email    : admin@demo.com" -ForegroundColor White
Write-Host "    Password : demo1234"       -ForegroundColor White
Write-Host ""

Set-Location -LiteralPath $projectDir
flutter run -d chrome --web-port 58715
