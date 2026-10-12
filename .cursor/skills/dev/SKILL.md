---
name: dev
description: >-
  Start both SimplyMind (Flutter web) and dbdiagram (Vite/React) dev servers on
  the ports the integration expects (Flutter 4123, Vite 5173). Use when the
  user asks to "run the app", "start dev", "spin up the servers", or wants to
  test the home-screen DB Diagram icon locally.
---

# Dev — start SimplyMind + dbdiagram locally

SimplyMind links to dbdiagram at a well-known URL. In debug (`kDebugMode`) the
AppBar icon opens `http://localhost:5173/`, so **both servers must be running
on the exact ports below** for the integration to work.

| App | Command | URL |
|---|---|---|
| dbdiagram (Vite/React) | `npm --prefix dbdiagram run dev` | `http://localhost:5173/` |
| SimplyMind (Flutter web) | `flutter run -d web-server --web-port=4123 --web-hostname=127.0.0.1` | `http://127.0.0.1:4123/` |

## Steps

1. **Pre-flight check** (fast, do once per fresh clone):
   - `Test-Path dbdiagram\node_modules` — if `False`, run `npm --prefix dbdiagram install` first.
   - `Test-Path .dart_tool` — if `False`, run `flutter pub get` first.

2. **Start Vite first** (background, port 5173):
   ```powershell
   npm --prefix dbdiagram run dev
   ```
   Watch for `Local:   http://localhost:5173/` in the output before moving on.

3. **Start Flutter second** (background, port 4123):
   ```powershell
   flutter run -d web-server --web-port=4123 --web-hostname=127.0.0.1
   ```
   Watch for `lib\main.dart is being served at http://127.0.0.1:4123`.

4. **Smoke-test both URLs** before telling the user they're ready:
   ```powershell
   try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 http://127.0.0.1:4123/).StatusCode } catch { "ERR: $_" }
   try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 http://localhost:5173/).StatusCode } catch { "ERR: $_" }
   ```
   Both should return `200`.

5. **Report back** to the user with the two URLs and remind them that the
   DB Diagram icon in the SimplyMind AppBar will navigate to the Vite server
   because `kDebugMode` is true.

## Port troubleshooting

- `errno = 10048` (bind failed, address in use) → something is already on that
  port. Kill it or pick another and tell the user the override.
- `errno = 10013` (access forbidden) → Windows reserved port range
  (common for 8000–8999). Pick a port in 4000–5999 or 9000+.
- Do **not** use `-d chrome` from a background shell — Chrome will not attach
  back to the Flutter debug service and the launcher hangs forever at
  "Waiting for connection from debug service on Chrome…". Use `-d web-server`
  and let the user open the URL in their own Chrome window.

## Integration quirk — Cursor's in-IDE browser

When testing the DB Diagram icon from the **Cursor browser** (not real Chrome),
`window.open(url, '_self')` is blocked for cross-origin targets, so the icon
appears to do nothing (the Material ripple still fires). This is a Cursor
browser limitation, **not a bug** — tell the user to test the click in a
real Chrome tab.

## Shutdown

- Hot reload Flutter with `r`, restart with `R`, quit with `q` in that terminal.
- Stop Vite with `Ctrl+C` in its terminal. Or by PID:
  `Stop-Process -Id <pid> -Force`.
