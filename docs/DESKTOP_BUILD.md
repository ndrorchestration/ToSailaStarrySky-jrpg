# Aetherwake Windows desktop build

Aetherwake retains its HTTP-served browser path for development and automated smoke testing. The supported player-facing path is a packaged NW.js desktop build.

## For players

1. Download **Aetherwake-OneClick.exe**.
2. Double-click it.
3. Allow the self-extracting launcher to unpack its embedded runtime and start Aetherwake.

The one-click executable opens Aetherwake in its own resizable, maximizable game window. It does not require Python, PowerShell, a manually started HTTP server, or opening an HTML file. The embedded runtime is extracted to a temporary folder when launched.

**Fallback:** **Aetherwake-Windows.zip** is also published for manual extraction. Extract the ZIP completely, then double-click **Aetherwake.exe**. Keep the extracted files together.

## For maintainers

The package is built by GitHub Actions from a tagged commit or by manually dispatching the **Windows desktop package** workflow.

Local build requirements:

- Windows or a compatible NW.js build environment
- Node.js 20+
- npm

Commands:

```powershell
npm install
npm run test:desktop-package
npm run package:windows
```

The workflow creates both the one-click executable and the ZIP fallback, then publishes both as release assets.

## Launch contract

The desktop shell must:

- launch `index-embedded.html`;
- preserve the 960×640 initial canvas;
- run without Python or a separately started HTTP server;
- keep the browser-served path available as a fallback;
- publish `Aetherwake-OneClick.exe` as the primary player artifact;
- fail visibly if packaging or the entry point is invalid.

The packaged build does not change gameplay semantics; it supplies the desktop runtime container.
