# Title audio binary handoff

The exact recovered Aetherwake title theme is already fingerprinted by repository authority. The remaining blocker is **binary transfer into the Git checkout**, not uncertainty about which file is correct.

## Required source

Use the exact file:

`Aetherwake - Skyward Arpeggio Main Title.mp3`

Governed identity:
- SHA-256: `7ac5fe9c2ee0bc8d0cbfa36441dbb7783dbe2ef0cc5e2ee665086a527a7bc350`
- bytes: `4,233,081`
- canonical repository path: `assets/audio/aetherwake-skyward-arpeggio-main-title.mp3`

Do not rename or substitute another encode before admission.

## One-command admission

From a clean checkout of the active candidate branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\admit-title-audio.ps1 -Source "C:\path\to\Aetherwake - Skyward Arpeggio Main Title.mp3" -Commit
```

The wrapper fails closed unless:
- Git HEAD is readable;
- the checkout is on a named branch, not detached HEAD;
- the working tree is clean before mutation;
- the source exists;
- the source passes exact SHA-256 and byte-count preflight **before any repository mutation**;
- only the canonical MP3, governed manifest, and generated runtime registry are staged;
- all three expected paths are staged;
- `test:m0-title-audio-ready` passes before commit;
- the admission commit leaves the checkout clean;
- the strict M0 title-audio gate still passes after commit.

A successful committed admission emits:

`TITLE_AUDIO_ADMISSION=COMMITTED_VERIFIED`

and prints the exact next M0 command.

## Why this is local

The connected GitHub write surface can create blobs only from UTF-8/base64 text supplied directly in the request. It does not provide a trustworthy file-reference-to-binary-repository transfer for the recovered 4.23 MB Library asset. Serializing the MP3 through a large text payload would widen the failure surface and is intentionally not treated as a production-quality admission path.

## After admission

Run the printed next command:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-m0-local.ps1
```

Final M0 remains incomplete until executable verification succeeds, the 54-frame accessibility matrix is human-reviewed, and the uncoached external-player gate is completed.
