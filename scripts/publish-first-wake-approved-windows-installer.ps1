# Publish only an explicitly approved, exact-source, Defender-scanned First Wake
# Windows Setup.exe to an SHA-scoped GitHub prerelease. Never run from ordinary CI.
# A draft release is verified by downloading the attached installer before publish.
param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[0-9a-f]{40}$')][string]$ExpectedSourceSha,
    [Parameter(Mandatory=$true)][string]$CandidateDir,
    [Parameter(Mandatory=$true)][string]$PlayerAcceptanceReceipt,
    [switch]$ApprovePublicPrerelease,
    [switch]$AcceptUnsignedPreview
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if (-not $ApprovePublicPrerelease.IsPresent) {
    throw "TSTSS_RELEASE_CREATOR_EXPLICIT_APPROVAL_REQUIRED"
}
$repo = "ndrorchestration/ToSailtheStarrySky-jrpg"
$root = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$current = (& git -C $root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $current -cne $ExpectedSourceSha) {
    throw "TSTSS_RELEASE_SOURCE_SHA_MISMATCH"
}
$dirty = @(& git -C $root status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0 -or $dirty.Count -gt 0) {
    throw "TSTSS_RELEASE_TRACKED_SOURCE_NOT_CLEAN"
}
foreach ($cmd in @("gh", "Get-MpComputerStatus", "Get-FileHash", "Get-AuthenticodeSignature")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        throw "TSTSS_RELEASE_TOOL_UNAVAILABLE:$cmd"
    }
}
$status = Get-MpComputerStatus -ErrorAction Stop
if (-not [bool]$status.AntivirusEnabled -or -not [bool]$status.RealTimeProtectionEnabled) {
    throw "TSTSS_RELEASE_DEFENDER_REALTIME_REQUIRED"
}
& gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_GH_AUTH_REQUIRED" }

$dir = [IO.Path]::GetFullPath($CandidateDir)
$setup = Join-Path $dir "ToSailTheStarrySky-Setup.exe"
$game = Join-Path $dir "ToSailTheStarrySky.exe"
$manifest = Join-Path $dir "SHA256SUMS.txt"
$custodyPath = Join-Path $dir "TSTSS_WINDOWS_INSTALLER_DEFENDER_CUSTODY.json"
foreach ($file in @($setup, $game, $manifest, $custodyPath, $PlayerAcceptanceReceipt)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "TSTSS_RELEASE_REQUIRED_EVIDENCE_MISSING:$file"
    }
}
$installerHash = (Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash.ToLowerInvariant()
$gameHash = (Get-FileHash -LiteralPath $game -Algorithm SHA256).Hash.ToLowerInvariant()
$manifestLines = @(Get-Content -LiteralPath $manifest)
if ($manifestLines -cnotcontains "$installerHash  ToSailTheStarrySky-Setup.exe" -or
    $manifestLines -cnotcontains "$gameHash  ToSailTheStarrySky.exe") {
    throw "TSTSS_RELEASE_MANIFEST_DIGEST_MISMATCH"
}

$custody = Get-Content -LiteralPath $custodyPath -Raw | ConvertFrom-Json
if ($custody.schema -cne "TSTSS_WINDOWS_INSTALLER_DEFENDER_CUSTODY_V1" -or
    $custody.sourceSha -cne $ExpectedSourceSha -or
    -not [bool]$custody.defenderAntivirusEnabled -or
    -not [bool]$custody.defenderRealtimeEnabled -or
    $custody.installer.result -cne "PASS" -or
    $custody.game.result -cne "PASS" -or
    $custody.installer.sha256 -cne $installerHash -or
    $custody.game.sha256 -cne $gameHash -or
    [bool]$custody.publicReleaseAuthorized) {
    throw "TSTSS_RELEASE_EXACT_BINARY_DEFENDER_CUSTODY_NOT_VERIFIED"
}
foreach ($evidence in @($custody.installer, $custody.game)) {
    if ([string]::IsNullOrWhiteSpace([string]$evidence.scanId) -or
        [long]$evidence.scanStartEvent -le 0 -or
        [long]$evidence.scanCompletionEvent -le [long]$evidence.scanStartEvent -or
        [int]$evidence.detections -ne 0) {
        throw "TSTSS_RELEASE_DEFENDER_SCAN_EVIDENCE_INCOMPLETE"
    }
}
$signature = Get-AuthenticodeSignature -LiteralPath $setup
if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -and
    -not $AcceptUnsignedPreview.IsPresent) {
    throw "TSTSS_RELEASE_UNSIGNED_PREVIEW_NEEDS_EXPLICIT_APPROVAL"
}

