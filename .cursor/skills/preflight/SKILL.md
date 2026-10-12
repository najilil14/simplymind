---
name: preflight
description: >-
  Build both SimplyMind (Flutter web) and dbdiagram (Vite/React) locally in
  release mode, mirror the CI merge step, and verify there are no obvious
  breakages before the user pushes to main. Use when the user asks to
  "verify before push", "preflight", "test the build", "simulate CI", or
  wants confidence a push will not break production.
---

# Preflight — build & verify before pushing to main

Pushing to `main` triggers `.github/workflows/deploy.yml`, which publishes to
`gh-pages` and the live site at `https://simplymind.nzilo.com`. This skill
reproduces the CI build steps locally so broken deploys get caught before the
push, not after.

## Steps

Copy this checklist and track progress:

```
Preflight progress:
- [ ] 1. Verify tree is clean / inspect staged changes
- [ ] 2. flutter pub get (if dependencies changed)
- [ ] 3. flutter analyze (fast lint pass)
- [ ] 4. flutter build web --release --base-href "/"
- [ ] 5. npm --prefix dbdiagram ci
- [ ] 6. npm --prefix dbdiagram run build
- [ ] 7. Merge dbdiagram/dist into build/web/dbdiagram (mirrors CI)
- [ ] 8. Spot-check build/web/index.html and build/web/dbdiagram/index.html
- [ ] 9. Report go / no-go to user, do NOT push automatically
```

### 1. Inspect current state

```powershell
git status
git diff --cached --stat   # if changes are staged
```

Call out anything surprising (build artifacts, large binaries, secrets).

### 2–4. Flutter side

```powershell
flutter pub get
flutter analyze
flutter build web --release --base-href "/"
```

Flags:
- Any `analyze` error → stop, report, do not continue.
- `build web` must exit 0 and produce `build/web/index.html` plus
  `build/web/main.dart.js`.

### 5–6. dbdiagram side

```powershell
npm --prefix dbdiagram ci
npm --prefix dbdiagram run build
```

`npm run build` runs `tsc --noEmit && vite build`. Any TypeScript error or
Vite bundling error → stop and report.

### 7. Mirror the CI merge step

```powershell
Remove-Item -Recurse -Force build\web\dbdiagram -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path build\web\dbdiagram | Out-Null
Copy-Item -Recurse dbdiagram\dist\* build\web\dbdiagram\
```

### 8. Spot-check the merged output

```powershell
Test-Path build\web\index.html
Test-Path build\web\dbdiagram\index.html
Select-String -Path build\web\dbdiagram\index.html -Pattern '/dbdiagram/assets/' | Select-Object -First 3
```

The grep must find `/dbdiagram/assets/...` references. If it finds `/assets/`
instead, the Vite `base` config regressed — fix `dbdiagram/vite.config.ts`
before pushing.

### 9. Report

Produce a short go / no-go summary. Example green report:

```
Preflight: GREEN
- flutter analyze: 0 issues
- flutter build web: build/web/main.dart.js = 2.1 MB
- vite build: build/web/dbdiagram/assets/index-abc.js = 480 KB
- /dbdiagram/ base confirmed in dbdiagram/index.html
Safe to: git push origin main
```

**Never run `git push` automatically from this skill.** Hand control back
to the user.

## When to skip steps

- Only Flutter files changed → skip steps 5–7 if time matters, but **run them
  anyway if the diff touches `.github/workflows/deploy.yml`,
  `dbdiagram/vite.config.ts`, or `web/sw.js`**.
- Only dbdiagram files changed → steps 2–4 are still worth running because
  `flutter build web` is cheap on a warm cache and catches drift.

## Notes

- `build/` is currently tracked in git (unusual, intentional per repo history);
  the preflight updates it in place but **does not stage it**. Decide with the
  user whether to include the regenerated `build/` in the push.
- `npm ci` requires `dbdiagram/package-lock.json` to exist and match
  `package.json`. If it fails, run `npm --prefix dbdiagram install` to update
  the lockfile, then commit the lockfile separately.
