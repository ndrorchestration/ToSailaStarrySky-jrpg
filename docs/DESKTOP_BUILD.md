# Aetherwake Windows desktop build

Aetherwake retains its browser path for development and automated smoke testing. The preferred player-facing Windows path is now a **single self-contained launcher executable** wrapped around the verified NW.js runtime.

## For players

Use the `Aetherwake-One-File` artifact produced by the **Windows desktop package** GitHub Actions workflow. GitHub delivers Actions artifacts as ZIP downloads, so extract that download once. Inside it there is exactly one player-facing file:

`Aetherwake - The Last Solarpunk Airship.exe`

Double-click that file. No Python, PowerShell, Node.js, local HTTP server, or manually managed game folder is required.

On first launch, the executable silently extracts the verified NW.js runtime into a private content-addressed directory under your local AppData folder and starts `Aetherwake.exe` from there. Later launches reuse the matching cached runtime. A changed embedded build receives a different cache directory automatically.

The launcher uses the Aetherwake emblem as its Windows application icon.

### Folder-package fallback

The workflow also retains the older `Aetherwake-Windows` artifact. That artifact contains the raw NW.js runtime and is useful for debugging or packaging verification. It must be extracted completely before launching its inner `Aetherwake.exe`.

## For maintainers

The package is built automatically on `dev/progression-build` and `main`, from version tags, or by manually dispatching the **Windows desktop package** workflow.

The pipeline:

1. stages the minimal Aetherwake runtime;
2. builds and verifies the normal NW.js Windows package;
3. creates a ZIP payload from that verified package;
4. generates the Windows icon from the tracked Aetherwake emblem;
5. publishes a self-contained .NET 8 Windows launcher with the payload embedded;
6. renames the single executable to `Aetherwake - The Last Solarpunk Airship.exe`;
7. verifies the one-file artifact contains exactly that executable.

The launcher source lives under `packaging/one-file-launcher/`. It extracts only under `%LOCALAPPDATA%\Aetherwake\runtime\<payload-hash>`, validates archive paths against zip-slip traversal, and starts the existing NW.js `Aetherwake.exe` without changing gameplay semantics.

Useful verification commands:

```powershell
npm install
npm run test:desktop-package
npm run test:one-file-launcher
npm run package:windows
```

The GitHub workflow also configures .NET 8 for the single-file publish stage.

## Launch contract

The player-facing one-file package must:

- consist of exactly one recognizable executable;
- be named `Aetherwake - The Last Solarpunk Airship.exe`;
- carry the Aetherwake Windows icon;
- require no local development server or developer tooling;
- embed the already-verified NW.js runtime rather than fork gameplay code;
- use a content-addressed private runtime cache;
- fail visibly if the embedded runtime is missing or cannot be prepared.

The folder-based `Aetherwake-Windows` artifact remains a fallback and diagnostic package.

Packaging does not change gameplay semantics. A one-file artifact is considered established only when its contract checks and the Windows desktop packaging workflow pass for the same source state.
