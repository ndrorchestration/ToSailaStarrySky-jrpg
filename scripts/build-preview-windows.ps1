param(
  [string]$OutputDir = (Join-Path $PSScriptRoot "..\preview-release")
)

$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $repo

Write-Host "== Aetherwake Preview 0.1 portable Windows build =="

npm ci
if ($LASTEXITCODE -ne 0) { throw "npm ci failed with code $LASTEXITCODE." }

npm run test:embedded-launch-readiness
if ($LASTEXITCODE -ne 0) { throw "embedded launch readiness recovery test failed with code $LASTEXITCODE." }

npm run test:desktop-package
if ($LASTEXITCODE -ne 0) { throw "desktop package contract failed with code $LASTEXITCODE." }

npm run test:preview-world-presentation
if ($LASTEXITCODE -ne 0) { throw "Preview world presentation test failed with code $LASTEXITCODE." }

npm run package:windows
if ($LASTEXITCODE -ne 0) { throw "Windows package build failed with code $LASTEXITCODE." }

$distRoot = (Resolve-Path (Join-Path $repo "..\aetherwake-dist")).Path
$package = Get-ChildItem -LiteralPath $distRoot -Directory |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1
if (-not $package) { throw "NW.js did not produce a package directory." }

$exe = Join-Path $package.FullName "Aetherwake.exe"
if (-not (Test-Path -LiteralPath $exe)) {
  throw "Aetherwake.exe not found in packaged runtime."
}

# Preview 0.1 deliberately verifies the portable runtime directly.
# Formal NSIS installation, publication, and milestone evidence are not on this critical path.
$marker = Join-Path $env:TEMP "aetherwake-preview-ready.json"
if (Test-Path -LiteralPath $marker) {
  Remove-Item -LiteralPath $marker -Force
}

$env:AETHERWAKE_DESKTOP_SMOKE_MARKER = $marker
$game = Start-Process -FilePath $exe -PassThru
try {
  $deadline = (Get-Date).AddSeconds(20)
  while ((Get-Date) -lt $deadline -and -not (Test-Path -LiteralPath $marker)) {
    if ($game.HasExited) {
      throw "Portable Aetherwake.exe exited before reporting first-frame readiness with code $($game.ExitCode)."
    }
    Start-Sleep -Milliseconds 250
  }

  if (-not (Test-Path -LiteralPath $marker)) {
    throw "Portable Aetherwake.exe did not report runtime-ready + first-frame within 20 seconds."
  }

  $ready = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
  if (-not $ready.runtimeReady -or -not $ready.firstFrame) {
    throw "Preview readiness marker did not confirm runtimeReady and firstFrame."
  }
  if ($ready.width -ne 960 -or $ready.height -ne 640) {
    throw "Preview readiness marker reported unexpected canvas $($ready.width)x$($ready.height)."
  }
  if ($ready.setupOrder -notlike "*setup-done*") {
    throw "Preview readiness marker did not include setup-done."
  }
  if ($game.HasExited) {
    throw "Portable Aetherwake.exe exited immediately after first-frame readiness with code $($game.ExitCode)."
  }
  Write-Host "PREVIEW_DESKTOP_RENDER_READINESS=PASS"
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

$previewDir = Join-Path $OutputDir "Aetherwake-Preview-0.1"
Copy-Item -LiteralPath $package.FullName -Destination $previewDir -Recurse

$zip = Join-Path $OutputDir "Aetherwake-Preview-0.1-Windows.zip"
Compress-Archive -Path (Join-Path $previewDir "*") -DestinationPath $zip -CompressionLevel Optimal

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $zip
$manifest = Join-Path $OutputDir "SHA256SUMS.txt"
"$($hash.Hash.ToLower())  $([IO.Path]::GetFileName($zip))" |
  Set-Content -LiteralPath $manifest -Encoding ASCII

Write-Host ""
Write-Host "AETHERWAKE_PREVIEW_0_1=PASS"
Write-Host "PORTABLE_EXE=$(Join-Path $previewDir 'Aetherwake.exe')"
Write-Host "PORTABLE_ZIP=$zip"
Write-Host "SHA256=$($hash.Hash.ToLower())"