# Player acceptance is independent of script-created security evidence.
# These fields must come from an actual installed-game Windows playtest.
$playtest = Get-Content -LiteralPath $PlayerAcceptanceReceipt -Raw | ConvertFrom-Json
if ($playtest.schema -cne "TSTSS_FIRST_WAKE_WINDOWS_PLAYER_ACCEPTANCE_V1" -or
    $playtest.sourceSha -cne $ExpectedSourceSha -or
    $playtest.installerSha256 -cne $installerHash -or
    $playtest.result -cne "PASS" -or
    [string]::IsNullOrWhiteSpace([string]$playtest.tester) -or
    [string]::IsNullOrWhiteSpace([string]$playtest.testedAtUtc)) {
    throw "TSTSS_RELEASE_PLAYER_ACCEPTANCE_NOT_BOUND"
}
$acceptanceAt = [datetimeoffset]::MinValue
if (-not [datetimeoffset]::TryParse([string]$playtest.testedAtUtc, [ref]$acceptanceAt) -or
    $acceptanceAt -gt [datetimeoffset]::UtcNow -or
    $acceptanceAt -lt [datetimeoffset]::UtcNow.AddDays(-30)) {
    throw "TSTSS_RELEASE_PLAYER_ACCEPTANCE_TIMESTAMP_INVALID"
}
foreach ($field in @(
    "installedGameLaunched", "firstFlightCompleted", "splashdownCompleted",
    "postflightReserveInspected", "saveAndLoadVerified",
    "windowMaximizeRestoreVerified", "installerUninstallVerified",
    "inputAndAccessibilityReviewed", "visualAndAudioReviewed",
    "creatorReviewedAndApproved"
)) {
    if (-not [bool]$playtest.$field) {
        throw "TSTSS_RELEASE_PLAYER_ACCEPTANCE_INCOMPLETE:$field"
    }
}

# Do not replace an existing release or rewrite another build's assets.
$tag = "first-wake-native-preview-$($ExpectedSourceSha.Substring(0,12))"
& gh release view $tag --repo $repo --json name 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { throw "TSTSS_RELEASE_TAG_ALREADY_EXISTS" }

$notes = Join-Path $dir "FIRST_WAKE_RELEASE_NOTES.txt"
@(
    "To Sail the Starry Sky — First Wake native Windows playable preview",
    "",
    "This is a development preview, not the complete JRPG.",
    "Download the Setup.exe, double-click to install, then launch from Windows Start or Desktop.",
    "Works without the Godot editor, command line, browser or source checkout.",
    "Source SHA: $ExpectedSourceSha",
    "Setup.exe SHA256: $installerHash",
    "Microsoft Defender-on exact binary scan receipt and player acceptance reviewed.",
    "Installer Authenticode status: $($signature.Status)",
    "Unsigned Windows preview binaries may trigger Microsoft SmartScreen reputation warnings.",
    "Do not disable Windows Defender or antivirus to run this preview."
) | Set-Content -LiteralPath $notes -Encoding UTF8

# Creating a draft first allows a remote download-and-digest check before
# the one-way public release action. A failed check leaves only a draft.
& gh release create $tag $setup $manifest --repo $repo --target $ExpectedSourceSha --title "To Sail the Starry Sky — First Wake Windows Preview" --notes-file $notes --draft --prerelease
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_DRAFT_UPLOAD_FAILED" }
Write-Host "TSTSS_RELEASE_DRAFT_ASSET_UPLOAD=PASS"

