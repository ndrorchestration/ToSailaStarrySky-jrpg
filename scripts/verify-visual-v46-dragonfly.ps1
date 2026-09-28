param(
  [switch]$SkipFullVisual
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Run-Step {
  param([string]$Label, [scriptblock]$Command)
  Write-Host "== $Label =="
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE"
  }
}

$head = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -notmatch '^[0-9a-f]{40}$') {
  throw 'Unable to resolve exact 40-character Git head.'
}

$status = git status --porcelain
if ($LASTEXITCODE -ne 0) { throw 'git status failed' }
if ($status) {
  throw 'Working tree is not clean. Exact-head visual verification must run from a clean tree.'
}

Run-Step 'Dragonfly focused contracts' {
  node --test tests/dragonfly-visual-authority.test.js tests/flight-visual-gate.test.js tests/title-visual-stage.test.js tests/first-wake-visual-stage.test.js
}

if (-not $SkipFullVisual) {
  Run-Step 'Full Chapter 1 visual suite' { npm run test:chapter1-visual }
  Run-Step 'Complete Chapter 1 browser route + replay' { npm run test:chapter1-browser }
}

Run-Step 'Exact-head visual evidence capture' { npm run capture:visual-evidence }
Run-Step 'Visual performance verifier' { npm run verify:visual-performance }
Run-Step 'Git whitespace verification' { git diff --check }

$manifest = Join-Path $repo 'visual-evidence\manifest.json'
if (-not (Test-Path $manifest)) {
  throw 'Visual evidence manifest missing after capture.'
}
$manifestHash = (Get-FileHash -Algorithm SHA256 $manifest).Hash.ToLowerInvariant()

Write-Host "AETHERWAKE_DRAGONFLY_EXACT_HEAD=$head"
Write-Host "AETHERWAKE_VISUAL_EVIDENCE_MANIFEST_SHA256=$manifestHash"
Write-Host "AETHERWAKE_DRAGONFLY_RENDER_REVIEW=PENDING_HUMAN"
Write-Host "AETHERWAKE_DRAGONFLY_VERIFY=PASS"
