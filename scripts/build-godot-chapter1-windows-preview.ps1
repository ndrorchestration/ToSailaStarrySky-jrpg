param(
    [Parameter(Mandatory=$true)]
    [string]$GodotExe,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
function Get-Sha256Hex([string]$Path) {
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        return (($sha.ComputeHash($stream) | ForEach-Object ToString x2) -join '')
    }
    finally {
        $stream.Dispose()
    }
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$GodotDir = Join-Path $RepoRoot "godot"
if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "build\godot-first-wake"
}
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$Exe = Join-Path $OutputDir "Aetherwake-First-Wake-Godot-Preview.exe"

if (-not (Test-Path -LiteralPath $GodotExe)) {
    throw "GODOT_EDITOR_NOT_FOUND: $GodotExe"
}

$TemplateDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$ReleaseTemplate = Join-Path $TemplateDir "windows_release_x86_64.exe"
if (-not (Test-Path -LiteralPath $ReleaseTemplate)) {
    throw "GODOT_4_7_2_WINDOWS_EXPORT_TEMPLATE_NOT_FOUND: $ReleaseTemplate"
}

function Invoke-GodotChecked {
    param([string[]]$Arguments, [string]$Label)
    & $GodotExe @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--editor", "--quit") "Godot import"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_content_test.gd") "Chapter I content contract"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_dialogue_test.gd") "Chapter I dialogue cursor"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_state_test.gd") "Chapter I state contract"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_save_codec_test.gd") "Chapter I save codec"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_save_scene_test.gd") "Chapter I save scene"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_review_test.gd") "Chapter I review scene"
Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--script", "res://tests/first_wake_chapter1_export_contract.gd") "Windows export contract"

if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

Invoke-GodotChecked @("--headless", "--path", $GodotDir, "--export-release", "Windows Desktop Review", $Exe) "Windows release export"

# Godot can return immediately before the exported file becomes observable on
# Windows. Bound the handoff rather than treating a short filesystem delay as
# an export failure.
$ExportDeadline = (Get-Date).AddSeconds(10)
while (-not (Test-Path -LiteralPath $Exe) -and (Get-Date) -lt $ExportDeadline) {
    Start-Sleep -Milliseconds 200
}
if (-not (Test-Path -LiteralPath $Exe)) {
    throw "WINDOWS_EXPORT_MISSING: $Exe"
}
$Item = Get-Item -LiteralPath $Exe
if ($Item.Length -lt 1000000) {
    throw "WINDOWS_EXPORT_TOO_SMALL: $($Item.Length)"
}
$Sha = Get-Sha256Hex $Exe

Write-Output "AETHERWAKE_GODOT_WINDOWS_EXPORT_EXE=$Exe"
Write-Output "AETHERWAKE_GODOT_WINDOWS_EXPORT_BYTES=$($Item.Length)"
Write-Output "AETHERWAKE_GODOT_WINDOWS_EXPORT_SHA256=$Sha"
Write-Output "AETHERWAKE_GODOT_WINDOWS_EXPORT_PASS"
