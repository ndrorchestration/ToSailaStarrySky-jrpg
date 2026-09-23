param(
  [Parameter(Mandatory=$true)][string]$Source,
  [switch]$Commit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

$expected = @(
  'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3',
  'docs/audio-assets.json',
  'modules/audio-assets-runtime.js'
)

$head = (& git rev-parse HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$head)) {
  throw 'Title-audio admission requires readable Git HEAD provenance.'
}

$status = (& git status --porcelain=v1 2>$null) -join "
"
if (-not [string]::IsNullOrWhiteSpace([string]$status)) {
  throw 'Title-audio admission requires a clean working tree before mutation.'
}

if (-not (Test-Path -LiteralPath $Source)) {
  throw "Title-audio source file does not exist: $Source"
}

Write-Host "SOURCE_COMMIT=$head"
npm run admit:title-audio -- --source "$Source"
if ($LASTEXITCODE -ne 0) {
  throw "Governed title-audio admission failed with code $LASTEXITCODE."
}

& git add -- @expected
if ($LASTEXITCODE -ne 0) {
  throw "Failed to stage governed title-audio admission paths."
}

$staged = @(& git diff --cached --name-only) | Where-Object { $_ -and $_.Trim() }
$unexpected = @($staged | Where-Object { $_ -notin $expected })
$missing = @($expected | Where-Object { $_ -notin $staged })

if ($unexpected.Count -gt 0) {
  throw "Unexpected staged paths after title-audio admission: $($unexpected -join ', ')"
}
if ($missing.Count -gt 0) {
  throw "Expected title-audio admission paths were not staged: $($missing -join ', ')"
}

npm run test:m0-title-audio-ready
if ($LASTEXITCODE -ne 0) {
  throw "Strict M0 title-audio readiness failed with code $LASTEXITCODE."
}

if (-not $Commit) {
  Write-Host ''
  Write-Host 'TITLE_AUDIO_ADMISSION=STAGED_VERIFIED'
  Write-Host 'COMMIT_REQUIRED=true'
  Write-Host "STAGED_PATHS=$($staged -join ',')"
  exit 0
}

& git commit -m 'assets: admit canonical Skyward Arpeggio title theme'
if ($LASTEXITCODE -ne 0) {
  throw "Git commit failed with code $LASTEXITCODE."
}

$after = (& git status --porcelain=v1 2>$null) -join "
"
if (-not [string]::IsNullOrWhiteSpace([string]$after)) {
  throw 'Title-audio admission commit completed but working tree is not clean.'
}

$newHead = (& git rev-parse HEAD 2>$null)
npm run test:m0-title-audio-ready
if ($LASTEXITCODE -ne 0) {
  throw "Post-commit strict title-audio readiness failed with code $LASTEXITCODE."
}

Write-Host ''
Write-Host 'TITLE_AUDIO_ADMISSION=COMMITTED_VERIFIED'
Write-Host "SOURCE_COMMIT=$head"
Write-Host "ADMISSION_COMMIT=$newHead"
