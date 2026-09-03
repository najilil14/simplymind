'use strict';

// SimplyMind offline service worker.
// Precaches the app shell on install so launches work offline. Code
// entrypoints (index.html, flutter_bootstrap.js, main.dart.js) are network
// first, so a new deploy is picked up on the next visit instead of being
// pinned to whatever was cached before. Heavy immutable payloads (CanvasKit,
// fonts, assets) stay cache first. version.json is network only so the
// in-page update banner still works.

// Replaced with the commit sha by .github/workflows/deploy.yml. A changing
// cache name is what forces the browser to install this worker again and
// refetch the shell after every deploy.
const BUILD_ID = '3c4f11f9678b04cc650e12b2222459e31ebb5a5f';
const CACHE_NAME = 'simplymind-' + BUILD_ID;

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
  './guide.html',
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
  return url.pathname.endsWith('version.json');
}

// Files that carry app code and must never outlive a deploy.
function isCodeEntrypoint(url) {
  const path = url.pathname;
  return (
    path.endsWith('/') ||
    path.endsWith('.html') ||
    path.endsWith('/flutter_bootstrap.js') ||
    path.endsWith('/flutter.js') ||
    path.endsWith('/main.dart.js') ||
    path.endsWith('/manifest.json')
  );
}

async function cachePut(request, response) {
  if (response && response.ok) {
    const cache = await caches.open(CACHE_NAME);
    await cache.put(request, response.clone());
  }
  return response;
}

async function networkFirst(request, fallbackKeys) {
  try {
    const fresh = await fetch(request, { cache: 'no-store' });
    if (fresh && fresh.ok) {
      await cachePut(request, fresh);
      return fresh;
    }
  } catch (_) {
    // Offline; fall through to the cache.
  }
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;
  for (const key of fallbackKeys || []) {
    const hit = await cache.match(key);
    if (hit) return hit;
  }
  return Response.error();
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  const networkPromise = fetch(request)
      .then((response) => cachePut(request, response))
      .catch(() => null);

  if (cached) {
    // Kick off revalidation; do not await.
    networkPromise;
    return cached;
  }

  const fresh = await networkPromise;
  return fresh || Response.error();
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

  if (request.mode === 'navigate') {
    event.respondWith(
      networkFirst(request, ['./index.html', 'index.html', './']),
    );
    return;
  }

  if (isCodeEntrypoint(url)) {
    event.respondWith(networkFirst(request));
    return;
  }

  event.respondWith(cacheFirst(request));
});
