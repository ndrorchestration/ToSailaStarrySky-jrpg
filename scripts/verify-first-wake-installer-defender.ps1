# First Wake native Windows installer security custody.
# Runs on a trusted, already-Defender-on Windows host, not on a disabled hosted VM.
# Validates this exact compiled NSIS setup and embedded Godot game binary.
# Does not sign or publish binaries, modify Defender settings, or accept scan failures.
param(
    [Parameter(Mandatory=$true)][string]$SetupExe,
    [Parameter(Mandatory=$true)][string]$GameExe,
    [Parameter(Mandatory=$true)][string]$ExpectedSourceSha,
    [string]$OutputDir = ""
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Assert-DefenderReady {
    foreach ($command in @("Get-MpComputerStatus", "Get-MpPreference", "Start-MpScan", "Get-MpThreatDetection", "Get-WinEvent")) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
            throw "TSTSS_DEFENDER_COMMAND_MISSING:$command"
        }
    }
    $status = Get-MpComputerStatus -ErrorAction Stop
    if (-not [bool]$status.AntivirusEnabled -or -not [bool]$status.RealTimeProtectionEnabled) {
        throw "TSTSS_DEFENDER_REALTIME_NOT_ENABLED"
    }
    $rootExclusions = @((Get-MpPreference -ErrorAction Stop).ExclusionPath |
        Where-Object { $null -ne $_ -and [string]$_ -match '^[A-Za-z]:[/\\]?$' })
    if ($rootExclusions.Count -gt 0) {
        throw "TSTSS_DEFENDER_WHOLE_DRIVE_EXCLUDED"
    }
    $null = Get-WinEvent -ListLog "Microsoft-Windows-Windows Defender/Operational" -ErrorAction Stop
    return $status
}

