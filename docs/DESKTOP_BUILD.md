# Aetherwake Windows desktop build

Aetherwake retains its browser path for development and automated smoke testing. The simplest player-facing path is a packaged NW.js Windows build.

## For players

Use the `Aetherwake-Windows` artifact produced by the **Windows desktop package** GitHub Actions workflow. Download and extract the ZIP completely, then double-click:

`Aetherwake.exe`

Do not run the executable from inside the ZIP. Keep the extracted files together because the NW.js application loads its packaged resources from that directory.

## For maintainers

The package is built automatically on `dev/progression-build` and `main`, from version tags, or by manually dispatching the **Windows desktop package** workflow.

Local build requirements:

- Windows or a compatible NW.js build environment
- Node.js 22+
- npm

Commands:

```powershell
npm install
npm run test:all
npm run test:desktop-package
npm run package:windows
```

The build output is intentionally placed outside the repository at `../aetherwake-dist`. This prevents the packager from recursively including its own generated output. GitHub Actions verifies that the NW.js output root contains `Aetherwake.exe` and the non-empty `package.nw` application archive, then compresses the entire output root as `Aetherwake-Windows.zip`.

## Launch contract

The desktop package must:

- launch `index-embedded.html`;
- preserve the 960×640 initial window;
- run without Python, PowerShell, or a separately started HTTP server;
- include the tracked application icon;
- preserve the browser-served path as a development fallback;
- fail the packaging workflow if the executable or packaged application archive is absent or empty.

Packaging does not change gameplay semantics. A desktop artifact is considered established only when both the normal Aetherwake smoke workflow and the Windows desktop packaging workflow pass for the same source state.
