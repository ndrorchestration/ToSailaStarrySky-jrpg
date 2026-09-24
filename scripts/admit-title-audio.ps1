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
  'docs/audio-assets.json'
)

$head = (& git rev-parse HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$head)) { throw 'Readable Git HEAD required.' }
$status = (& git status --porcelain=v1 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$status)) {
  throw 'Title-audio admission requires a clean working tree before mutation.'
}
if (-not (Test-Path -LiteralPath $Source)) { throw "Title-audio source missing: $Source" }
$branchName = (& git branch --show-current 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$branchName)) { throw 'Named branch required.' }

npm run admit:title-audio -- --source "$Source" --check-only
if ($LASTEXITCODE -ne 0) { throw 'Title-audio preflight verification failed.' }
npm run admit:title-audio -- --source "$Source"
if ($LASTEXITCODE -ne 0) { throw 'Governed title-audio admission failed.' }

& git add -- @expected
if ($LASTEXITCODE -ne 0) { throw 'Failed to stage governed title-audio files.' }

$staged = @(& git diff --cached --name-only) | Where-Object { $_ -and $_.Trim() }
$unexpected = @($staged | Where-Object { $_ -notin $expected })
$missing = @($expected | Where-Object { $_ -notin $staged })
if ($unexpected.Count -gt 0) { throw "Unexpected staged paths: $($unexpected -join ', ')" }
if ($missing.Count -gt 0) { throw "Expected staged paths missing: $($missing -join ', ')" }

npm run test:chapter1-title-audio-ready
if ($LASTEXITCODE -ne 0) { throw 'Strict Chapter 1 title-audio readiness failed.' }

if (-not $Commit) {
  Write-Host 'CHAPTER1_TITLE_AUDIO_ADMISSION=STAGED_VERIFIED'
  Write-Host "STAGED_PATHS=$($staged -join ',')"
  exit 0
}

& git commit -m 'assets: admit canonical Skyward Arpeggio title theme'
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }
$after = (& git status --porcelain=v1 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$after)) { throw 'Working tree not clean after admission commit.' }
$newHead = (& git rev-parse HEAD 2>$null)
Write-Host 'CHAPTER1_TITLE_AUDIO_ADMISSION=COMMITTED_VERIFIED'
Write-Host "SOURCE_COMMIT=$head"
Write-Host "ADMISSION_COMMIT=$newHead"
Write-Host 'NEXT_COMMAND=npm run build:chapter1:windows'
