param(
    [Parameter(Mandatory=$true)][string]$EngineRoot,
    [switch]$SkipTests,
    [switch]$BuildGameTarget
)
$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path (Join-Path $PSScriptRoot '../ToSailTheStarrySky.uproject')).Path
$BuildTool = Join-Path $EngineRoot 'Engine/Build/BatchFiles/Build.bat'
$EditorCmd = Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
if (-not (Test-Path $BuildTool)) { throw "Missing Unreal Build.bat at $BuildTool" }
if (-not (Test-Path $EditorCmd)) { throw "Missing UnrealEditor-Cmd.exe at $EditorCmd" }
$Evidence = Join-Path $PSScriptRoot '../Saved/MigrationEvidence'
$GitHead = (git -C (Join-Path $PSScriptRoot '../..') rev-parse HEAD)
if ($LASTEXITCODE -ne 0 -or -not $GitHead) { throw 'Unable to resolve repository HEAD' }
$WorkingTree = @(git -C (Join-Path $PSScriptRoot '../..') status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect working tree' }
if ($WorkingTree.Count -gt 0) { throw 'Working tree has uncommitted changes; evidence cannot be bound to HEAD' }
New-Item -Path $Evidence -ItemType Directory -Force | Out-Null
$GitHead | Set-Content (Join-Path $Evidence 'head.txt')
& $BuildTool ToSailTheStarrySkyEditor Win64 Development "-Project=$Project" -WaitMutex 2>&1 |
    Tee-Object (Join-Path $Evidence 'build.log')
if ($LASTEXITCODE -ne 0) { throw "Unreal editor build failed ($LASTEXITCODE)" }
if ($BuildGameTarget) {
    & $BuildTool ToSailTheStarrySky Win64 Development "-Project=$Project" -WaitMutex 2>&1 |
        Tee-Object (Join-Path $Evidence 'game-target-build.log')
    if ($LASTEXITCODE -ne 0) { throw "Unreal game target build failed ($LASTEXITCODE)" }
}
if ($SkipTests) { Write-Host 'Editor build succeeded; automation tests deliberately skipped. No gameplay, rendering or packaging proof.'; exit 0 }
# Count authored TSTSS automation declarations instead of accepting a stale fixed
# minimum as the suite grows. This is a *lower bound*, not a substitute for
# matching individual test identities in a native AutomationReport.
$SourceRoot = Join-Path $PSScriptRoot '../Source/ToSailTheStarrySky/Private'
$TestDeclarations = @(
    Get-ChildItem -Path $SourceRoot -Filter '*Tests.cpp' -Recurse -File |
        ForEach-Object {
            [regex]::Matches((Get-Content $_.FullName -Raw),
                'IMPLEMENT_SIMPLE_AUTOMATION_TEST\s*\(\s*[^,]+,\s*"(TSTSS\.[^"]+)"') |
                ForEach-Object { $_.Groups[1].Value }
        }
)
if ($TestDeclarations.Count -lt 6) { throw 'Unable to discover expected Unreal automation suite' }
if (@($TestDeclarations | Sort-Object -Unique).Count -ne $TestDeclarations.Count) {
    throw 'Duplicate Unreal automation test identifiers found'
}
$TestDeclarations | Sort-Object | Set-Content (Join-Path $Evidence 'expected-tests.txt')
$ReportDirectory = Join-Path $Evidence 'AutomationReport'
if (Test-Path $ReportDirectory) { Remove-Item $ReportDirectory -Recurse -Force }
New-Item -Path $ReportDirectory -ItemType Directory -Force | Out-Null
$ExportArgument = '-ReportExportPath=' + $ReportDirectory
& $EditorCmd $Project -unattended -nop4 -nullrhi '-ExecCmds=Automation RunTest TSTSS;Quit' $ExportArgument -log 2>&1 |
    Tee-Object (Join-Path $Evidence 'automation.log')
if ($LASTEXITCODE -ne 0) { throw "Unreal automation command failed ($LASTEXITCODE)" }
$ReportPath = Join-Path $Evidence 'AutomationReport/index.json'
if (-not (Test-Path $ReportPath)) { throw 'No automation JSON evidence; refusing to mark PASS' }
$Report = Get-Content $ReportPath -Raw | ConvertFrom-Json
if ($null -eq $Report.succeeded -or $null -eq $Report.failed -or $null -eq $Report.notRun) {
    throw 'Automation report schema missing required summary fields; cannot claim PASS'
}
# Epic's JSON report includes per-test fullTestPath, state, warnings and errors.
# Counts alone are insufficient: an omitted new test could be masked by extras.
if ($null -eq $Report.tests) { throw 'Automation JSON lacks per-test results' }
$Reported = @($Report.tests | Where-Object { $_.fullTestPath -like 'TSTSS.*' })
$ReportedNames = @($Reported | ForEach-Object { [string]$_.fullTestPath })
if (@($ReportedNames | Sort-Object -Unique).Count -ne $ReportedNames.Count) {
    throw 'Duplicate TSTSS result identities in automation report'
}
$Missing = @($TestDeclarations | Where-Object { $_ -notin $ReportedNames })
$Unexpected = @($ReportedNames | Where-Object { $_ -notin $TestDeclarations })
if ($Missing.Count -gt 0 -or $Unexpected.Count -gt 0) {
    throw "Automation identity mismatch: missing=$($Missing -join ', ') unexpected=$($Unexpected -join ', ')"
}
$Unsuccessful = @($Reported | Where-Object {
    $_.state -ne 'Success' -or $_.errors -ne 0 -or $_.warnings -ne 0
})
if ($Unsuccessful.Count -gt 0) {
    throw "TSTSS tests not cleanly successful: $(($Unsuccessful | ForEach-Object { $_.fullTestPath + ':' + $_.state }) -join ', ')"
}
if ($null -ne $Report.inProcess -and $Report.inProcess -ne 0) {
    throw 'Automation report contains tests still in progress'
}
if ($Report.failed -gt 0 -or $Report.notRun -gt 0 -or $Report.succeededWithWarnings -gt 0 -or $Report.succeeded -lt $TestDeclarations.Count) {
    throw "Automation evidence incomplete: succeeded=$($Report.succeeded), failed=$($Report.failed), notRun=$($Report.notRun)"
}
Write-Host "Native build and reported automation checks passed at $GitHead. Visual acceptance remains separate."
