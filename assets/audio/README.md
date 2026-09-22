# Aetherwake title theme

Canonical supplied asset:

`Aetherwake - Skyward Arpeggio Main Title.mp3`

Runtime destination:

`assets/audio/aetherwake-skyward-arpeggio-main-title.mp3`

Verified source identity:

- size: **4,233,081 bytes**
- duration: **179.976 seconds**
- sample rate: **48 kHz**
- channels: **stereo**
- SHA-256: `7ac5fe9c2ee0bc8d0cbfa36441dbb7783dbe2ef0cc5e2ee665086a527a7bc350`

## Runtime boundary

`modules/title-music.js` loads this track directly from the canonical embedded runtime. No iframe or alternate desktop launcher is permitted.

Playback is deliberately non-fatal:

- autoplay rejection does not block launch;
- a missing asset does not block launch;
- decode failure does not block launch;
- the controller retries after keyboard/pointer interaction;
- the theme loops only in boot/title-menu states;
- it fades and resets once authored opening/gameplay begins.

## Admission state

The original supplied MP3 is recoverable in the project file stack and its identity above has been verified. The binary must still be admitted to GitHub at the exact runtime destination before title music can be considered repository-complete.
