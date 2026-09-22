# Aetherwake Windows desktop build

Aetherwake retains its HTTP-served browser path for development and automated smoke testing. The supported player-facing path is a packaged NW.js desktop build.

## For players

1. Download **Aetherwake-Windows.zip**.
2. Extract the ZIP completely to a normal folder.
3. Open the extracted folder.
4. Double-click **Aetherwake.exe**.

The executable opens Aetherwake in its own resizable, maximizable game window. Do not open `index.html` or `index-embedded.html`; those are development/fallback files. Do not run the executable from inside the ZIP. Keep the extracted folder intact because the executable loads the game files beside it.

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

The output is placed under `dist/`. The workflow compresses the generated package as `Aetherwake-Windows.zip`.

## Launch contract

The desktop shell must:

- launch `index-embedded.html`;
- preserve the 960×640 initial canvas;
- run without Python or a separately started HTTP server;
- keep the browser-served path available as a fallback;
- fail visibly if packaging or the entry point is invalid.

The packaged build does not change gameplay semantics; it supplies the desktop runtime container.
