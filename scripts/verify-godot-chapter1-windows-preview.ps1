param(
    [Parameter(Mandatory=$true)]
    [string]$GodotExe,
    [Parameter(Mandatory=$true)]
    [string]$ExpectedSourceSha,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

function Assert-Exists([string]$Path, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Label missing: $Path"
    }
}

function Assert-DefenderCustomScan([string]$Path, [string]$Label) {
    Assert-Exists $Path $Label
    if (-not (Get-Command Start-MpScan -ErrorAction SilentlyContinue)) {
        throw "DEFENDER_START_MPSCAN_UNAVAILABLE"
    }
    if (-not (Get-Command Get-MpThreatDetection -ErrorAction SilentlyContinue)) {
        throw "DEFENDER_GET_THREAT_DETECTION_UNAVAILABLE"
    }

    $scanStarted = Get-Date
    Start-MpScan -ScanType CustomScan -ScanPath $Path -ErrorAction Stop
    Start-Sleep -Milliseconds 750

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $detections = @(
        Get-MpThreatDetection -ErrorAction Stop |
            Where-Object {
                $detectedAt = $_.InitialDetectionTime
                if ($null -eq $detectedAt -or $detectedAt -lt $scanStarted.AddSeconds(-5)) {
                    return $false
                }
                $resourcesText = (@($_.Resources) -join [Environment]::NewLine)
                return $resourcesText.IndexOf(
                    $fullPath,
                    [System.StringComparison]::OrdinalIgnoreCase
                ) -ge 0
            }
    )
    if ($detections.Count -gt 0) {
        throw "DEFENDER_DETECTION_FOR_$Label"
    }
    Assert-Exists $Path "$Label after Defender scan"
    Write-Output "DEFENDER_SCAN_$Label=PASS"
}

function Invoke-CmdChecked([string]$CmdPath, [string]$Label) {
    Assert-Exists $CmdPath $Label
    $quoted = '"' + $CmdPath + '"'
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList @("/d", "/c", $quoted) -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "$Label failed with exit code $($process.ExitCode)"
    }
}

function Find-ExactExecutableProcess([string]$ExecutablePath) {
    $exact = [System.IO.Path]::GetFullPath($ExecutablePath)
    return @(
        Get-CimInstance Win32_Process -ErrorAction Stop |
            Where-Object {
                $_.ExecutablePath -and
                [System.IO.Path]::GetFullPath([string]$_.ExecutablePath).Equals(
                    $exact,
                    [System.StringComparison]::OrdinalIgnoreCase
                )
            }
    )
}

$RepoRoot = Split-Path -Parent $PSScriptRoot
$RepoRoot = [System.IO.Path]::GetFullPath($RepoRoot)

Push-Location $RepoRoot
try {
    $HeadSha = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $HeadSha -notmatch '^[0-9a-f]{40}$') {
        throw "GIT_HEAD_UNAVAILABLE"
    }
    if ($HeadSha -ne $ExpectedSourceSha) {
        throw "SOURCE_SHA_MISMATCH expected=$ExpectedSourceSha actual=$HeadSha"
    }

    $Dirty = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        throw "GIT_STATUS_FAILED"
    }
    if ($Dirty.Count -gt 0) {
        throw "WORKTREE_NOT_CLEAN"
    }
}
finally {
    Pop-Location
}

if (-not $OutputDir) {
    $OutputDir = Join-Path $RepoRoot "build\godot-first-wake-exact-qa"
}
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$ExportDir = Join-Path $OutputDir "export"
$PackageDir = Join-Path $OutputDir "package"
$BuildScript = Join-Path $RepoRoot "scripts\build-godot-chapter1-windows-preview.ps1"
$PackageScript = Join-Path $RepoRoot "scripts\package-godot-chapter1-windows-preview.ps1"

