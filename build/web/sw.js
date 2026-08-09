'use strict';

// SimplyMind offline service worker.
// Precaches the app shell on install. Same-origin GETs use stale-while-
// revalidate so the first online visit fills the cache (main.dart.js,
// CanvasKit, fonts, assets) and later launches work offline. version.json
// stays network-only so the in-page update banner still works.

const CACHE_NAME = 'simplymind-v1';

const PRECACHE_URLS = [
  './',
  './index.html',
  './flutter_bootstrap.js',
  './flutter.js',
  './main.dart.js',
  './manifest.json',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
  './privacy.html',
  './dmca.html',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      await Promise.all(
        PRECACHE_URLS.map(async (url) => {
          try {
            const response = await fetch(url, { cache: 'reload' });
            if (response.ok) {
              await cache.put(url, response);
            }
          } catch (_) {
            // Ignore missing files during install; runtime caching will fill gaps.
          }
        }),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key)),
      );
      await self.clients.claim();
    })(),
  );
});

function isVersionJson(url) {
  return url.pathname.endsWith('/version.json') ||
      url.pathname.endsWith('version.json');
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Keep update checks live; fail silently when offline (banner handles null).
  if (isVersionJson(url)) {
    event.respondWith(fetch(request));
    return;
  }

  // App navigations: prefer network, fall back to cached shell.
  if (request.mode === 'navigate') {
    event.respondWith(
      (async () => {
        try {
          const fresh = await fetch(request);
          const cache = await caches.open(CACHE_NAME);
          if (fresh.ok) {
            cache.put('./index.html', fresh.clone());
          }
          return fresh;
        } catch (_) {
          const cache = await caches.open(CACHE_NAME);
          return (
            (await cache.match('./index.html')) ||
            (await cache.match('index.html')) ||
            (await cache.match('./')) ||
            Response.error()
          );
        }
      })(),
    );
    return;
  }

  // Assets: cache-first, refresh in background when online.
  event.respondWith(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      const cached = await cache.match(request);

      const networkPromise = fetch(request)
          .then((response) => {
            if (response && response.ok) {
              cache.put(request, response.clone());
            }
            return response;
          })
          .catch(() => null);

      if (cached) {
        // Kick off revalidation; do not await.
        networkPromise;
        return cached;
      }

      const fresh = await networkPromise;
      return fresh || Response.error();
    })(),
  );
});