$verificationDir = Join-Path $dir "remote-download-verification"
if (Test-Path -LiteralPath $verificationDir) {
    throw "TSTSS_RELEASE_VERIFICATION_DIRECTORY_ALREADY_EXISTS"
}
New-Item -ItemType Directory -Path $verificationDir -Force | Out-Null
& gh release download $tag --repo $repo --pattern "ToSailTheStarrySky-Setup.exe" --dir $verificationDir
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_DRAFT_DOWNLOAD_FAILED" }
$remote = Join-Path $verificationDir "ToSailTheStarrySky-Setup.exe"
if (-not (Test-Path -LiteralPath $remote -PathType Leaf)) {
    throw "TSTSS_RELEASE_DRAFT_REMOTE_ASSET_NOT_FOUND"
}
$remoteHash = (Get-FileHash -LiteralPath $remote -Algorithm SHA256).Hash.ToLowerInvariant()
if ($remoteHash -cne $installerHash) { throw "TSTSS_RELEASE_DRAFT_ASSET_SHA256_MISMATCH" }
Write-Host "TSTSS_RELEASE_DRAFT_DOWNLOADED_SHA256=PASS:$remoteHash"

# Public promotion is permitted only with explicit creator approval supplied
# above AND source/Defender/installed-player/remote-byte proofs.
# Validate the draft asset's expected direct URL before making it public.
$draftDetails = (& gh release view $tag --repo $repo --json assets,isDraft | Out-String)
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_DRAFT_METADATA_QUERY_FAILED" }
$draft = $draftDetails | ConvertFrom-Json
$draftAsset = @($draft.assets | Where-Object { $_.name -ceq "ToSailTheStarrySky-Setup.exe" })
$expectedUrl = "https://github.com/$repo/releases/download/$tag/ToSailTheStarrySky-Setup.exe"
if (-not [bool]$draft.isDraft -or
    $draftAsset.Count -ne 1 -or
    [string]$draftAsset[0].url -cne $expectedUrl -or
    [long]$draftAsset[0].size -ne (Get-Item -LiteralPath $setup).Length) {
    throw "TSTSS_RELEASE_DRAFT_ASSET_METADATA_MISMATCH"
}
# GitHub release asset digest provides a second independent stored checksum.
# Older GitHub instances may omit digest; remote byte-download verification above
# is mandatory regardless of this optional server-provided value.
$digest = [string]$draftAsset[0].digest
if ($digest -and $digest -cne "sha256:$installerHash") {
    throw "TSTSS_RELEASE_DRAFT_GITHUB_ASSET_DIGEST_MISMATCH"
}
Write-Host "TSTSS_RELEASE_DRAFT_METADATA=PASS"
& gh release edit $tag --repo $repo --draft=false --prerelease
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_PROMOTION_FAILED_DRAFT_ONLY" }
$details = (& gh release view $tag --repo $repo --json assets,isDraft,isPrerelease | Out-String)
if ($LASTEXITCODE -ne 0) { throw "TSTSS_RELEASE_PUBLISHED_ASSET_QUERY_FAILED" }
$published = $details | ConvertFrom-Json
$asset = @($published.assets | Where-Object { $_.name -ceq "ToSailTheStarrySky-Setup.exe" })
if ([bool]$published.isDraft -or -not [bool]$published.isPrerelease -or $asset.Count -ne 1) {
    throw "TSTSS_RELEASE_PUBLIC_ASSET_STATE_MISMATCH"
}
$url = [string]$asset[0].url
$expectedUrl = "https://github.com/$repo/releases/download/$tag/ToSailTheStarrySky-Setup.exe"
if ($url -cne $expectedUrl) {
    throw "TSTSS_RELEASE_DIRECT_DOWNLOAD_URL_MISMATCH"
}
$urlPath = Join-Path $dir "DIRECT_WINDOWS_INSTALLER_URL.txt"
Set-Content -LiteralPath $urlPath -Value $url -Encoding ascii
Write-Host "TSTSS_FIRST_WAKE_DIRECT_DOWNLOAD_READY=PASS"
Write-Host "TSTSS_FIRST_WAKE_DIRECT_DOWNLOAD_URL=$url"
Write-Host "TSTSS_FIRST_WAKE_PUBLIC_INSTALLER_SHA256=$installerHash"
Write-Host "TSTSS_FIRST_WAKE_README_LINK_PENDING_CREATOR_REVIEW"
