param(
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Amonigio,
  [Parameter(Mandatory=$true)][string]$Nocturnal,
  [Parameter(Mandatory=$true)][string]$Solar,
  [Parameter(Mandatory=$true)][string]$OpenSky,
  [switch]$Commit
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

$head = (& git rev-parse HEAD 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$head)) { throw 'Readable Git HEAD required.' }
$branchName = (& git branch --show-current 2>$null)
if ([string]::IsNullOrWhiteSpace([string]$branchName)) { throw 'Named branch required.' }
$status = (& git status --porcelain=v1 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$status)) {
  throw 'Chapter 1 audio admission requires a clean working tree.'
}

foreach ($inputPath in @($Title,$Amonigio,$Nocturnal,$Solar,$OpenSky)) {
  if (-not (Test-Path -LiteralPath $inputPath)) { throw "Audio source missing: $inputPath" }
}

# Exact-byte preflight: no repository mutation before every source verifies.
npm run admit:title-audio -- --source "$Title" --check-only
if ($LASTEXITCODE -ne 0) { throw 'Title audio exact-byte preflight failed.' }
npm run admit:chapter1-soundtrack -- --amonigio "$Amonigio" --nocturnal "$Nocturnal" --solar "$Solar" --openSky "$OpenSky" --check-only
if ($LASTEXITCODE -ne 0) { throw 'Chapter 1 soundtrack exact-byte preflight failed.' }
Write-Host 'CHAPTER1_AUDIO_PREFLIGHT=PASS'

npm run admit:title-audio -- --source "$Title"
if ($LASTEXITCODE -ne 0) { throw 'Title audio admission failed.' }
npm run admit:chapter1-soundtrack -- --amonigio "$Amonigio" --nocturnal "$Nocturnal" --solar "$Solar" --openSky "$OpenSky"
if ($LASTEXITCODE -ne 0) { throw 'Chapter 1 soundtrack admission failed.' }

$expected = @(
  'assets/audio/aetherwake-skyward-arpeggio-main-title.mp3',
  'assets/audio/amonigio-umulula.mp3',
  'assets/audio/nocturnal-resolve.mp3',
  'assets/audio/solar-punk-airship.mp3',
  'assets/audio/open-sky-signal.mp3',
  'docs/audio-assets.json'
)
& git add -- @expected
if ($LASTEXITCODE -ne 0) { throw 'Failed to stage governed Chapter 1 audio paths.' }

$staged = @(& git diff --cached --name-only) | Where-Object { $_ -and $_.Trim() }
$unexpected = @($staged | Where-Object { $_ -notin $expected })
$missing = @($expected | Where-Object { $_ -notin $staged })
if ($unexpected.Count -gt 0) { throw "Unexpected staged paths: $($unexpected -join ', ')" }
if ($missing.Count -gt 0) { throw "Expected audio paths missing: $($missing -join ', ')" }

npm run test:chapter1-title-audio-ready
if ($LASTEXITCODE -ne 0) { throw 'Strict title-audio readiness failed.' }
npm run test:chapter1-soundtrack-ready
if ($LASTEXITCODE -ne 0) { throw 'Strict Chapter 1 soundtrack readiness failed.' }
npm run test:chapter1-audio-routing
if ($LASTEXITCODE -ne 0) { throw 'Chapter 1 audio routing failed.' }
Write-Host 'CHAPTER1_AUDIO_READINESS=PASS'

if (-not $Commit) {
  Write-Host 'CHAPTER1_AUDIO_ADMISSION=STAGED_VERIFIED'
  Write-Host "STAGED_PATHS=$($staged -join ',')"
  exit 0
}

& git commit -m 'assets: admit governed Chapter 1 soundtrack'
if ($LASTEXITCODE -ne 0) { throw 'Git commit failed.' }

$after = (& git status --porcelain=v1 2>$null) -join "\n"
if (-not [string]::IsNullOrWhiteSpace([string]$after)) { throw 'Working tree not clean after audio admission.' }

$newHead = (& git rev-parse HEAD 2>$null)
Write-Host 'CHAPTER1_AUDIO_ADMISSION=COMMITTED_VERIFIED'
Write-Host "SOURCE_COMMIT=$head"
Write-Host "ADMISSION_COMMIT=$newHead"
Write-Host 'NEXT_COMMAND=npm run build:chapter1:windows'
