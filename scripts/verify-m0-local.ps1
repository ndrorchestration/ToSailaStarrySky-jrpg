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
  gates = @()
  visualMatrix = $null
  windowsPackage = $null
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
    'test:audio-assets',
    'test:title-audio-admission',
    'test:title-audio-runtime',
    'test:music-bus',
    'test:audio-settings',
    'test:world-authority'
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
  if ($visual.captureCount -ne 54) {
    throw "Accessibility visual matrix capture count drifted: $($visual.captureCount)"
  }
  if ($visual.reviewStatus -ne 'HUMAN_REVIEW_REQUIRED') {
    throw "Accessibility visual matrix review status drifted: $($visual.reviewStatus)"
  }
  $results.visualMatrix = [ordered]@{
    manifest = $VisualManifestPath
    captureCount = $visual.captureCount
    reviewStatus = $visual.reviewStatus
    status = 'CAPTURED_HUMAN_REVIEW_REQUIRED'
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
    $results.windowsPackage = [ordered]@{
      script = $packageScript
      exitCode = $packageCode
      status = $(if ($packageCode -eq 0) { 'PASS' } else { 'FAIL' })
    }
    if ($packageCode -ne 0) {
      Write-Summary 'FAIL'
      throw "Windows release verification failed (exit $packageCode)"
    }
  } else {
    $results.windowsPackage = [ordered]@{
      status = 'SKIPPED_BY_OPERATOR'
    }
  }

  Write-Summary 'PASS_WITH_HUMAN_VISUAL_REVIEW_PENDING'
  Write-Host ""
  Write-Host "M0_LOCAL_VERIFICATION=PASS_WITH_HUMAN_VISUAL_REVIEW_PENDING" -ForegroundColor Green
  Write-Host "SUMMARY=$SummaryPath"
  Write-Host "VISUAL_MATRIX=$VisualManifestPath"
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
