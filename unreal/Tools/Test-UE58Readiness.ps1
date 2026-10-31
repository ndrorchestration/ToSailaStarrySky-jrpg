param(
    [string]$EngineRoot = 'C:\Program Files\Epic Games\UE_5.8',
    [switch]$Json
)
$ErrorActionPreference = 'Stop'
$Checks = [ordered]@{}
$VersionPath = Join-Path $EngineRoot 'Engine/Build/Build.version'
$BuildBat = Join-Path $EngineRoot 'Engine/Build/BatchFiles/Build.bat'
$EditorCmd = Join-Path $EngineRoot 'Engine/Binaries/Win64/UnrealEditor-Cmd.exe'
$Checks.EngineVersionFile = Test-Path $VersionPath
$Checks.EngineBuildBatch = Test-Path $BuildBat
$Checks.EngineEditorCommand = Test-Path $EditorCmd
$Checks.EngineVersionIs58 = $false
$EngineVersion = $null
if ($Checks.EngineVersionFile) {
    try {
        $Version = Get-Content $VersionPath -Raw | ConvertFrom-Json
        $EngineVersion = "$($Version.MajorVersion).$($Version.MinorVersion)"
        $Checks.EngineVersionIs58 = ($Version.MajorVersion -eq 5 -and $Version.MinorVersion -eq 8)
    } catch {
        $Checks.EngineVersionIs58 = $false
    }
}
$ProgramFilesX86 = [Environment]::GetFolderPath('ProgramFilesX86')
$VsWhere = Join-Path $ProgramFilesX86 'Microsoft Visual Studio/Installer/vswhere.exe'
$Checks.VsWherePresent = Test-Path $VsWhere
$Checks.MsvcToolchainPresent = $false
$VisualStudioPath = $null
if ($Checks.VsWherePresent) {
    $Result = @(& $VsWhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null)
    if ($LASTEXITCODE -eq 0 -and $Result.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Result[0])) {
        $VisualStudioPath = [string]$Result[0]
        $Checks.MsvcToolchainPresent = $true
    }
}
$Checks.WindowsSdkIncludePresent = $false
$SdkRoot = Join-Path $ProgramFilesX86 'Windows Kits/10/Include'
if (Test-Path $SdkRoot) {
    $Checks.WindowsSdkIncludePresent = @(Get-ChildItem $SdkRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^10\.0\.\d+\.0$' -and [version]$_.Name -ge [version]'10.0.22621.0' }).Count -gt 0
}
$IsReady = !(@($Checks.Values) -contains $false)
$Report = [ordered]@{
    EngineRoot = $EngineRoot
    EngineVersion = $EngineVersion
    VisualStudioPath = $VisualStudioPath
    Checks = $Checks
    ReadyForPinnedBuild = $IsReady
}
if ($Json) {
    $Report | ConvertTo-Json -Depth 6
} else {
    foreach ($Key in $Checks.Keys) {
        Write-Output "$Key=$($Checks[$Key])"
    }
    Write-Output "EngineVersion=$EngineVersion"
    Write-Output "VisualStudioPath=$VisualStudioPath"
    Write-Output "ReadyForPinnedBuild=$IsReady"
}
if (-not $IsReady) { exit 2 }
exit 0
