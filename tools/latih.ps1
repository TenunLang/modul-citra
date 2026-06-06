# Jalankan training OCR digit + uji baca, dari root repo modul-citra.
#
#   powershell -ExecutionPolicy Bypass -File tools/latih.ps1            # latih + uji
#   powershell -ExecutionPolicy Bypass -File tools/latih.ps1 -Dataset   # regen dataset dulu
#   powershell -ExecutionPolicy Bypass -File tools/latih.ps1 -Tenun "C:\path\tenun.exe"
param(
    [switch]$Dataset,
    [string]$Tenun = "C:\Users\mumur\AppData\Local\Tenun\tenun.exe"
)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

if (-not (Test-Path $Tenun)) { throw "tenun.exe tidak ditemukan: $Tenun" }

if ($Dataset) {
    Write-Host "== regen dataset multi-font ==" -ForegroundColor Cyan
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "buat_dataset.ps1")
}
if (-not (Test-Path "digit_dataset.txt")) {
    Write-Host "digit_dataset.txt belum ada -> generate" -ForegroundColor Yellow
    powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot "buat_dataset.ps1")
}

Write-Host "== latih (bisa beberapa menit) ==" -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
& $Tenun run examples/ocr_latih_dataset.tenun
Write-Host ("waktu latih: {0}s" -f [math]::Round($sw.Elapsed.TotalSeconds, 0)) -ForegroundColor Green

if (-not (Test-Path "model_font.txt")) { throw "model_font.txt tidak terbentuk (mungkin OOM saat latih)" }

Write-Host "== uji baca ==" -ForegroundColor Cyan
foreach ($img in @("nik.png", "nik_times.png", "nik_tahoma.png", "tgl_calibri.png")) {
    if (Test-Path $img) { & $Tenun run examples/ocr_baca.tenun $img }
}
