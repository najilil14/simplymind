---
name: deploy-status
description: >-
  Report the status of the SimplyMind + dbdiagram deployment on GitHub Pages:
  latest Actions run, HTTP status of the two live URLs, service-worker cache
  hints, and rollback steps. Use when the user asks "is the deploy up?",
  "did my push ship?", "why is it blank?", or wants a quick deploy
  health check.
---

# Deploy status — Actions, live URLs, SW cache tips

Site layout:

| App | Live URL |
|---|---|
| SimplyMind (Flutter) | `https://simplymind.nzilo.com/` |
| dbdiagram (Vite/React) | `https://simplymind.nzilo.com/dbdiagram/` |

Pipeline: push to `main` → `.github/workflows/deploy.yml` → `gh-pages` branch
→ GitHub Pages serves the merged `build/web`.

## Steps

### 1. Latest CI run

```powershell
gh run list --branch main --limit 3
gh run view --log-failed   # only if the latest run failed
```

Report: run id, commit title, status, duration. If the run is still
in progress, poll with `gh run watch <id>` only if the user explicitly asks
to wait.

### 2. Live URL health

```powershell
try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 https://simplymind.nzilo.com/).StatusCode } catch { "ERR: $_" }
try { (Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 https://simplymind.nzilo.com/dbdiagram/).StatusCode } catch { "ERR: $_" }
```

Both should return `200`. For a deeper check, fetch the HTML and confirm the
asset references are correct:

```powershell
(Invoke-WebRequest -UseBasicParsing https://simplymind.nzilo.com/dbdiagram/).Content | Select-String '/dbdiagram/assets/'
```

If the dbdiagram page references `/assets/...` instead of `/dbdiagram/assets/...`,
Vite's `base` config was lost in the last deploy — rebuild with the preflight
skill and verify `dbdiagram/vite.config.ts` sets
`base: command === 'build' ? '/dbdiagram/' : '/'`.

### 3. "It looks blank in my browser" — the SW cache explanation

SimplyMind registers a service worker scoped at `/`. Returning users have the
previously-installed SW controlling their page until the new one activates.
Symptoms to recognize:

- SimplyMind home loads old UI (no DB Diagram icon).
- `/dbdiagram/` shows a blank page or the Flutter shell.
- Any file served by `web/sw.js` is stale after a deploy.

Give the user **one** of these fixes (do not run them for them unless asked):

1. Visit `https://simplymind.nzilo.com/` first → hard-refresh with
   `Ctrl+Shift+R` → the new SW installs and takes over on reload.
2. DevTools → Application → Service Workers → "Unregister" → reload.
3. DevTools → Application → Storage → "Clear site data" → reload.

The deploy pipeline stamps a new `BUILD_ID` into `web/sw.js` on every push, so
option 1 reliably forces an update.

### 4. Rollback (only if the user asks)

The site is served from the `gh-pages` branch. To roll back:

```powershell
gh run list --workflow "Deploy Flutter SimplyMind Web" --limit 10
# Identify a prior successful run, then re-run it:
gh run rerun <run-id>
```

Alternative: revert the offending commit on `main` and push — CI will
redeploy the previous good state.

### 5. Report format

Produce a compact status block, for example:

```
Deploy status: HEALTHY
- Latest run: 38224038410 "Feat:Integrate dbdiagram app" (success, 2m54s)
- https://simplymind.nzilo.com/           → 200
- https://simplymind.nzilo.com/dbdiagram/ → 200 (asset paths OK)
- Service worker: current BUILD_ID = <sha>
```

If anything is RED, list it first with the exact command the user should run
to recover.

## Notes

- `gh` must be authenticated (`gh auth status`). If not, instruct the user to
  run `gh auth login` — do not attempt to re-authenticate autonomously.
- Do not push, re-run, or roll back without explicit user intent — this skill
  is **read-only by default**.
