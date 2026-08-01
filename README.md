# SimplyMind

A simple, offline-first mind map app built with Flutter. One codebase runs on
**Android**, **iOS**, and the **web**.

## Features

- Infinite pan/zoom canvas with draggable nodes and curved connector lines
- Four template modes, switchable at any time:
  - **Map** - free-form canvas, drag nodes anywhere (bezier connectors)
  - **List** - indented outline, top to bottom (elbow connectors)
  - **Step** - numbered sequence with arrows between steps
  - **Graph** - radial auto-layout around the root
- Per-branch template override: any node can lay out its own subtree
  in a different mode than the rest of the map
- Tap to select, double-tap to edit text, drag to move a whole branch
  (in auto-layout modes, reorder siblings with the arrow buttons instead)
- Add child nodes, recolor them from a palette, delete branches
- Undo / redo
- Multiple mind maps: create, rename, duplicate, delete
- All data stored **locally on the device** as JSON
  (SharedPreferences on Android, NSUserDefaults on iOS, localStorage on web)
- Export any map as a `.json` file and import it back on any platform

## JSON format

```json
{
  "id": "map-id",
  "title": "My Ideas",
  "updatedAt": "2026-07-30T22:00:00.000Z",
  "layout": "map",
  "nodePadding": 8,
  "nodes": [
    { "id": "n1", "text": "Central topic", "x": 3000, "y": 3000, "color": 4283391477, "parentId": null },
    { "id": "n2", "text": "Branch idea", "x": 3260, "y": 2900, "color": 4278233238, "parentId": "n1", "layout": "list" }
  ]
}
```

`x`/`y` are canvas coordinates of the node center, `color` is an ARGB integer,
and `parentId: null` marks the root node.

`layout` is one of `"map"`, `"list"`, `"step"`, `"graph"` and selects the
template for the whole map. A node may carry its own optional `layout` field
to override the template for its subtree. When the field is missing the map
defaults to `"map"` and nodes inherit from their nearest ancestor. In auto
layouts (`list`/`step`/`graph`) positions are computed from the tree, and the
stored `x`/`y` are only used again when switching back to `map` mode; sibling
order in the `nodes` array is the display order.

`nodePadding` (2-28, default 8) is the space in pixels between a node's text
and its box border; node boxes grow with it. Adjustable per map from the
editor's settings (tune icon).

## Running

```bash
flutter pub get

# Web (works on any OS)
flutter run -d chrome

# Android (requires Android Studio / Android SDK)
flutter run -d android

# iOS (requires a Mac with Xcode)
flutter run -d ios
```

## Building for release

```bash
flutter build web        # static site in build/web
flutter build appbundle  # Android App Bundle for the Play Store
flutter build apk        # Android APK for direct installs
flutter build ios        # iOS (on macOS)
```

## Releasing a new version

1. Bump `version` in `pubspec.yaml` (e.g. `1.0.1+2` - always increase the
   `+build` number).
2. Rebuild for the platforms you ship.

### Web deployment

`flutter build web` produces a plain static site in `build/web` - upload that
folder to any static host:

- **Netlify Drop** (fastest, no account tooling): drag the `build/web` folder
  onto https://app.netlify.com/drop
- **Firebase Hosting / Vercel / GitHub Pages**: standard static deploys
- **Own server (Apache/nginx/XAMPP)**: copy `build/web` into the web root

Recommended cache headers: serve `index.html` and `version.json` with
`Cache-Control: no-cache` so browsers revalidate; other assets can be cached.

**Automatic updates on web:** each build embeds its version in `version.json`.
The page polls it (on tab focus and every 5 minutes) and shows an
"Update" banner when a newer deploy is live - one click reloads the app.

### App icon

The launcher icon lives in `assets/icon/app_icon.png`. After replacing it run:

```bash
dart run flutter_launcher_icons
```

to regenerate all Android/iOS/web icon sizes.

### Store distribution

- **Android (Play Store):** create a signing keystore, upload the app bundle
  to the Play Console. Users receive updates automatically via the store.
- **iOS (App Store):** requires a Mac (or a CI service such as Codemagic) and
  an Apple Developer account; ship betas via TestFlight. Updates are also
  handled automatically by the store.

## Project structure

```
lib/
  main.dart                     app entry + theme
  models/mind_map.dart          MindMap / MindMapNode, JSON (de)serialization
  storage/mind_map_storage.dart local persistence layer
  storage/json_transfer.dart    export / import as .json files
  state/editor_controller.dart  editor state, undo/redo, autosave
  screens/home_screen.dart      list of saved mind maps
  screens/editor_screen.dart    the mind map canvas editor
```
