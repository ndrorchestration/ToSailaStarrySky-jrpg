param(
  [switch]$SkipInstall,
  [switch]$SkipBrowserInstall,
  [switch]$SkipWindowsPackage
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = Split-Path -Parent $PSScriptRoot
$Artifacts = Join-Path $Repo 'artifacts\m0-local-verification'
$SummaryPath = Join-Path $Artifacts 'summary.json'
$VisualManifestPath = Join-Path $Repo 'artifacts\accessibility-visual-matrix\manifest.json'

New-Item -ItemType Directory -Force -Path $Artifacts | Out-Null

$results = [ordered]@{
  startedAt = (Get-Date).ToUniversalTime().ToString('o')
  repo = $Repo
  gitHead = $null
  gitStatus = $null
  developmentSkips = [ordered]@{
    install = [bool]$SkipInstall
    browserInstall = [bool]$SkipBrowserInstall
    windowsPackage = [bool]$SkipWindowsPackage
  }
  gates = @()
  visualMatrix = $null
  windowsPackage = $null
  externalPlaytest = $null
  evidenceBindings = [ordered]@{
    visualManifestSha256 = $null
    releaseEvidencePath = $null
    releaseEvidenceSha256 = $null
    releaseSourceCommit = $null
    installerSha256 = $null
    portableZipSha256 = $null
  }
  manualAcceptance = [ordered]@{
    accessibilityVisualReview = 'PENDING_HUMAN_REVIEW'
    accessibilityReviewProtocol = 'docs/M0_ACCESSIBILITY_VISUAL_REVIEW.md'
    accessibilityEvidenceTemplate = 'docs/m0-accessibility-visual-review.template.json'
    uncoachedExternalPlayer = 'NOT_RUN'
    externalPlayerProtocol = 'docs/M0_EXTERNAL_PLAYTEST.md'
    externalPlayerEvidenceTemplate = 'docs/m0-external-playtest-record.template.json'
  }
  overall = 'RUNNING'
}

function Write-Summary {
  param([string]$Overall)
  $results.overall = $Overall
  $results.completedAt = (Get-Date).ToUniversalTime().ToString('o')
  $results | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 $SummaryPath
}

function Invoke-Gate {
  param(
    [string]$Name,
    [string]$Command
  )

  Write-Host ""
  Write-Host "=== $Name ===" -ForegroundColor Cyan
  $started = Get-Date
  & cmd.exe /d /s /c $Command
  $code = $LASTEXITCODE
  $entry = [ordered]@{
    name = $Name
    command = $Command
    startedAt = $started.ToUniversalTime().ToString('o')
    completedAt = (Get-Date).ToUniversalTime().ToString('o')
    exitCode = $code
    status = $(if ($code -eq 0) { 'PASS' } else { 'FAIL' })
  }
  $results.gates += $entry

  if ($code -ne 0) {
    Write-Summary 'FAIL'
    throw "M0 gate failed: $Name (exit $code)"
  }
}

try {
  Push-Location $Repo

  try {
    $results.gitHead = (& git rev-parse HEAD 2>$null)
    $results.gitStatus = (& git status --porcelain=v1 2>$null) -join "
"
  } catch {
    $results.gitHead = $null
    $results.gitStatus = 'git metadata unavailable'
  }

  if ([string]::IsNullOrWhiteSpace([string]$results.gitHead)) {
    Write-Summary 'FAIL'
    throw 'M0 exact-head verification requires readable Git HEAD provenance.'
  }
  if (-not [string]::IsNullOrWhiteSpace([string]$results.gitStatus)) {
    Write-Summary 'FAIL'
    throw 'M0 exact-head verification requires a clean working tree. Commit or discard local changes before running this lane.'
  }

  if (-not $SkipInstall) {
    Invoke-Gate 'npm clean install' 'npm ci --ignore-scripts --no-audit --no-fund'
  }

  $unitGates = @(
    'test:save-system',
    'test:save-runtime',
    'test:save-payload',
    'test:save-interrupted-write',
    'test:persistence-coverage',
    'test:first-wake-benchmark',
    'test:input-actions',
    'test:focus-manager',
    'test:gamepad-input',
    'test:input-bindings',
    'test:input-runtime',
    'test:input-accessibility',
    'test:user-settings',
    'test:settings-runtime',
    'test:accessibility-rendering',
    'test:accessibility-visual-review',
    'test:audio-assets',
    'test:title-audio-admission',
    'test:title-audio-handoff',
    'test:title-audio-runtime',
    'test:m0-title-audio-ready',
    'test:music-bus',
    'test:audio-settings',
    'test:world-authority',
    'test:production-method',
    'test:release-evidence',
    'test:external-playtest-evidence'
  )

  foreach ($gate in $unitGates) {
    Invoke-Gate $gate "npm run $gate"
  }

  if (-not $SkipBrowserInstall) {
    Invoke-Gate 'Playwright Chromium install' 'npx playwright install chromium'
  }

  foreach ($gate in @(
    'test:smoke',
    'test:first-wake-benchmark-live',
    'test:controller-parity-live',
    'test:accessibility-visual-matrix'
  )) {
    Invoke-Gate $gate "npm run $gate"
  }

  if (-not (Test-Path $VisualManifestPath)) {
    throw "Accessibility visual matrix manifest missing: $VisualManifestPath"
  }
  $visual = Get-Content -Raw $VisualManifestPath | ConvertFrom-Json
  if ($visual.captureCount -ne 58) {
    throw "Accessibility visual matrix capture count drifted: $($visual.captureCount)"
  }
  if ($visual.reviewStatus -ne 'HUMAN_REVIEW_REQUIRED') {
    throw "Accessibility visual matrix review status drifted: $($visual.reviewStatus)"
  }
  Invoke-Gate 'prepare:accessibility-review' 'npm run prepare:accessibility-review'
  $reviewHtml = Join-Path (Split-Path $VisualManifestPath -Parent) 'review-index.html'
  $reviewRecord = Join-Path (Split-Path $VisualManifestPath -Parent) 'human-review.json'
  if (-not (Test-Path $reviewHtml) -or -not (Test-Path $reviewRecord)) {
    throw 'Accessibility review packet was not generated.'
  }
  $visualManifestHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $VisualManifestPath).Hash.ToLower()
  if ($visual.gitHead -ne $results.gitHead) {
    Write-Summary 'FAIL'
    throw "Accessibility visual manifest Git HEAD does not match M0 candidate: $($visual.gitHead) != $($results.gitHead)"
  }
  $results.evidenceBindings.visualManifestSha256 = $visualManifestHash
  $results.visualMatrix = [ordered]@{
    manifest = $VisualManifestPath
    manifestSha256 = $visualManifestHash
    gitHead = $visual.gitHead
    captureCount = $visual.captureCount
    reviewStatus = $visual.reviewStatus
    status = 'CAPTURED_HUMAN_REVIEW_REQUIRED'
    reviewHtml = $reviewHtml
    reviewRecord = $reviewRecord
  }

  if (-not $SkipWindowsPackage) {
    $packageScript = Join-Path $PSScriptRoot 'build-windows-release.ps1'
    if (-not (Test-Path $packageScript)) {
      throw "Windows release verifier missing: $packageScript"
    }
    Write-Host ""
    Write-Host "=== exact Windows package/install/save-restart verification ===" -ForegroundColor Cyan
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $packageScript
    $packageCode = $LASTEXITCODE
    if ($packageCode -ne 0) {
      $results.windowsPackage = [ordered]@{
        script = $packageScript
        exitCode = $packageCode
        status = 'FAIL'
      }
      Write-Summary 'FAIL'
      throw "Windows release verification failed (exit $packageCode)"
    }

    $releaseEvidencePath = Join-Path $Repo 'local-release\RELEASE_EVIDENCE.json'
    if (-not (Test-Path $releaseEvidencePath)) {
      Write-Summary 'FAIL'
      throw "Release evidence missing after verified Windows build: $releaseEvidencePath"
    }
    $releaseEvidence = Get-Content -LiteralPath $releaseEvidencePath -Raw | ConvertFrom-Json
    $releaseEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $releaseEvidencePath).Hash.ToLower()
    if ($releaseEvidence.source.gitHead -ne $results.gitHead) {
      Write-Summary 'FAIL'
      throw "Release evidence Git HEAD does not match M0 candidate: $($releaseEvidence.source.gitHead) != $($results.gitHead)"
    }
    $results.evidenceBindings.releaseEvidencePath = $releaseEvidencePath
    $results.evidenceBindings.releaseEvidenceSha256 = $releaseEvidenceHash
    $results.evidenceBindings.releaseSourceCommit = $releaseEvidence.source.gitHead
    $results.evidenceBindings.installerSha256 = $releaseEvidence.artifacts.installer.sha256
    $results.evidenceBindings.portableZipSha256 = $releaseEvidence.artifacts.portableZip.sha256
    $results.windowsPackage = [ordered]@{
      script = $packageScript
      exitCode = $packageCode
      status = 'PASS'
      releaseEvidence = $releaseEvidencePath
      releaseEvidenceSha256 = $releaseEvidenceHash
      sourceCommit = $releaseEvidence.source.gitHead
      installerSha256 = $releaseEvidence.artifacts.installer.sha256
      portableZipSha256 = $releaseEvidence.artifacts.portableZip.sha256
    }
    Invoke-Gate 'prepare:external-playtest' 'npm run prepare:external-playtest'
    $externalPlaytestDir = Join-Path $Repo 'artifacts\m0-external-playtest'
    $externalPlaytestRecord = Join-Path $externalPlaytestDir 'external-playtest.json'
    $externalPlaytestGuide = Join-Path $externalPlaytestDir 'observer-guide.html'
    if (-not (Test-Path $externalPlaytestRecord) -or -not (Test-Path $externalPlaytestGuide)) {
      Write-Summary 'FAIL'
      throw 'External playtest packet was not generated.'
    }
    $results.externalPlaytest = [ordered]@{
      status = 'PREPARED_NOT_RUN'
      releaseEvidence = $releaseEvidencePath
      record = $externalPlaytestRecord
      observerGuide = $externalPlaytestGuide
    }
  } else {
    $results.windowsPackage = [ordered]@{
      status = 'SKIPPED_DEVELOPMENT_ONLY'
    }
    Write-Summary 'INCOMPLETE_REQUIRED_GATE_SKIPPED'
    Write-Host ""
    Write-Host "M0_LOCAL_VERIFICATION=INCOMPLETE_REQUIRED_GATE_SKIPPED" -ForegroundColor Yellow
    Write-Host "WINDOWS_PACKAGE=SKIPPED_DEVELOPMENT_ONLY"
    Write-Host "SUMMARY=$SummaryPath"
    exit 2
  }

  if ($SkipInstall -or $SkipBrowserInstall) {
    Write-Summary 'INCOMPLETE_REQUIRED_PREREQUISITE_SKIPPED'
    Write-Host ""
    Write-Host "M0_LOCAL_VERIFICATION=INCOMPLETE_REQUIRED_PREREQUISITE_SKIPPED" -ForegroundColor Yellow
    Write-Host "DEVELOPMENT_SKIP_INSTALL=$([bool]$SkipInstall)"
    Write-Host "DEVELOPMENT_SKIP_BROWSER_INSTALL=$([bool]$SkipBrowserInstall)"
    Write-Host "SUMMARY=$SummaryPath"
    Write-Host "VISUAL_MATRIX=$VisualManifestPath"
  Write-Host "ACCESSIBILITY_REVIEW_HTML=$reviewHtml"
  Write-Host "ACCESSIBILITY_REVIEW_RECORD=$reviewRecord"
  Write-Host "EXTERNAL_PLAYTEST_GUIDE=$externalPlaytestGuide"
  Write-Host "EXTERNAL_PLAYTEST_RECORD=$externalPlaytestRecord"
  Write-Host "ACCESSIBILITY_REVIEW_HTML=$reviewHtml"
  Write-Host "ACCESSIBILITY_REVIEW_RECORD=$reviewRecord"
    exit 2
  }

  Write-Summary 'PASS_WITH_MANUAL_ACCEPTANCE_PENDING'
  Write-Host ""
  Write-Host "M0_LOCAL_VERIFICATION=PASS_WITH_MANUAL_ACCEPTANCE_PENDING" -ForegroundColor Green
  Write-Host "MANUAL_ACCESSIBILITY_REVIEW=PENDING_HUMAN_REVIEW"
  Write-Host "UNCOACHED_EXTERNAL_PLAYER=NOT_RUN"
  Write-Host "SUMMARY=$SummaryPath"
  Write-Host "VISUAL_MATRIX=$VisualManifestPath"
  Write-Host "VISUAL_MANIFEST_SHA256=$($results.evidenceBindings.visualManifestSha256)"
  Write-Host "RELEASE_EVIDENCE=$($results.evidenceBindings.releaseEvidencePath)"
  Write-Host "RELEASE_EVIDENCE_SHA256=$($results.evidenceBindings.releaseEvidenceSha256)"
  Write-Host "INSTALLER_SHA256=$($results.evidenceBindings.installerSha256)"
  Write-Host "PORTABLE_ZIP_SHA256=$($results.evidenceBindings.portableZipSha256)"
}
catch {
  if ($results.overall -eq 'RUNNING') {
    Write-Summary 'FAIL'
  }
  Write-Error $_
  exit 1
}
finally {
  Pop-Location
}
