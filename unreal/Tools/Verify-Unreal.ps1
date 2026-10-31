param(
    [Parameter(Mandatory=$true)][string]$EngineRoot,
    [switch]$SkipTests
)
$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path (Join-Path $PSScriptRoot '../ToSailTheStarrySky.uproject')).Path
$BuildTool = Join-Path $EngineRoot 'Engine/Build/BatchFiles/Build.bat'
$EditorCmd = Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
if (-not (Test-Path $BuildTool)) { throw "Missing Unreal Build.bat at $BuildTool" }
if (-not (Test-Path $EditorCmd)) { throw "Missing UnrealEditor-Cmd.exe at $EditorCmd" }
$Evidence = Join-Path $PSScriptRoot '../Saved/MigrationEvidence'
New-Item -Path $Evidence -ItemType Directory -Force | Out-Null
$GitHead = (git -C (Join-Path $PSScriptRoot '../..') rev-parse HEAD)
$GitHead | Set-Content (Join-Path $Evidence 'head.txt')
& $BuildTool ToSailTheStarrySkyEditor Win64 Development "-Project=$Project" -WaitMutex 2>&1 |
    Tee-Object (Join-Path $Evidence 'build.log')
if ($LASTEXITCODE -ne 0) { throw "Unreal editor build failed ($LASTEXITCODE)" }
if ($SkipTests) { Write-Host 'Build succeeded; automation tests deliberately skipped'; exit 0 }
$ExportArgument = '-ReportExportPath=' + (Join-Path $Evidence 'AutomationReport')
& $EditorCmd $Project -unattended -nop4 -nullrhi '-ExecCmds=Automation RunTests TSTSS; Quit' $ExportArgument -log 2>&1 |
    Tee-Object (Join-Path $Evidence 'automation.log')
if ($LASTEXITCODE -ne 0) { throw "Unreal automation command failed ($LASTEXITCODE)" }
$ReportPath = Join-Path $Evidence 'AutomationReport/index.json'
if (-not (Test-Path $ReportPath)) { throw 'No automation JSON evidence; refusing to mark PASS' }
$Report = Get-Content $ReportPath -Raw | ConvertFrom-Json
if ($Report.failed -gt 0 -or $Report.notRun -gt 0 -or $Report.succeeded -lt 6) {
    throw "Automation evidence incomplete: succeeded=$($Report.succeeded), failed=$($Report.failed), notRun=$($Report.notRun)"
}
Write-Host "Native build and reported automation checks passed at $GitHead. Visual acceptance remains separate."
