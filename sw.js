const CACHE_NAME = 'statickit-cache-v1';
const ASSETS = [
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-114x114.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-120x120.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-144x144.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-152x152.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-16x16.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-180x180.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-192x192.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-228x228.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-256x256.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-310x310.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-32x32.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-384x384.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-48x48.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-512x512.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-57x57.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-60x60.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-70x70.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/base-76x76.png',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/favicon-inactive.ico',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/favicon.ico',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/generated-favicon-alt.svg',
  '1dbedcd2-bf6a-46b5-9042-444a3d1103f8/generated-favicon.svg',
  'asset-manifest.json',
  'browserconfig.xml',
  'css/bundle.min.66a0637f.css',
  'css/css-bundle-report.json',
  'favicon.svg',
  'images/banner.jpg',
  'images/preview-prefs.jpg',
  'images/preview.jpg',
  'index.html',
  'js/bundle.min.89d76dc6.js',
  'js/js-bundle-report.json',
  'perf-metrics.json',
  'site.webmanifest',
  'sitemap.xml'
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
