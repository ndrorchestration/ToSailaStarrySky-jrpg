# First Wake security custody preflight: read-only verification; NEVER authorizes publication.
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$InstallerPath,
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedSha256,
  [Parameter(Mandatory = $true)][ValidatePattern('^[a-fA-F0-9]{40}$')][string]$SourceCommit,
  [string]$ReceiptPath = ''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$receipt = [ordered]@{
  schema = 'tstss-defender-custody-preflight-v1'
  timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
  source_sha = $SourceCommit.ToLowerInvariant()
  installer_sha256_expected = $ExpectedSha256.ToLowerInvariant()
  installer_sha256_observed = $null
  defender_av_enabled_before = $false
  defender_realtime_enabled_before = $false
  defender_av_enabled_after = $false
  defender_realtime_enabled_after = $false
  defender_engine_version = $null
  defender_signature_version = $null
  defender_operational_log_accessible = $false
  signature_status = 'NOT_ESTABLISHED'
  custody_preflight = 'BLOCKED'
  defender_scan = 'NOT_PERFORMED'
  human_acceptance = 'NOT_ESTABLISHED'
  release_authorized = $false
  failure = $null
}
try {
  if ($env:OS -ne 'Windows_NT') { throw 'WINDOWS_HOST_REQUIRED' }
  foreach ($command in @('Get-MpComputerStatus','Get-WinEvent','Get-FileHash','Get-AuthenticodeSignature')) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "REQUIRED_COMMAND_MISSING:$command" }
  }
  $file = (Resolve-Path -LiteralPath $InstallerPath -ErrorAction Stop).ProviderPath
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw 'INSTALLER_NOT_A_FILE' }
  $observed = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
  $receipt.installer_sha256_observed = $observed
  if ($observed -ne $ExpectedSha256.ToLowerInvariant()) { throw 'INSTALLER_SHA256_MISMATCH' }
  $status = Get-MpComputerStatus -ErrorAction Stop
  $receipt.defender_av_enabled_before = [bool]$status.AntivirusEnabled
  $receipt.defender_realtime_enabled_before = [bool]$status.RealTimeProtectionEnabled
  $receipt.defender_engine_version = [string]$status.AMEngineVersion
  $receipt.defender_signature_version = [string]$status.AntivirusSignatureVersion
  if (-not $receipt.defender_av_enabled_before) { throw 'DEFENDER_ANTIVIRUS_DISABLED' }
  if (-not $receipt.defender_realtime_enabled_before) { throw 'DEFENDER_REALTIME_DISABLED' }
  $null = Get-WinEvent -ListLog 'Microsoft-Windows-Windows Defender/Operational' -ErrorAction Stop
  $receipt.defender_operational_log_accessible = $true
  $signature = Get-AuthenticodeSignature -LiteralPath $file -ErrorAction Stop
  $receipt.signature_status = [string]$signature.Status
  if ($signature.Status -ne 'Valid') { throw 'INSTALLER_AUTHENTICODE_NOT_VALID' }
  $after = Get-MpComputerStatus -ErrorAction Stop
  $receipt.defender_av_enabled_after = [bool]$after.AntivirusEnabled
  $receipt.defender_realtime_enabled_after = [bool]$after.RealTimeProtectionEnabled
  if (-not $receipt.defender_av_enabled_after -or -not $receipt.defender_realtime_enabled_after) {
    throw 'DEFENDER_CUSTODY_LOST'
  }
  $receipt.custody_preflight = 'PASS'
  Write-Host 'TSTSS_DEFENDER_ON_CUSTODY_PREFLIGHT=PASS'
  Write-Host 'TSTSS_DEFENDER_SCAN=NOT_PERFORMED'
  Write-Host 'TSTSS_PUBLIC_RELEASE_AUTHORIZED=NO'
} catch {
  $receipt.failure = $_.Exception.Message
  Write-Error "TSTSS_DEFENDER_ON_CUSTODY_PREFLIGHT=BLOCKED:$($receipt.failure)" -ErrorAction Continue
} finally {
  if ($ReceiptPath) {
    $full = [IO.Path]::GetFullPath($ReceiptPath)
    $parent = Split-Path -Parent $full
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $receipt | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $full -Encoding utf8
  }
}
if ($receipt.custody_preflight -ne 'PASS') { exit 1 }
