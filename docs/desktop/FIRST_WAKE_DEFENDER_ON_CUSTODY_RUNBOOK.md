# First Wake — Defender-on exact-artifact custody runbook

**Status:** review-only procedure. Does not authorize release, override GitHub CI, or certify any current installer. See [installer delivery gates](FIRST_WAKE_INSTALLER_DELIVERY.md). This is for an authorized maintainer and a trusted Windows test machine, not for players.

## Preconditions and stop rules

- Bind to one frozen PR commit and the **actual installer bytes**. The old PR #551 functional SHA `dd96cbc6669aa899383db770cc5b1b917db29ac684096fe5aa5e13dd9521a2ec` refers to runner-local *unsigned* development output; it is not a current public download nor automatically the hash of any rebuilt or signed installer.
- Use Windows with a functioning Microsoft Defender Antivirus and real-time protection **enabled**. An unavailable cmdlet, disabled antivirus, disabled realtime protection, incomplete scan, detection, hash mismatch, missing logs or uncertain custody means **BLOCKED**, never PASS.
- Do not disable Defender, add scan exclusions, elevate an untrusted setup, run from an unknown mirror, relax the existing `exact-windows-qa` job, or treat a successful functional job as security clearance.
- If policy prevents compliant hosted execution, preserve the hosted red check and run separate *maintainer-attested* evidence on a trusted machine. This is not the same as claiming GitHub CI green.

## Acquire and identify

1. Record tester identity, UTC date, machine provenance/ownership, OS build, tool versions, exact Git source SHA, commit and build inputs, pinned Godot editor/template digests, NSIS version, and installer build transcript. Obtain the installer through an authenticated, controlled channel; **do not** use historical Aetherwake release files or assume a runner-local artifact URL is public.
2. Calculate the installer SHA-256 and independently compare it with the approved build manifest. Record the exported Godot EXE and uninstaller hashes as available. Capture all receipts into an access-controlled evidence directory. Avoid exposing private usernames, machine identifiers or signing secrets in public logs.
3. In PowerShell (interactive, on the **trusted verification host**) run:

```powershell
$ErrorActionPreference = 'Stop'
$commands = @('Get-MpComputerStatus','Start-MpScan','Get-MpThreatDetection','Get-WinEvent')
foreach ($command in $commands) {
  if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
    throw "DEFENDER_COMMAND_MISSING:$command"
  }
}
$mp = Get-MpComputerStatus
$mp | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AMProductVersion,AMEngineVersion,AntivirusSignatureVersion,AntivirusSignatureLastUpdated | Format-List
if (-not [bool]$mp.AntivirusEnabled -or -not [bool]$mp.RealTimeProtectionEnabled) {
  throw 'DEFENDER_ON_CUSTODY_NOT_ESTABLISHED'
}
Get-WinEvent -ListLog 'Microsoft-Windows-Windows Defender/Operational' | Out-Null
```

4. With the trusted installer location supplied by the maintainer, compute its digest then perform the intended scan. **A command returning does not by itself establish a clean result**: retain scan output, Defender Operational events and threat-detection review, including scan completion, exact path, detections and errors. Re-check realtime protection after the scan.

```powershell
$installer = 'C:\trusted-review\ToSailTheStarrySky-Setup.exe'  # replace with the real inspected path
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw 'INSTALLER_NOT_FOUND' }
Get-FileHash -LiteralPath $installer -Algorithm SHA256
Start-MpScan -ScanType CustomScan -ScanPath $installer -ErrorAction Stop
Get-MpThreatDetection
(Get-MpComputerStatus) | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureVersion
```

5. Repeat appropriate scanning and evidence collection for the actual exported executable, uninstaller, source/build inputs as required by release policy, and **final signed distributable**. The installer may contain payloads not independently exposed by scanning its outer PE; validate installed content on the controlled test machine. Verify signed binaries with `Get-AuthenticodeSignature`, including trusted publisher identity, signature status and timestamp policy. Do not store private keys in repository or CI logs.
6. On a clean test profile, verify final signed distribution hash and signature before executing. Exercise install, actual native game launch/first frame, resize/maximize/fullscreen, F5/F9 save restore, repeated setup refusal, and uninstall without damaging unrelated data. Capture exact signed hashes and results. Signing/repacking changes bytes and invalidates the previous unsigned artifact's identity.

## Minimum evidence bundle

| Evidence | Required proof |
|---|---|
| Source/build identity | Commit SHA, pinned toolchain and dependency digests, build log |
| Host custody | Owned/trusted host, Windows build, UTC time, Defender AV and realtime **true** both before and after |
| Defender scan | Scan target SHA-256, complete scan disposition, definition/engine versions, threat and operational event review |
| Distribution integrity | Final signed Setup.exe, game and uninstaller hashes, verified Authenticode identities |
| Functional native QA | Exact signed bytes installed, game window and persistence tested, uninstall result |
| Human acceptance | Creator visual decision and independent uncoached player decision linked to final candidate |
| Approval | Exact tag, hashes, release notes and explicit creator authorization |

Mark each evidence field **PASS / FAIL / NOT ESTABLISHED**, not a blanket PASS. If any required field is absent, publication remains blocked. Only after every separate gate is satisfied and the creator explicitly approves the exact public prerelease may a publisher attach assets, verify public redownload and add the README link.
