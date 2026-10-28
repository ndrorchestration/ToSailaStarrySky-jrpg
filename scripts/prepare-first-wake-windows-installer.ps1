# Creator-controlled exact-source Windows installer and security verification.
# Produces a local installer ONLY. Never changes Defender, signs, uploads or releases.
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedSourceSha,
    [string]$GodotExe = "",
    [string]$NsisExe = "",
    [string]$OutputDir = ""
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$actualSha = (& git -C $root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $actualSha -cne $ExpectedSourceSha) {
    throw "TSTSS_INSTALLER_SOURCE_SHA_MISMATCH"
}
$dirty = @(& git -C $root status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw "TSTSS_INSTALLER_TRACKED_SOURCE_NOT_CLEAN"
}
$status = Get-MpComputerStatus -ErrorAction Stop
if (-not [bool]$status.AntivirusEnabled -or -not [bool]$status.RealTimeProtectionEnabled) {
    throw "TSTSS_INSTALLER_DEFENDER_REALTIME_REQUIRED"
}

if (-not $GodotExe) {
    # If Godot is running, prefer the exact editor the creator already installed.
    foreach ($process in @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^Godot' })) {
        try {
            if (-not $process.Path -or -not (Test-Path -LiteralPath $process.Path)) { continue }
            $version = ((& $process.Path --version) | Out-String).Trim()
            if ($LASTEXITCODE -eq 0 -and $version -eq "4.7.2.stable.official.ed1daf0bf") {
                $GodotExe = [string]$process.Path
                break
            }
        } catch { continue }
    }
}
if (-not $GodotExe) {
    foreach ($command in @("godot.exe", "godot", "Godot_v4.7.2-stable_win64_console.exe")) {
        $cmd = Get-Command $command -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $cmd -or -not $cmd.Source) { continue }
        $version = ((& $cmd.Source --version) | Out-String).Trim()
        if ($LASTEXITCODE -eq 0 -and $version -eq "4.7.2.stable.official.ed1daf0bf") {
            $GodotExe = [string]$cmd.Source
            break
        }
    }
}

# Windows players/developers often use Godot's official portable ZIP rather
# than an MSI install or PATH entry. Search only conventional, bounded local
# locations, then verify the EXACT official version before selecting it.
if (-not $GodotExe) {
    $portableLocations = @(
        (Join-Path $env:USERPROFILE "Downloads\Godot_v4.7.2-stable_win64.exe"),
        (Join-Path $env:USERPROFILE "Downloads"),
        (Join-Path $env:USERPROFILE "Documents")
    )
    foreach ($folder in @(Get-ChildItem -LiteralPath $env:USERPROFILE -Directory -Filter "godot-4.7.2*" -ErrorAction SilentlyContinue)) {
        $portableLocations += $folder.FullName
    }
    foreach ($folder in $portableLocations) {
        if (-not (Test-Path -LiteralPath $folder -PathType Container)) { continue }
        foreach ($filename in @(
            "Godot_v4.7.2-stable_win64_console.exe",
            "Godot_v4.7.2-stable_win64.exe"
        )) {
            $candidate = Join-Path $folder $filename
            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
            try {
                $version = ((& $candidate --version 2>$null) | Out-String).Trim()
                if ($LASTEXITCODE -eq 0 -and $version -eq "4.7.2.stable.official.ed1daf0bf") {
                    $GodotExe = $candidate
                    Write-Host "TSTSS_INSTALLER_VERIFIED_PORTABLE_GODOT=FOUND"
                    break
                }
            } catch { continue }
        }
        if ($GodotExe) { break }
    }
}

if (-not $GodotExe -or -not (Test-Path -LiteralPath $GodotExe -PathType Leaf)) {
    throw "TSTSS_INSTALLER_GODOT_4_7_2_NOT_FOUND"
}
$templates = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $templates -PathType Leaf)) {
    throw "TSTSS_INSTALLER_GODOT_EXPORT_TEMPLATE_NOT_FOUND"
}

if (-not $NsisExe) {
    $nsisCommand = Get-Command "makensis.exe" -ErrorAction SilentlyContinue
    if ($nsisCommand -and $nsisCommand.Source) { $NsisExe = [string]$nsisCommand.Source }
}
if (-not $NsisExe) {
    foreach ($candidate in @(
        (Join-Path ([Environment]::GetFolderPath("ProgramFilesX86")) "NSIS\makensis.exe"),
        (Join-Path $env:ProgramFiles "NSIS\makensis.exe")
    )) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $NsisExe = [IO.Path]::GetFullPath($candidate)
            break
        }
    }
}
if (-not $NsisExe -or -not (Test-Path -LiteralPath $NsisExe -PathType Leaf)) {
    throw "TSTSS_INSTALLER_NSIS_COMPILER_NOT_FOUND"
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $env:LOCALAPPDATA "TSTSS\FirstWakeInstallerCandidate"
}
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
if (Test-Path -LiteralPath $OutputDir) {
    throw "TSTSS_INSTALLER_OUTPUT_ALREADY_EXISTS"
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "TSTSS_INSTALLER_PREP_STAGE=BUILD"
$builder = Join-Path $root "scripts\build-first-wake-godot-installer.ps1"
& $builder -GodotExe $GodotExe -NsisExe $NsisExe -OutputDir $OutputDir
if (-not $?) { throw "TSTSS_INSTALLER_PREP_BUILD_FAILED" }
$setup = Join-Path $OutputDir "ToSailTheStarrySky-Setup.exe"
$game = Join-Path $OutputDir "ToSailTheStarrySky.exe"
if (-not (Test-Path -LiteralPath $setup -PathType Leaf) -or
    -not (Test-Path -LiteralPath $game -PathType Leaf)) {
    throw "TSTSS_INSTALLER_PREP_BINARIES_MISSING"
}

Write-Host "TSTSS_INSTALLER_PREP_STAGE=DEFENDER_ON_SCAN"
$scanner = Join-Path $root "scripts\verify-first-wake-installer-defender.ps1"
& $scanner -SetupExe $setup -GameExe $game -ExpectedSourceSha $ExpectedSourceSha -OutputDir $OutputDir
if (-not $?) { throw "TSTSS_INSTALLER_PREP_SCAN_FAILED" }
$receipt = Join-Path $OutputDir "TSTSS_WINDOWS_INSTALLER_DEFENDER_CUSTODY.json"
if (-not (Test-Path -LiteralPath $receipt -PathType Leaf)) {
    throw "TSTSS_INSTALLER_PREP_RECEIPT_MISSING"
}
$data = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
$sha = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
if ($data.sourceSha -cne $ExpectedSourceSha -or
    $data.installer.result -cne "PASS" -or
    $data.installer.sha256 -cne $sha -or
    $data.game.result -cne "PASS" -or
    -not [bool]$data.defenderRealtimeEnabled -or
    [bool]$data.publicReleaseAuthorized) {
    throw "TSTSS_INSTALLER_PREP_INVALID_RECEIPT"
}
Write-Host "TSTSS_INSTALLER_LOCAL_PREP=PASS"
Write-Host "TSTSS_INSTALLER_SETUP_PATH=$setup"
Write-Host "TSTSS_INSTALLER_SETUP_SHA256=$sha"
Write-Host "TSTSS_INSTALLER_PLAYER_ACCEPTANCE=NOT_ESTABLISHED"
Write-Host "TSTSS_INSTALLER_PUBLISHER_APPROVAL=NOT_ESTABLISHED"
Write-Host "PUBLIC_RELEASE_AUTHORIZED=NO"
