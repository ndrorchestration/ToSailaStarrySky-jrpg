param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\chapter1-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake Chapter 1 portable Windows candidate =="

$gitHead = (git rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or -not $gitHead) {
  throw "Unable to resolve Git HEAD. Run from an authenticated Git checkout."
}
$status = @(git status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) { throw "git status failed." }
if ($status.Count -gt 0) {
  throw "Tracked/staged source changes are present. Commit or restore them before candidate verification."
}
$shortHead = $gitHead.Substring(0, 12)
Write-Host "CHAPTER1_SOURCE_COMMIT=$gitHead"

npm ci
if ($LASTEXITCODE -ne 0) { throw "npm ci failed with code $LASTEXITCODE." }

# Browser proof is part of Chapter I acceptance. Install the pinned Playwright
# Chromium runtime if it is not already cached on this Windows machine.
npx playwright install chromium
if ($LASTEXITCODE -ne 0) { throw "Playwright Chromium installation failed with code $LASTEXITCODE." }

npm run test:chapter1-core
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 deterministic core gate failed with code $LASTEXITCODE." }

npm run test:chapter1-browser
if ($LASTEXITCODE -ne 0) { throw "Chapter 1 full browser player-route gate failed with code $LASTEXITCODE." }

npm run test:desktop-package
if ($LASTEXITCODE -ne 0) { throw "Desktop package contract failed with code $LASTEXITCODE." }

npm run package:windows
if ($LASTEXITCODE -ne 0) { throw "Windows package build failed with code $LASTEXITCODE." }

# Candidate evidence must still describe the exact source that was tested.
$afterBuildHead = (git rev-parse HEAD).Trim()
if ($afterBuildHead -ne $gitHead) {
  throw "Git HEAD changed during Chapter 1 candidate build."
}
$afterBuildStatus = @(git status --porcelain --untracked-files=no)
if ($afterBuildStatus.Count -gt 0) {
  throw "Tracked/staged source changed during Chapter 1 candidate build."
}

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$exeFile = Get-ChildItem -LiteralPath $distRoot -Filter "Aetherwake.exe" -File -Recurse |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $exeFile) {
  throw "Aetherwake.exe not found anywhere under packaged runtime root: $distRoot"
}

$package = Get-Item -LiteralPath $exeFile.DirectoryName
$exe = $exeFile.FullName
Write-Host "CHAPTER1_PACKAGE_ROOT=$($package.FullName)"
Write-Host "CHAPTER1_PACKAGE_EXE=$exe"

$marker = Join-Path $env:TEMP "aetherwake-chapter1-ready.json"
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}

$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $exe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) {
      throw "Chapter 1 Aetherwake.exe exited before first-frame readiness with code $($game.ExitCode)."
    }
    Start-Sleep -Milliseconds 250
  }

  if (-not (Test-Path -LiteralPath $marker)) {
    throw "Chapter 1 Aetherwake.exe did not report runtime-ready + first-frame within 20 seconds."
  }

  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame) {
    throw "Chapter 1 readiness marker did not confirm runtimeReady and firstFrame."
  }
  if ($ready.width -ne 960 -or $ready.height -ne 640) {
    throw "Chapter 1 readiness marker reported unexpected canvas $($ready.width)x$($ready.height)."
  }
  if ($ready.setupOrder -notlike "*setup-done*") {
    throw "Chapter 1 readiness marker did not include setup-done."
  }
  if ($game.HasExited) {
    throw "Chapter 1 Aetherwake.exe exited immediately after first-frame readiness with code $($game.ExitCode)."
  }
  Write-Host "CHAPTER1_DESKTOP_RENDER_READINESS=PASS"
}
finally {
  if ($game -and -not $game.HasExited) {
    Stop-Process -Id $game.Id -Force
  }
  Remove-Item Env:AETHERWAKE_DESKTOP_SMOKE_MARKER -ErrorAction SilentlyContinue
}

if (Test-Path -LiteralPath $OutputDir) {
  Remove-Item -LiteralPath $OutputDir -Recurse -Force
}
New-Item -ItemType Directory -Path $OutputDir | Out-Null

$folderName = "Aetherwake-Chapter1-$shortHead"
$candidateDir = Join-Path $OutputDir $folderName
Copy-Item -LiteralPath $package.FullName -Destination $candidateDir -Recurse

$zipName = "$folderName-Windows.zip"
$zip = Join-Path $OutputDir $zipName
Compress-Archive -Path (Join-Path $candidateDir "*") -DestinationPath $zip -CompressionLevel Optimal

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip
$hashLower = $hash.Hash.ToLower()
$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
"$hashLower  $zipName" | Set-Content -LiteralPath $manifest -Encoding ASCII

$evidence = [ordered]@{
  schemaVersion = 1
  candidate = "Aetherwake Chapter 1"
  sourceCommit = $gitHead
  generatedAtUtc = [DateTime]::UtcNow.ToString("o")
  chapter1Core = "PASS"
  chapter1BrowserRoute = "PASS"
  desktopPackageContract = "PASS"
  desktopRuntimeReady = $true
  desktopFirstFrame = $true
  canvas = "960x640"
  portableZip = $zipName
  portableZipSha256 = $hashLower
  windowsSaveCloseRelaunchContinue = "NOT_YET_VERIFIED"
  acceptance = "TECHNICAL_CANDIDATE_MANUAL_RELAUNCH_AND_PLAYER_ACCEPTANCE_PENDING"
}
$evidencePath = Join-Path $OutputDir "CHAPTER1_RELEASE_EVIDENCE.json"
$evidence | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $evidencePath -Encoding UTF8

Write-Host ""
Write-Host "AETHERWAKE_CHAPTER1_WINDOWS_CANDIDATE=PASS"
Write-Host "SOURCE_COMMIT=$gitHead"
Write-Host "PORTABLE_EXE=$(Join-Path $candidateDir 'Aetherwake.exe')"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "SHA256=$hashLower"
Write-Host "EVIDENCE=$evidencePath"
Write-Host "WINDOWS_SAVE_CLOSE_RELAUNCH_CONTINUE=NOT_YET_VERIFIED"
