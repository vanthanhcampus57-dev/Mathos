# Mathos Windows Release Automated Build Script
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\build_windows_release.ps1
# Optional: -Version v0.1.0-alpha -GodotExe C:\path\to\Godot_console.exe

param(
    [string]$Version = "v0.1.0-alpha",
    [string]$GodotExe = "C:\Users\HP\Documents\ChatGPT\MATHOS\TOOLS\Godot\4.7.1\portable\Godot_v4.7.1-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectPath = Split-Path -Parent $ScriptDir
$BuildDir = Join-Path $ProjectPath "build\windows"
$ReleaseDir = Join-Path $ProjectPath "release"
$ZipName = "Mathos-Windows-x64-$Version.zip"
$ZipPath = Join-Path $ReleaseDir $ZipName
$ChecksumPath = "$ZipPath.sha256"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Mathos Windows Release Build Pipeline" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check Godot executable
if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "Godot console executable not found at: $GodotExe"
}

# Check Export Templates
$GodotDir = Split-Path -Parent $GodotExe
$PortableTemplates = Join-Path $GodotDir "editor_data\export_templates\4.7.1.stable"
$AppDataTemplates = Join-Path $env:APPDATA "Godot\export_templates\4.7.1.stable"

if ((-not (Test-Path -LiteralPath (Join-Path $PortableTemplates "windows_release_x86_64.exe"))) -and (-not (Test-Path -LiteralPath (Join-Path $AppDataTemplates "windows_release_x86_64.exe")))) {
    throw "Export templates 4.7.1.stable are missing. Install them in Godot before building. Checked: $PortableTemplates and $AppDataTemplates"
}

# Ensure build and release directories exist
if (-not (Test-Path -LiteralPath $BuildDir)) {
    New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null
}
if (-not (Test-Path -LiteralPath $ReleaseDir)) {
    New-Item -ItemType Directory -Force -Path $ReleaseDir | Out-Null
}

# Run Godot headless export
Write-Host "`n[1/4] Running Godot Release Export..." -ForegroundColor Green
& $GodotExe --headless --path $ProjectPath --export-release "Windows Desktop" (Join-Path $BuildDir "Mathos.exe")

if ((-not (Test-Path -LiteralPath (Join-Path $BuildDir "Mathos.exe"))) -or (-not (Test-Path -LiteralPath (Join-Path $BuildDir "Mathos.pck")))) {
    throw "Export failed. Mathos.exe or Mathos.pck is missing in $BuildDir"
}

Write-Host "Export success: Mathos.exe and Mathos.pck created." -ForegroundColor Green

# Compress Release Archive
Write-Host "`n[2/4] Packaging ZIP Archive..." -ForegroundColor Green
if (Test-Path -LiteralPath $ZipPath) {
    Remove-Item -LiteralPath $ZipPath -Force
}
if (Test-Path -LiteralPath $ChecksumPath) {
    Remove-Item -LiteralPath $ChecksumPath -Force
}

Compress-Archive -Path (Join-Path $BuildDir "*") -DestinationPath $ZipPath -Force
Write-Host "Archive created at: $ZipPath" -ForegroundColor Green

# Calculate Hash
Write-Host "`n[3/4] Calculating SHA256 Checksum..." -ForegroundColor Green
$hashInfo = Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
$hash = $hashInfo.Hash
$fileSize = (Get-Item -LiteralPath $ZipPath).Length / 1MB
$checksumLine = "$hash  $ZipName"
[System.IO.File]::WriteAllText($ChecksumPath, $checksumLine + "`n", [System.Text.Encoding]::ASCII)

Write-Host "`n[4/4] Verifying release artifacts..." -ForegroundColor Green
if ((Get-Content -LiteralPath $ChecksumPath -Raw).Trim() -ne $checksumLine) {
    throw "Checksum file verification failed: $ChecksumPath"
}

# Output Report
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " RELEASE BUILD SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Version      : $Version"
Write-Host "File Name    : $ZipName"
Write-Host ("File Size    : {0:N2} MB" -f $fileSize)
Write-Host "SHA256 Hash  : $hash"
Write-Host "Output Path  : $ZipPath"
Write-Host "Checksum File: $ChecksumPath"
Write-Host "==========================================" -ForegroundColor Cyan
