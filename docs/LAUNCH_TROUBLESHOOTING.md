# Launch and startup troubleshooting

## Player launch authority

The primary Windows player artifact is the standard **Aetherwake Setup** installer.
Install it normally, then launch **Aetherwake.exe** from the Desktop or Start Menu.
Do not bypass antivirus protection for old self-extracting/SFX artifacts.

## Expected healthy startup

A healthy launch shows the loading screen briefly, creates the 960×640 game canvas,
completes runtime setup, then reveals Aetherwake. The loading overlay is not allowed
to disappear until the runtime records `setup-done`.

## If Aetherwake cannot start

Current builds fail visibly instead of silently revealing a blank window. The
failure screen begins with:

`AETHERWAKE COULD NOT START`

and reports either a JavaScript startup error, an unhandled promise rejection, or
a startup timeout. Record that message when reporting a launch problem.

Recommended recovery:

1. Close Aetherwake.
2. Reinstall the latest standard Aetherwake Setup build.
3. Launch the installed `Aetherwake.exe` normally.
4. If the same visible failure recurs, preserve the exact error text and build identity.

## Development HTML diagnostics

The browser/dev entry point remains `index-embedded.html`. For development only,
serve the repository root over HTTP and append `?debug=1` to expose the diagnostic
overlay. Opening extracted temporary ZIP paths or treating a `file://` URL as the
primary player experience is not the supported Windows handoff.

## Verification contract

CI requires all of the following before startup is considered healthy:

- a 960×640 canvas exists;
- `window._setupOrder` reaches `setup-done`;
- First Wake, combat, and world runtime surfaces initialize;
- the loading overlay is hidden only after setup completes;
- no startup failure panel is present;
- browser console/page errors fail smoke verification.
