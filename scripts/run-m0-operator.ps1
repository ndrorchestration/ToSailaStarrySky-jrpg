param(
  [string]$TitleAudioSource,
  [switch]$SkipTitleAdmission
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

Write-Host '== Aetherwake M0 operator lane =='

$head = (& git rev-parse HEAD 2>$null)
$branchName = (& git branch --show-current 2>$null)
$status = (& git status --porcelain=v1 2>$null) -join "
"

if ([string]::IsNullOrWhiteSpace([string]$head)) {
  throw 'M0 operator lane requires readable Git HEAD provenance.'
}
if ([string]::IsNullOrWhiteSpace([string]$branchName)) {
  throw 'M0 operator lane requires a named branch; detached HEAD is not allowed.'
}
if (-not [string]::IsNullOrWhiteSpace([string]$status)) {
  throw 'M0 operator lane requires a clean working tree.'
}

Write-Host "START_COMMIT=$head"
Write-Host "BRANCH=$branchName"

$manifestPath = Join-Path $Repo 'docs\audio-assets.json'
if (-not (Test-Path -LiteralPath $manifestPath)) {
  throw "Audio authority missing: $manifestPath"
}

# Do not trust manifest labels alone. The strict readiness gate also requires
# the canonical MP3 to exist, be Git-tracked, and match governed bytes/SHA-256.
& cmd.exe /d /s /c "npm run test:m0-title-audio-ready"
$titleReady = ($LASTEXITCODE -eq 0)

if (-not $titleReady) {
  if ($SkipTitleAdmission) {
    throw 'Title audio is not admitted; -SkipTitleAdmission cannot produce an M0 candidate.'
  }
  if ([string]::IsNullOrWhiteSpace([string]$TitleAudioSource)) {
    throw 'Title audio is not admitted. Supply -TitleAudioSource with the exact governed MP3.'
  }

  $admit = Join-Path $PSScriptRoot 'admit-title-audio.ps1'
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $admit -Source $TitleAudioSource -Commit
  $admitCode = $LASTEXITCODE
  if ($admitCode -ne 0) {
    throw "Title-audio admission failed with code $admitCode."
  }

  $head = (& git rev-parse HEAD 2>$null)
  $status = (& git status --porcelain=v1 2>$null) -join "
"
  if ([string]::IsNullOrWhiteSpace([string]$head) -or
      -not [string]::IsNullOrWhiteSpace([string]$status)) {
    throw 'Post-admission candidate provenance is not clean.'
  }
  Write-Host "ADMITTED_COMMIT=$head"
} else {
  Write-Host 'TITLE_AUDIO_ADMISSION=ALREADY_VERIFIED_STRICT'
}

$m0 = Join-Path $PSScriptRoot 'verify-m0-local.ps1'
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $m0
$m0Code = $LASTEXITCODE
if ($m0Code -ne 0) {
  throw "Full M0 local verification did not complete successfully (exit $m0Code)."
}

$summary = Join-Path $Repo 'artifacts\m0-local-verification\summary.json'
if (-not (Test-Path -LiteralPath $summary)) {
  throw "M0 summary missing after verification: $summary"
}
$result = Get-Content -LiteralPath $summary -Raw | ConvertFrom-Json
if ($result.overall -ne 'PASS_WITH_MANUAL_ACCEPTANCE_PENDING') {
  throw "Unexpected M0 local result: $($result.overall)"
}
if ($result.manualAcceptance.accessibilityVisualReview -ne 'PENDING_HUMAN_REVIEW') {
  throw 'M0 summary lost pending human accessibility review boundary.'
}
if ($result.manualAcceptance.uncoachedExternalPlayer -ne 'NOT_RUN') {
  throw 'M0 summary lost NOT_RUN external-player boundary.'
}
if (-not $result.externalPlaytest -or $result.externalPlaytest.status -ne 'PREPARED_NOT_RUN') {
  throw 'Candidate-bound external playtest packet was not prepared.'
}

npm run prepare:m0-manual-acceptance
if ($LASTEXITCODE -ne 0) {
  throw "Manual acceptance dashboard generation failed with code $LASTEXITCODE."
}
$manualDashboard = Join-Path $Repo 'artifacts\m0-manual-acceptance\index.html'
if (-not (Test-Path -LiteralPath $manualDashboard)) {
  throw 'Manual acceptance dashboard was not generated.'
}

Write-Host ''
Write-Host 'M0_OPERATOR_LANE=TECHNICAL_PASS_MANUAL_ACCEPTANCE_PENDING'
Write-Host "CANDIDATE_COMMIT=$($result.gitHead)"
Write-Host "SUMMARY=$summary"
Write-Host "ACCESSIBILITY_REVIEW_HTML=$($result.visualMatrix.reviewHtml)"
Write-Host "ACCESSIBILITY_REVIEW_RECORD=$($result.visualMatrix.reviewRecord)"
Write-Host "EXTERNAL_PLAYTEST_GUIDE=$($result.externalPlaytest.observerGuide)"
Write-Host "EXTERNAL_PLAYTEST_RECORD=$($result.externalPlaytest.record)"
Write-Host "MANUAL_ACCEPTANCE_DASHBOARD=$manualDashboard"