if (Test-Path -LiteralPath $OutputDir) {
    Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

& $BuildScript -GodotExe $GodotExe -OutputDir $ExportDir
if ($LASTEXITCODE -ne 0) {
    throw "GODOT_BUILD_GATE_FAILED:$LASTEXITCODE"
}

$ExportedExe = Join-Path $ExportDir "Aetherwake-First-Wake-Godot-Preview.exe"
Assert-Exists $ExportedExe "exported Godot preview"

& $PackageScript -ExportedExe $ExportedExe -OutputDir $PackageDir
if ($LASTEXITCODE -ne 0) {
    throw "GODOT_PACKAGE_GATE_FAILED:$LASTEXITCODE"
}

$Staging = Join-Path $PackageDir "staging"
$PayloadExe = Join-Path $Staging "Aetherwake\Aetherwake-First-Wake-Godot-Preview.exe"
$InstallCmd = Join-Path $Staging "Install-Aetherwake-Godot-Preview.cmd"
$UninstallCmd = Join-Path $Staging "Uninstall-Aetherwake-Godot-Preview.cmd"
$Zip = Join-Path $PackageDir "Aetherwake-First-Wake-Godot-Native-Preview-Windows.zip"

Assert-DefenderCustomScan $InstallCmd "INSTALL_WRAPPER"
Assert-DefenderCustomScan $UninstallCmd "UNINSTALL_WRAPPER"
Assert-DefenderCustomScan $PayloadExe "PACKAGED_EXE"
Assert-DefenderCustomScan $Zip "ZIP"

$InstallDir = Join-Path $env:LOCALAPPDATA "Programs\Aetherwake-Godot-Native-Preview"
$InstalledExe = Join-Path $InstallDir "Aetherwake-First-Wake-Godot-Preview.exe"
$InstalledUninstall = Join-Path $InstallDir "Uninstall-Aetherwake-Godot-Preview.cmd"
$DesktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "Aetherwake Native Preview.lnk"
$StartMenuDir = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Aetherwake Native Preview"
$StartMenuShortcut = Join-Path $StartMenuDir "Aetherwake Native Preview.lnk"
$TempCleanup = Join-Path $env:TEMP "Aetherwake-Godot-Native-Preview-Uninstall.cmd"

if (Test-Path -LiteralPath $InstallDir) {
    throw "PREEXISTING_NATIVE_PREVIEW_INSTALL:$InstallDir"
}
if ((Find-ExactExecutableProcess $InstalledExe).Count -gt 0) {
    throw "PREEXISTING_NATIVE_PREVIEW_PROCESS"
}

Invoke-CmdChecked $InstallCmd "native preview installer"

$LaunchDeadline = (Get-Date).AddSeconds(20)
$Running = @()
while ((Get-Date) -lt $LaunchDeadline) {
    $Running = @(Find-ExactExecutableProcess $InstalledExe)
    if ($Running.Count -gt 0) {
        break
    }
    Start-Sleep -Milliseconds 250
}
if ($Running.Count -ne 1) {
    throw "INSTALLED_NATIVE_PREVIEW_PROCESS_NOT_READY"
}

Assert-Exists $InstalledExe "installed executable"
Assert-Exists $InstalledUninstall "installed uninstaller"
Assert-Exists $DesktopShortcut "Desktop shortcut"
Assert-Exists $StartMenuShortcut "Start Menu shortcut"

$WindowDeadline = (Get-Date).AddSeconds(10)
$MainWindowReady = $false
$MainWindowTitle = ""
while ((Get-Date) -lt $WindowDeadline) {
    $Process = Get-Process -Id ([int]$Running[0].ProcessId) -ErrorAction SilentlyContinue
    if ($null -ne $Process) {
        $Process.Refresh()
        $MainWindowTitle = [string]$Process.MainWindowTitle
        if ($Process.MainWindowHandle -ne 0 -and $MainWindowTitle -like "*Aetherwake*") {
            $MainWindowReady = $true
            break
        }
    }
    Start-Sleep -Milliseconds 250
}
if (-not $MainWindowReady) {
    throw "INSTALLED_NATIVE_PREVIEW_WINDOW_NOT_READY title=$MainWindowTitle"
}

Invoke-CmdChecked $InstalledUninstall "running-app native preview uninstaller"

$CleanupDeadline = (Get-Date).AddSeconds(20)
while ((Get-Date) -lt $CleanupDeadline) {
    $StillRunning = @(Find-ExactExecutableProcess $InstalledExe)
    if (
        $StillRunning.Count -eq 0 -and
        -not (Test-Path -LiteralPath $InstallDir) -and
        -not (Test-Path -LiteralPath $DesktopShortcut) -and
        -not (Test-Path -LiteralPath $StartMenuDir) -and
        -not (Test-Path -LiteralPath $TempCleanup)
    ) {
        break
    }
    Start-Sleep -Milliseconds 250
}

if ((Find-ExactExecutableProcess $InstalledExe).Count -gt 0) {
    throw "UNINSTALL_LEFT_NATIVE_PREVIEW_PROCESS"
}
if (Test-Path -LiteralPath $InstallDir) {
    throw "UNINSTALL_LEFT_INSTALL_DIRECTORY"
}
if (Test-Path -LiteralPath $DesktopShortcut) {
    throw "UNINSTALL_LEFT_DESKTOP_SHORTCUT"
}
if (Test-Path -LiteralPath $StartMenuDir) {
    throw "UNINSTALL_LEFT_START_MENU_SHORTCUT"
}
if (Test-Path -LiteralPath $TempCleanup) {
    throw "UNINSTALL_LEFT_TEMP_CLEANUP_COPY"
}

$ExeItem = Get-Item -LiteralPath $PayloadExe
$ZipItem = Get-Item -LiteralPath $Zip
$ExeSha = Get-Sha256Hex $PayloadExe
$ZipSha = Get-Sha256Hex $Zip
$ReceiptPath = Join-Path $OutputDir "WINDOWS_NATIVE_QA_RECEIPT.json"

$Receipt = [ordered]@{
    sourceSha = $HeadSha
    verifiedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    godotExe = [System.IO.Path]::GetFullPath($GodotExe)
    exportedExe = [System.IO.Path]::GetFullPath($ExportedExe)
    packagedExe = [System.IO.Path]::GetFullPath($PayloadExe)
    packagedExeBytes = [int64]$ExeItem.Length
    packagedExeSha256 = $ExeSha
    zip = [System.IO.Path]::GetFullPath($Zip)
    zipBytes = [int64]$ZipItem.Length
    zipSha256 = $ZipSha
    defender = [ordered]@{
        installWrapper = "PASS"
        uninstallWrapper = "PASS"
        packagedExe = "PASS"
        zip = "PASS"
    }
    install = [ordered]@{
        perUser = "PASS"
        liveLaunch = "PASS"
        windowTitle = $MainWindowTitle
        desktopShortcut = "PASS"
        startMenuShortcut = "PASS"
        runningAppUninstall = "PASS"
        cleanup = "PASS"
    }
    publicReleaseAuthorized = $false
}

$Receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $ReceiptPath -Encoding UTF8

Write-Output "AETHERWAKE_GODOT_EXACT_QA_SOURCE=$HeadSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_BYTES=$($ExeItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_SHA256=$ExeSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_BYTES=$($ZipItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_SHA256=$ZipSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RECEIPT=$ReceiptPath"
Write-Output "AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS"
