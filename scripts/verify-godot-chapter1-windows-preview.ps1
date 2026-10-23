param(
    [Parameter(Mandatory=$true)]
    [string]$GodotExe,
    [Parameter(Mandatory=$true)]
    [string]$ExpectedSourceSha,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ExpectedGodotVersion = "4.7.2.stable.official.ed1daf0bf"

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

function Invoke-GodotCaptureChecked([string[]]$Arguments, [string]$Label, [string]$LogPath) {
    $PreviousErrorActionPreference = $ErrorActionPreference
    $HadNativePreference = Test-Path Variable:PSNativeCommandUseErrorActionPreference
    if ($HadNativePreference) {
        $PreviousNativePreference = $PSNativeCommandUseErrorActionPreference
        $PSNativeCommandUseErrorActionPreference = $false
    }
    $ErrorActionPreference = "Continue"
    try {
        $lines = @(& $GodotExe @Arguments 2>&1 | ForEach-Object { "$_" })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $PreviousErrorActionPreference
        if ($HadNativePreference) {
            $PSNativeCommandUseErrorActionPreference = $PreviousNativePreference
        }
    }
    $lines | Set-Content -LiteralPath $LogPath -Encoding UTF8
    if ($exitCode -ne 0) {
        throw "$Label failed with exit code $exitCode; log=$LogPath"
    }
    return $lines
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
$GodotDir = Join-Path $RepoRoot "godot"

Assert-Exists $GodotExe "Godot editor"
$GodotVersionLog = Join-Path $env:TEMP "aetherwake-godot-version-$PID.txt"
try {
    $GodotVersionLines = @(Invoke-GodotCaptureChecked @("--version") "Godot version check" $GodotVersionLog)
    $GodotVersion = (($GodotVersionLines -join [Environment]::NewLine).Trim())
}
finally {
    Remove-Item -LiteralPath $GodotVersionLog -Force -ErrorAction SilentlyContinue
}
if ($GodotVersion -ne $ExpectedGodotVersion) {
    throw "GODOT_VERSION_MISMATCH expected=$ExpectedGodotVersion actual=$GodotVersion"
}
$GodotExeSha = Get-Sha256Hex $GodotExe

$TemplateDir = Join-Path $env:APPDATA "Godot\export_templates\4.7.2.stable"
$ReleaseTemplate = Join-Path $TemplateDir "windows_release_x86_64.exe"
$TemplateVersionFile = Join-Path $TemplateDir "version.txt"
Assert-Exists $ReleaseTemplate "Godot 4.7.2 Windows release template"
Assert-Exists $TemplateVersionFile "Godot 4.7.2 template version file"
$ReleaseTemplateSha = Get-Sha256Hex $ReleaseTemplate
$TemplateVersionText = (Get-Content -LiteralPath $TemplateVersionFile -Raw).Trim()

if ($ExpectedSourceSha -notmatch '^[0-9a-f]{40}
    if ($LASTEXITCODE -ne 0 -or $HeadSha -notmatch '^[0-9a-f]{40}$') {
        throw "GIT_HEAD_UNAVAILABLE"
    }
    if ($HeadSha -ne $ExpectedSourceSha) {
        throw "SOURCE_SHA_MISMATCH expected=$ExpectedSourceSha actual=$HeadSha"
    }

    $TrackedDirty = @(& git status --porcelain --untracked-files=no)
    if ($LASTEXITCODE -ne 0) {
        throw "GIT_STATUS_FAILED"
    }
    if ($TrackedDirty.Count -gt 0) {
        throw "TRACKED_WORKTREE_NOT_CLEAN"
    }

    $UntrackedGodot = @(& git ls-files --others --exclude-standard -- godot)
    if ($LASTEXITCODE -ne 0) {
        throw "GIT_UNTRACKED_GODOT_SCAN_FAILED"
    }
    if ($UntrackedGodot.Count -gt 0) {
        throw "UNTRACKED_GODOT_AUTHORITY_FILES"
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
$RenderDir = Join-Path $OutputDir "render-evidence"
$RenderLog = Join-Path $OutputDir "chapter1-native-render.log"
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
$ExportedExeSha = Get-Sha256Hex $ExportedExe

$PreviousCaptureOutput = $env:AETHERWAKE_CAPTURE_OUTPUT_DIR
$env:AETHERWAKE_CAPTURE_OUTPUT_DIR = $RenderDir
try {
    $RenderLines = @(Invoke-GodotCaptureChecked @(
        "--path", $GodotDir,
        "--rendering-method", "gl_compatibility",
        "--script", "res://tests/capture_first_wake_chapter1_review.gd"
    ) "native Chapter I renderer" $RenderLog)
}
finally {
    if ($null -eq $PreviousCaptureOutput) {
        Remove-Item Env:AETHERWAKE_CAPTURE_OUTPUT_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:AETHERWAKE_CAPTURE_OUTPUT_DIR = $PreviousCaptureOutput
    }
}
$RenderText = $RenderLines -join [Environment]::NewLine
if ($RenderText -notmatch "AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS") {
    throw "NATIVE_RENDER_PASS_MARKER_MISSING log=$RenderLog"
}
if ($RenderText -notmatch "AETHERWAKE_GODOT_CHAPTER1_ARTISTIC_ACCEPTANCE=PENDING") {
    throw "NATIVE_RENDER_ACCEPTANCE_BOUNDARY_MISSING log=$RenderLog"
}

$ExpectedRenderFiles = @(
    "chapter1-signal-native-960x640.png",
    "chapter1-formula-review-native-960x640.png",
    "chapter1-dialogue-native-960x640.png",
    "chapter1-crossing-native-960x640.png",
    "chapter1-wind-shear-combat-native-960x640.png",
    "chapter1-contact-native-960x640.png",
    "chapter1-choice-native-960x640.png",
    "chapter1-wake-native-960x640.png",
    "chapter1-done-native-960x640.png"
)
$RenderHashes = [ordered]@{}
foreach ($RenderName in $ExpectedRenderFiles) {
    $RenderPath = Join-Path $RenderDir $RenderName
    Assert-Exists $RenderPath "native render frame $RenderName"
    $RenderHashes[$RenderName] = Get-Sha256Hex $RenderPath
}

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

$Readme = Join-Path $Staging "README-FIRST.txt"
$Manifest = Join-Path $Staging "SHA256SUMS.txt"
Assert-Exists $Readme "package README"
Assert-Exists $Manifest "package hash manifest"

$PayloadExeItem = Get-Item -LiteralPath $PayloadExe
$ZipItem = Get-Item -LiteralPath $Zip
$ExeSha = Get-Sha256Hex $PayloadExe
$ZipSha = Get-Sha256Hex $Zip
if ($ExportedExeSha -ne $ExeSha) {
    throw "EXPORTED_TO_PACKAGED_EXE_HASH_MISMATCH exported=$ExportedExeSha packaged=$ExeSha"
}
$InstallCmdSha = Get-Sha256Hex $InstallCmd
$UninstallCmdSha = Get-Sha256Hex $UninstallCmd
$ReadmeSha = Get-Sha256Hex $Readme
$ManifestSha = Get-Sha256Hex $Manifest

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
foreach ($residuePath in @($DesktopShortcut, $StartMenuDir, $TempCleanup)) {
    if (Test-Path -LiteralPath $residuePath) {
        throw "PREEXISTING_NATIVE_PREVIEW_RESIDUE:$residuePath"
    }
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

$InstalledExeSha = Get-Sha256Hex $InstalledExe
if ($InstalledExeSha -ne $ExeSha) {
    throw "INSTALLED_EXE_HASH_MISMATCH packaged=$ExeSha installed=$InstalledExeSha"
}
$InstalledUninstallSha = Get-Sha256Hex $InstalledUninstall
if ($InstalledUninstallSha -ne $UninstallCmdSha) {
    throw "INSTALLED_UNINSTALLER_HASH_MISMATCH packaged=$UninstallCmdSha installed=$InstalledUninstallSha"
}

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

Push-Location $RepoRoot
try {
    $TrackedDirty = @(& git status --porcelain --untracked-files=no)
    if ($LASTEXITCODE -ne 0) {
        throw "FINAL_GIT_STATUS_FAILED"
    }
    if ($TrackedDirty.Count -gt 0) {
        throw "TRACKED_SOURCE_CHANGED_DURING_QA"
    }
}
finally {
    Pop-Location
}

$ReceiptPath = Join-Path $OutputDir "WINDOWS_NATIVE_QA_RECEIPT.json"

$Receipt = [ordered]@{
    sourceSha = $HeadSha
    verifiedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    godotExe = [System.IO.Path]::GetFullPath($GodotExe)
    godotVersion = $GodotVersion
    godotExeSha256 = $GodotExeSha
    windowsReleaseTemplate = [System.IO.Path]::GetFullPath($ReleaseTemplate)
    windowsReleaseTemplateSha256 = $ReleaseTemplateSha
    templateVersionText = $TemplateVersionText
    render = [ordered]@{
        method = "gl_compatibility"
        log = [System.IO.Path]::GetFullPath($RenderLog)
        pass = "PASS"
        artisticAcceptance = "PENDING"
        frameSha256 = $RenderHashes
    }
    exportedExe = [System.IO.Path]::GetFullPath($ExportedExe)
    exportedExeSha256 = $ExportedExeSha
    packagedExe = [System.IO.Path]::GetFullPath($PayloadExe)
    packagedExeBytes = [int64]$PayloadExeItem.Length
    packagedExeSha256 = $ExeSha
    installWrapperSha256 = $InstallCmdSha
    uninstallWrapperSha256 = $UninstallCmdSha
    packageReadmeSha256 = $ReadmeSha
    packageManifestSha256 = $ManifestSha
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
        installedExeHashMatch = "PASS"
        installedUninstallerHashMatch = "PASS"
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

$MarkdownReceiptPath = Join-Path $OutputDir "WINDOWS_NATIVE_QA_RECEIPT.md"
$RenderReceiptLines = @(
    $ExpectedRenderFiles |
        ForEach-Object { "- $_ : $($RenderHashes[$_])" }
)
$MarkdownReceipt = @(
    "# Aetherwake First Wake native Windows QA receipt",
    "",
    "Source SHA: $HeadSha",
    "Verified UTC: $($Receipt.verifiedAtUtc)",
    "Public release authorized: NO",
    "",
    "## Toolchain",
    "- Godot: $GodotVersion",
    "- Godot executable SHA-256: $GodotExeSha",
    "- Windows release template SHA-256: $ReleaseTemplateSha",
    "- Template version text: $TemplateVersionText",
    "",
    "## Native render gate",
    "- Rendering method: gl_compatibility",
    "- Frame count: $($ExpectedRenderFiles.Count)",
    "- Artistic acceptance: PENDING",
    $RenderReceiptLines,
    "",
    "## Package custody",
    "- Exported EXE SHA-256: $ExportedExeSha",
    "- Packaged EXE SHA-256: $ExeSha",
    "- ZIP SHA-256: $ZipSha",
    "- Install wrapper SHA-256: $InstallCmdSha",
    "- Uninstall wrapper SHA-256: $UninstallCmdSha",
    "- README SHA-256: $ReadmeSha",
    "- Manifest SHA-256: $ManifestSha",
    "",
    "## Windows verification",
    "- Defender custom scans: PASS (installer / uninstaller / packaged EXE / ZIP)",
    "- Per-user install: PASS",
    "- Installed EXE byte identity: PASS",
    "- Installed uninstaller byte identity: PASS",
    "- Live native window: PASS - $MainWindowTitle",
    "- Desktop shortcut: PASS",
    "- Start Menu shortcut: PASS",
    "- Running-app uninstall: PASS",
    "- Cleanup: PASS",
    "- Final tracked-source integrity: PASS",
    "",
    "## Boundary",
    "This receipt is private engineering evidence only. It does not establish creator visual acceptance, independent player acceptance, issue #293 disposition, merge authorization, or public release authorization."
) -join [Environment]::NewLine
Set-Content -LiteralPath $MarkdownReceiptPath -Value $MarkdownReceipt -Encoding UTF8

Write-Output "AETHERWAKE_GODOT_EXACT_QA_SOURCE=$HeadSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_VERSION=$GodotVersion"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_GODOT_SHA256=$GodotExeSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_TEMPLATE_SHA256=$ReleaseTemplateSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RENDER_FRAMES=$($ExpectedRenderFiles.Count)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_BYTES=$($PayloadExeItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_SHA256=$ExeSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_BYTES=$($ZipItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_SHA256=$ZipSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RECEIPT=$ReceiptPath"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RECEIPT_MD=$MarkdownReceiptPath"
Write-Output "AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS"
) {
    throw "EXPECTED_SOURCE_SHA_INVALID:$ExpectedSourceSha"
}

Push-Location $RepoRoot
try {
    $HeadSha = (& git rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $HeadSha -notmatch '^[0-9a-f]{40}$') {
        throw "GIT_HEAD_UNAVAILABLE"
    }
    if ($HeadSha -ne $ExpectedSourceSha) {
        throw "SOURCE_SHA_MISMATCH expected=$ExpectedSourceSha actual=$HeadSha"
    }

    $TrackedDirty = @(& git status --porcelain --untracked-files=no)
    if ($LASTEXITCODE -ne 0) {
        throw "GIT_STATUS_FAILED"
    }
    if ($TrackedDirty.Count -gt 0) {
        throw "TRACKED_WORKTREE_NOT_CLEAN"
    }

    $UntrackedGodot = @(& git ls-files --others --exclude-standard -- godot)
    if ($LASTEXITCODE -ne 0) {
        throw "GIT_UNTRACKED_GODOT_SCAN_FAILED"
    }
    if ($UntrackedGodot.Count -gt 0) {
        throw "UNTRACKED_GODOT_AUTHORITY_FILES"
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
$RenderDir = Join-Path $OutputDir "render-evidence"
$RenderLog = Join-Path $OutputDir "chapter1-native-render.log"
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
$ExportedExeSha = Get-Sha256Hex $ExportedExe

$PreviousCaptureOutput = $env:AETHERWAKE_CAPTURE_OUTPUT_DIR
$env:AETHERWAKE_CAPTURE_OUTPUT_DIR = $RenderDir
try {
    $RenderLines = @(Invoke-GodotCaptureChecked @(
        "--path", $GodotDir,
        "--rendering-method", "gl_compatibility",
        "--script", "res://tests/capture_first_wake_chapter1_review.gd"
    ) "native Chapter I renderer" $RenderLog)
}
finally {
    if ($null -eq $PreviousCaptureOutput) {
        Remove-Item Env:AETHERWAKE_CAPTURE_OUTPUT_DIR -ErrorAction SilentlyContinue
    }
    else {
        $env:AETHERWAKE_CAPTURE_OUTPUT_DIR = $PreviousCaptureOutput
    }
}
$RenderText = $RenderLines -join [Environment]::NewLine
if ($RenderText -notmatch "AETHERWAKE_GODOT_CHAPTER1_NATIVE_RENDER_PASS") {
    throw "NATIVE_RENDER_PASS_MARKER_MISSING log=$RenderLog"
}
if ($RenderText -notmatch "AETHERWAKE_GODOT_CHAPTER1_ARTISTIC_ACCEPTANCE=PENDING") {
    throw "NATIVE_RENDER_ACCEPTANCE_BOUNDARY_MISSING log=$RenderLog"
}

$ExpectedRenderFiles = @(
    "chapter1-signal-native-960x640.png",
    "chapter1-formula-review-native-960x640.png",
    "chapter1-dialogue-native-960x640.png",
    "chapter1-crossing-native-960x640.png",
    "chapter1-wind-shear-combat-native-960x640.png",
    "chapter1-contact-native-960x640.png",
    "chapter1-choice-native-960x640.png",
    "chapter1-wake-native-960x640.png",
    "chapter1-done-native-960x640.png"
)
$RenderHashes = [ordered]@{}
foreach ($RenderName in $ExpectedRenderFiles) {
    $RenderPath = Join-Path $RenderDir $RenderName
    Assert-Exists $RenderPath "native render frame $RenderName"
    $RenderHashes[$RenderName] = Get-Sha256Hex $RenderPath
}

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

$Readme = Join-Path $Staging "README-FIRST.txt"
$Manifest = Join-Path $Staging "SHA256SUMS.txt"
Assert-Exists $Readme "package README"
Assert-Exists $Manifest "package hash manifest"

$PayloadExeItem = Get-Item -LiteralPath $PayloadExe
$ZipItem = Get-Item -LiteralPath $Zip
$ExeSha = Get-Sha256Hex $PayloadExe
$ZipSha = Get-Sha256Hex $Zip
if ($ExportedExeSha -ne $ExeSha) {
    throw "EXPORTED_TO_PACKAGED_EXE_HASH_MISMATCH exported=$ExportedExeSha packaged=$ExeSha"
}
$InstallCmdSha = Get-Sha256Hex $InstallCmd
$UninstallCmdSha = Get-Sha256Hex $UninstallCmd
$ReadmeSha = Get-Sha256Hex $Readme
$ManifestSha = Get-Sha256Hex $Manifest

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
foreach ($residuePath in @($DesktopShortcut, $StartMenuDir, $TempCleanup)) {
    if (Test-Path -LiteralPath $residuePath) {
        throw "PREEXISTING_NATIVE_PREVIEW_RESIDUE:$residuePath"
    }
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

$InstalledExeSha = Get-Sha256Hex $InstalledExe
if ($InstalledExeSha -ne $ExeSha) {
    throw "INSTALLED_EXE_HASH_MISMATCH packaged=$ExeSha installed=$InstalledExeSha"
}
$InstalledUninstallSha = Get-Sha256Hex $InstalledUninstall
if ($InstalledUninstallSha -ne $UninstallCmdSha) {
    throw "INSTALLED_UNINSTALLER_HASH_MISMATCH packaged=$UninstallCmdSha installed=$InstalledUninstallSha"
}

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

Push-Location $RepoRoot
try {
    $TrackedDirty = @(& git status --porcelain --untracked-files=no)
    if ($LASTEXITCODE -ne 0) {
        throw "FINAL_GIT_STATUS_FAILED"
    }
    if ($TrackedDirty.Count -gt 0) {
        throw "TRACKED_SOURCE_CHANGED_DURING_QA"
    }
}
finally {
    Pop-Location
}

$ReceiptPath = Join-Path $OutputDir "WINDOWS_NATIVE_QA_RECEIPT.json"

$Receipt = [ordered]@{
    sourceSha = $HeadSha
    verifiedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    godotExe = [System.IO.Path]::GetFullPath($GodotExe)
    godotVersion = $GodotVersion
    godotExeSha256 = $GodotExeSha
    windowsReleaseTemplate = [System.IO.Path]::GetFullPath($ReleaseTemplate)
    windowsReleaseTemplateSha256 = $ReleaseTemplateSha
    templateVersionText = $TemplateVersionText
    render = [ordered]@{
        method = "gl_compatibility"
        log = [System.IO.Path]::GetFullPath($RenderLog)
        pass = "PASS"
        artisticAcceptance = "PENDING"
        frameSha256 = $RenderHashes
    }
    exportedExe = [System.IO.Path]::GetFullPath($ExportedExe)
    exportedExeSha256 = $ExportedExeSha
    packagedExe = [System.IO.Path]::GetFullPath($PayloadExe)
    packagedExeBytes = [int64]$PayloadExeItem.Length
    packagedExeSha256 = $ExeSha
    installWrapperSha256 = $InstallCmdSha
    uninstallWrapperSha256 = $UninstallCmdSha
    packageReadmeSha256 = $ReadmeSha
    packageManifestSha256 = $ManifestSha
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
        installedExeHashMatch = "PASS"
        installedUninstallerHashMatch = "PASS"
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
Write-Output "AETHERWAKE_GODOT_EXACT_QA_VERSION=$GodotVersion"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_GODOT_SHA256=$GodotExeSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_TEMPLATE_SHA256=$ReleaseTemplateSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RENDER_FRAMES=$($ExpectedRenderFiles.Count)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_BYTES=$($PayloadExeItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_EXE_SHA256=$ExeSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_BYTES=$($ZipItem.Length)"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_ZIP_SHA256=$ZipSha"
Write-Output "AETHERWAKE_GODOT_EXACT_QA_RECEIPT=$ReceiptPath"
Write-Output "AETHERWAKE_GODOT_EXACT_WINDOWS_PACKAGE_QA=PASS"
