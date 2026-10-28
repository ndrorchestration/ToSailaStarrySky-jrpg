param(
    [Parameter(Mandatory=$true)]
    [string]$GodotExe,
    [Parameter(Mandatory=$true)]
    [string]$NsisExe,
    [string]$OutputDir = ""
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$Repo = Split-Path -Parent $PSScriptRoot
$Game = Join-Path $Repo "godot"
$Project = Join-Path $Game "project.godot"
$Preset = Join-Path $Game "export_presets.cfg"
$Nsi = Join-Path $Repo "packaging\windows\ToSailTheStarrySky.nsi"
if (-not $OutputDir) { $OutputDir = Join-Path $Repo "build\first-wake-installer-proof" }
$OutputDir = [IO.Path]::GetFullPath($OutputDir)
$GameExe = Join-Path $OutputDir "ToSailTheStarrySky.exe"
$Installer = Join-Path $OutputDir "ToSailTheStarrySky-Setup.exe"
$Manifest = Join-Path $OutputDir "SHA256SUMS.txt"

foreach ($file in @($GodotExe, $NsisExe, $Project, $Preset, $Nsi)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "TSTSS_INSTALLER_REQUIRED_FILE_MISSING:$file"
    }
}
if ((Get-Content -LiteralPath $Project -Raw) -notmatch 'run/main_scene="res://scenes/first_wake_game.tscn"') {
    throw "TSTSS_INSTALLER_WRONG_GAME_ENTRY"
}
$presets = Get-Content -LiteralPath $Preset -Raw
if (-not $presets.Contains('name="Windows Desktop Review"') -or
    -not $presets.Contains("binary_format/embed_pck=true") -or
    -not $presets.Contains('platform="Windows Desktop"')) {
    throw "TSTSS_INSTALLER_EXPORT_PRESET_NOT_EMBEDDED_WINDOWS"
}
$version = ((& $GodotExe --version) | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $version -ne "4.7.2.stable.official.ed1daf0bf") {
    throw "TSTSS_INSTALLER_GODOT_VERSION_MISMATCH:$version"
}
$Template = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable\windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $Template)) {
    throw "TSTSS_INSTALLER_OFFICIAL_EXPORT_TEMPLATE_MISSING:$Template"
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
if (Test-Path -LiteralPath $GameExe) { Remove-Item -LiteralPath $GameExe -Force }
if (Test-Path -LiteralPath $Installer) { Remove-Item -LiteralPath $Installer -Force }

# Guard both the current scene and the real source-gated physics+save chain.
& $GodotExe --headless --path $Game --editor --quit
if ($LASTEXITCODE -ne 0) { throw "TSTSS_INSTALLER_IMPORT_FAILED:$LASTEXITCODE" }
& $GodotExe --headless --fixed-fps 60 --path $Game --script res://tests/first_wake_game_entry_test.gd
if ($LASTEXITCODE -ne 0) { throw "TSTSS_INSTALLER_NATIVE_GAME_ENTRY_FAILED:$LASTEXITCODE" }
& $GodotExe --headless --path $Game --export-release "Windows Desktop Review" $GameExe
if ($LASTEXITCODE -ne 0) { throw "TSTSS_INSTALLER_WINDOWS_EXPORT_FAILED:$LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $GameExe -PathType Leaf) -or
    (Get-Item -LiteralPath $GameExe).Length -lt 1000000) {
    throw "TSTSS_INSTALLER_EXPORTED_EXE_MISSING_OR_TRUNCATED"
}
# The full game payload is embedded in the executable, so no separate PCK
# is needed. The player does NOT install Godot, Python, Node or PowerShell.
& $NsisExe "/DGAME_EXE=$GameExe" "/DINSTALLER_OUT=$Installer" $Nsi
if ($LASTEXITCODE -ne 0) {
    throw "TSTSS_INSTALLER_NSIS_FAILED:$LASTEXITCODE"
}
if (-not (Test-Path -LiteralPath $Installer -PathType Leaf) -or
    (Get-Item -LiteralPath $Installer).Length -lt 1000000) {
    throw "TSTSS_INSTALLER_SETUP_MISSING_OR_TRUNCATED"
}
$sourceSha = (& git -C $Repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) { throw "TSTSS_INSTALLER_SOURCE_BINDING_FAILED" }
$items = @($GameExe, $Installer)
$lines = @()
foreach ($file in $items) {
    $hash = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines += "$hash  $([IO.Path]::GetFileName($file))"
}
$lines | Set-Content -LiteralPath $Manifest -Encoding ascii
Write-Host "TSTSS_INSTALLER_SOURCE_SHA=$sourceSha"
Write-Host "TSTSS_INSTALLER_GODOT_EXE=$GameExe"
Write-Host "TSTSS_INSTALLER_SETUP=$Installer"
Write-Host "TSTSS_INSTALLER_SHA256=$((Get-FileHash -LiteralPath $Installer -Algorithm SHA256).Hash.ToLowerInvariant())"
Write-Host "TSTSS_INSTALLER_FUNCTIONAL_BUILD_PASS"
Write-Host "TSTSS_INSTALLER_DEFENDER_CUSTODY=NOT_ESTABLISHED"
Write-Host "TSTSS_INSTALLER_AUTHENTICODE_SIGNING=NOT_ESTABLISHED"
Write-Host "TSTSS_INSTALLER_PUBLIC_RELEASE_AUTHORIZED=NO"