# Existing exclusions must not make our exact game/setup binaries unscannable.
# A scan completion event alone is insufficient if the object is excluded.
function Assert-NoTargetExclusions([string[]]$TargetFiles) {
    $prefs = Get-MpPreference -ErrorAction Stop
    $names = @($TargetFiles | ForEach-Object { [IO.Path]::GetFileName($_) })
    foreach ($extension in @($prefs.ExclusionExtension)) {
        if ($null -eq $extension) { continue }
        $text = ([string]$extension).Trim()
        if ($text.Contains("*") -or $text.Contains("?") -or
            $text.TrimStart(".").Equals("exe", [StringComparison]::OrdinalIgnoreCase)) {
            throw "TSTSS_DEFENDER_EXE_EXTENSION_EXCLUDED"
        }
    }
    foreach ($process in @($prefs.ExclusionProcess)) {
        if ($null -eq $process) { continue }
        $text = ([string]$process).Trim()
        if ($text.Contains("*") -or $text.Contains("?")) {
            throw "TSTSS_DEFENDER_AMBIGUOUS_PROCESS_EXCLUSION"
        }
        $fileName = [IO.Path]::GetFileName($text.Replace("/", "\"))
        foreach ($name in $names) {
            if ($fileName.Equals($name, [StringComparison]::OrdinalIgnoreCase)) {
                throw "TSTSS_DEFENDER_TARGET_PROCESS_EXCLUDED"
            }
        }
    }
    foreach ($exclusion in @($prefs.ExclusionPath)) {
        if ($null -eq $exclusion -or [string]::IsNullOrWhiteSpace([string]$exclusion)) { continue }
        $text = [Environment]::ExpandEnvironmentVariables(([string]$exclusion).Trim())
        if ($text.Contains("*") -or $text.Contains("?")) {
            throw "TSTSS_DEFENDER_AMBIGUOUS_PATH_EXCLUSION"
        }
        try {
            $path = [IO.Path]::GetFullPath($text).TrimEnd("\")
        } catch {
            throw "TSTSS_DEFENDER_INVALID_PATH_EXCLUSION"
        }
        foreach ($file in $TargetFiles) {
            $full = [IO.Path]::GetFullPath($file)
            if ($full.Equals($path, [StringComparison]::OrdinalIgnoreCase) -or
                $full.StartsWith($path + "\", [StringComparison]::OrdinalIgnoreCase)) {
                throw "TSTSS_DEFENDER_TARGET_PATH_EXCLUDED"
            }
        }
    }
}

function Get-DefenderField([System.Diagnostics.Eventing.Reader.EventRecord]$Event, [string]$Key) {
    [xml]$xml = $Event.ToXml()
    foreach ($item in @($xml.Event.EventData.Data)) {
        if ([string]$item.GetAttribute("Name") -eq $Key) {
            return [string]$item.InnerText
        }
    }
    return ""
}

function Get-ScanEvents([datetime]$StartTime) {
    return @(Get-WinEvent -FilterHashtable @{
        LogName = "Microsoft-Windows-Windows Defender/Operational"
        Id = @(1000, 1001, 1002)
        StartTime = $StartTime
    } -ErrorAction SilentlyContinue)
}

function Invoke-ExactDefenderScan([string]$Path, [string]$Label) {
    $full = [IO.Path]::GetFullPath($Path)
    $hashBefore = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
    $previous = Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 1 -ErrorAction SilentlyContinue
    $previousRecord = if ($null -eq $previous) { [long]0 } else { [long]$previous.RecordId }
    $lookback = (Get-Date).AddSeconds(-5)
    Start-MpScan -ScanType CustomScan -ScanPath $full -ErrorAction Stop

    $start = $null
    $scanId = ""
    $startDeadline = (Get-Date).AddSeconds(45)
    while ((Get-Date) -lt $startDeadline -and $null -eq $start) {
        foreach ($event in @(Get-ScanEvents $lookback)) {
            if ([long]$event.RecordId -le $previousRecord -or [int]$event.Id -ne 1000) { continue }
            $resources = Get-DefenderField $event "Scan Resources"
            if ($resources.IndexOf($full, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
            $scanId = Get-DefenderField $event "Scan ID"
            if ([string]::IsNullOrWhiteSpace($scanId)) { throw "TSTSS_DEFENDER_SCAN_ID_MISSING:$Label" }
            $start = $event
            break
        }
        if ($null -eq $start) { Start-Sleep -Milliseconds 300 }
    }
    if ($null -eq $start) { throw "TSTSS_DEFENDER_SCAN_START_NOT_ATTESTED:$Label" }

    $complete = $null
    $completeDeadline = (Get-Date).AddSeconds(180)
    while ((Get-Date) -lt $completeDeadline -and $null -eq $complete) {
        foreach ($event in @(Get-ScanEvents $lookback)) {
            if ([long]$event.RecordId -le $previousRecord -or [int]$event.Id -notin @(1001, 1002)) { continue }
            if ((Get-DefenderField $event "Scan ID") -ne $scanId) { continue }
            if ([int]$event.Id -eq 1002) { throw "TSTSS_DEFENDER_SCAN_CANCELLED:$Label" }
            $complete = $event
            break
        }
        if ($null -eq $complete) { Start-Sleep -Milliseconds 300 }
    }
    if ($null -eq $complete) { throw "TSTSS_DEFENDER_SCAN_COMPLETION_NOT_ATTESTED:$Label" }

    Start-Sleep -Milliseconds 750
    $detections = @(
        Get-MpThreatDetection -ErrorAction Stop |
        Where-Object {
            $when = $_.InitialDetectionTime
            $resourceText = @($_.Resources) -join [Environment]::NewLine
            $null -ne $when -and $when -ge $lookback -and
                $resourceText.IndexOf($full, [StringComparison]::OrdinalIgnoreCase) -ge 0
        }
    )
    if ($detections.Count -ne 0) { throw "TSTSS_DEFENDER_DETECTION:$Label" }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "TSTSS_DEFENDER_QUARANTINED_OR_MISSING:$Label"
    }
    $hashAfter = (Get-FileHash -LiteralPath $full -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hashAfter -ne $hashBefore) { throw "TSTSS_DEFENDER_SCAN_MODIFIED_BINARY:$Label" }
    $null = Assert-DefenderReady
    Write-Host "TSTSS_DEFENDER_SCAN_$Label=PASS"
    return [ordered]@{
        result = "PASS"
        label = $Label
        sha256 = $hashAfter
        scanId = $scanId
        scanStartEvent = [long]$start.RecordId
        scanCompletionEvent = [long]$complete.RecordId
        completionUtc = $complete.TimeCreated.ToUniversalTime().ToString("o")
        detections = 0
    }
}

if ($ExpectedSourceSha -cnotmatch '^[0-9a-f]{40}$') { throw "TSTSS_EXPECTED_SOURCE_SHA_INVALID" }
$repo = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$actualSha = (& git -C $repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $actualSha -cne $ExpectedSourceSha) {
    throw "TSTSS_EXACT_SOURCE_SHA_MISMATCH"
}
if (@(& git -C $repo status --porcelain --untracked-files=no).Count -gt 0) {
    throw "TSTSS_TRACKED_SOURCE_DIRTY"
}
foreach ($file in @($SetupExe, $GameExe)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "TSTSS_EXPECTED_BINARY_MISSING:$file"
    }
}
if (-not $OutputDir) { $OutputDir = Join-Path $env:TEMP "tstss-defender-proof" }
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$defender = Assert-DefenderReady
Assert-NoTargetExclusions @($GameExe, $SetupExe)
$gameResult = Invoke-ExactDefenderScan $GameExe "GAME"
$setupResult = Invoke-ExactDefenderScan $SetupExe "SETUP"
Assert-NoTargetExclusions @($GameExe, $SetupExe)
$gameSign = Get-AuthenticodeSignature -LiteralPath $GameExe
$setupSign = Get-AuthenticodeSignature -LiteralPath $SetupExe
$finalDefender = Assert-DefenderReady
$receipt = [ordered]@{
    schema = "TSTSS_WINDOWS_INSTALLER_DEFENDER_CUSTODY_V1"
    sourceSha = $actualSha
    defenderAntivirusEnabled = [bool]$finalDefender.AntivirusEnabled
    defenderRealtimeEnabled = [bool]$finalDefender.RealTimeProtectionEnabled
    defenderEngine = [string]$finalDefender.AMEngineVersion
    defenderSignatures = [string]$finalDefender.AntivirusSignatureVersion
    game = $gameResult
    installer = $setupResult
    gameAuthenticodeStatus = [string]$gameSign.Status
    installerAuthenticodeStatus = [string]$setupSign.Status
    publisherSigningApproved = $false
    playerAcceptanceApproved = $false
    publicReleaseAuthorized = $false
}
$receiptPath = Join-Path $OutputDir "TSTSS_WINDOWS_INSTALLER_DEFENDER_CUSTODY.json"
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $receiptPath -Encoding UTF8
Write-Host "TSTSS_DEFENDER_CUSTODY=PASS"
Write-Host "TSTSS_INSTALLER_SHA256=$($setupResult.sha256)"
Write-Host "TSTSS_INSTALLER_AUTHENTICODE_STATUS=$($setupSign.Status)"
Write-Host "TSTSS_DEFENDER_RECEIPT=$receiptPath"
Write-Host "PUBLIC_RELEASE_AUTHORIZED=NO"
