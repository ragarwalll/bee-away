const CACHE_NAME = 'statickit-cache-v1';
const ASSETS = [
  '/css/bundle.min.css',
  '/css/css-bundle-report.json',
  '/img/favicon/android-chrome-192x192.png',
  '/img/favicon/android-chrome-512x512.png',
  '/img/favicon/apple-touch-icon.png',
  '/img/favicon/favicon-1024x1024.png',
  '/img/favicon/favicon-16x16.png',
  '/img/favicon/favicon-32x32.png',
  '/img/favicon/favicon-96x96.png',
  '/img/favicon/favicon-inactive.svg',
  '/img/favicon/favicon.svg',
  '/img/favicon/mstile-150x150.png',
  '/img/favicon/safari-pinned-tab.png',
  '/img/favicon/web-app-manifest-192x192.png',
  '/img/favicon/web-app-manifest-512x512.png',
  '/img/images/banner.jpg',
  '/img/images/preview-prefs.jpg',
  '/img/images/preview.jpg',
  '/index.html',
  '/js/bundle.min.js',
  '/js/js-bundle-report.json',
  '/perf-metrics.json',
  '/sitemap.xml'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(cached => cached ||
      fetch(event.request))
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.map(k => {
        if (k !== CACHE_NAME) return caches.delete(k);
      }))
    )
  );
});
