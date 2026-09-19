# Launch and startup troubleshooting

## Canonical launch

From the repository root—the folder containing `index-embedded.html`, `aetherwake.js`, `p5.min.js`, and `modules/`—run:

```powershell
py -m http.server 8080
```

Open:

```
http://127.0.0.1:8080/index-embedded.html
```

## If the screen is blank

Use the exact URL above, then hard-refresh with `Ctrl+Shift+R`.

If startup fails, the game should display **AETHERWAKE COULD NOT START** with the failure category. The full details are also in the browser console (`F12` → **Console**).

For additional startup diagnostics, append:

```
?debug=1
```

Example:

```
http://127.0.0.1:8080/index-embedded.html?debug=1
```

## Common causes

- The server is running in the wrong folder.
- `index.html` was opened instead of `index-embedded.html`.
- The repository was not fully extracted.
- JavaScript is disabled or blocked by an extension.
- The browser is serving a stale cached copy.
- A required script request returns 404.
- The runtime throws during world, party, combat, or character-creation initialization.

## Expected healthy startup

The loading screen transitions to the Aetherwake canvas, then the title/menu appears. Press `N`, `Enter`, or `Space` to continue.

## Verification contract

CI must continue to assert:

- the canvas reaches 960×640;
- `window._setupOrder` reaches `setup-done`;
- `window._charcreate`, `window._combat`, and `window._world` are initialized;
- browser console/page errors fail the smoke test.
