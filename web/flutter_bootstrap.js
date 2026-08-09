{{flutter_js}}
{{flutter_build_config}}

// Custom bootstrap: skip Flutter's deprecated cleanup service worker and
// always load CanvasKit from the local build/ so the installed PWA works
// offline (CDN canvaskit would fail without a network).
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});
