param(
  [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

$head = (& git rev-parse HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$head)) {
  throw 'Chapter 1 local verification requires readable Git HEAD provenance.'
}
$branchName = (& git branch --show-current 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$branchName)) {
  throw 'Chapter 1 local verification requires a named branch.'
}
$beforeStatus = (& git status --porcelain --untracked-files=no 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$beforeStatus)) {
  throw 'Chapter 1 local verification requires no tracked/staged source drift.'
}

Write-Host "CHAPTER1_VERIFY_SOURCE_COMMIT=$head"
Write-Host "CHAPTER1_VERIFY_SOURCE_BRANCH=$branchName"

if (-not $SkipInstall) {
  npm ci
  if ($LASTEXITCODE -ne 0) { throw "npm ci failed with code $LASTEXITCODE." }

  npx playwright install chromium
  if ($LASTEXITCODE -ne 0) { throw "Playwright Chromium install failed with code $LASTEXITCODE." }
}

npm run test:chapter1-core
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 core gate failed with code $LASTEXITCODE." }
Write-Host 'CHAPTER1_CORE=PASS'

npm run test:chapter1-visual
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 visual/presentation gate failed with code $LASTEXITCODE." }
Write-Host 'CHAPTER1_VISUAL=PASS'

npm run test:chapter1-browser
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 browser route failed with code $LASTEXITCODE." }
Write-Host 'CHAPTER1_BROWSER=PASS'

npm run test:desktop-package
if ($LASTEXITCODE -ne 0) { throw "Desktop package contract failed with code $LASTEXITCODE." }
Write-Host 'CHAPTER1_DESKTOP_PACKAGE_CONTRACT=PASS'

$afterHead = (& git rev-parse HEAD 2>$null)
if ($afterHead -ne $head) {
  throw "Git HEAD changed during verification: $head -> $afterHead"
}
$afterStatus = (& git status --porcelain --untracked-files=no 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$afterStatus)) {
  throw 'Tracked/staged source drift appeared during Chapter 1 verification.'
}

$evidence = [ordered]@{
  schemaVersion = 1
  kind = 'AETHERWAKE_CHAPTER1_LOCAL_VERIFICATION'
  sourceCommit = $head
  sourceBranch = $branchName
  chapter1Core = 'PASS'
  chapter1Visual = 'PASS'
  chapter1BrowserRoute = 'PASS'
  desktopPackageContract = 'PASS'
  audioBinaryAdmission = 'NOT_EVALUATED_BY_THIS_LANE'
  windowsStandaloneRuntime = 'NOT_EVALUATED_BY_THIS_LANE'
  playerAcceptance = 'NOT_EVALUATED_BY_THIS_LANE'
  verifiedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
}

$evidencePath = Join-Path $Repo 'CHAPTER1_LOCAL_VERIFICATION.json'
$evidence | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

Write-Host ''
Write-Host 'CHAPTER1_LOCAL_VERIFICATION=PASS'
Write-Host "EVIDENCE=$evidencePath"
Write-Host 'This evidence does not establish audio admission, standalone Windows runtime, or player acceptance.'
