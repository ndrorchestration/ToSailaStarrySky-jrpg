# Aetherwake Windows desktop build

Aetherwake retains its HTTP-served browser path for development and automated smoke testing. The supported player-facing path is a packaged NW.js desktop build.

## For players

1. Download **Aetherwake-Setup.exe** from a Windows desktop release.
2. Run the installer and choose the install location if needed.
3. Launch Aetherwake from the created desktop or Start Menu shortcut.

The standard installer installs the packaged runtime and does not require Python, PowerShell, a manually started HTTP server, or opening an HTML file.

**Fallback:** **Aetherwake-Windows.zip** is also published for manual extraction. Extract the ZIP completely, then run **Aetherwake.exe** from the extracted folder. Keep the extracted files together.

Do not use superseded self-extracting/SFX artifacts. If Windows Defender flags an artifact, do not whitelist or bypass it; preserve the exact detection name and SHA-256 for a false-positive report.

## For maintainers

The package is built by GitHub Actions from a tagged commit or by manually dispatching the **Windows desktop package** workflow. The workflow builds the NW.js package, compiles the standard Inno Setup installer, installs and launches that installer in CI, and publishes the installer plus ZIP fallback for tagged/manual releases.

Local build requirements:

- Windows or a compatible NW.js build environment
- Node.js 22+
- npm

Local commands:

~~~powershell
npm ci
npm run test:desktop-package
npm run package:windows
~~~

## Launch contract

The desktop shell must:

- launch index-embedded.html;
- preserve the 960×640 initial canvas;
- run without Python or a separately started HTTP server;
- keep the browser-served path available as a fallback;
- publish Aetherwake-Setup.exe as the primary player artifact;
- publish Aetherwake-Windows.zip as the manual fallback;
- fail visibly if packaging or the entry point is invalid.

The packaged build does not change gameplay semantics; it supplies the desktop runtime container.
