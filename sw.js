const CACHE_NAME = 'statickit-cache-v1';
const ASSETS = [
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-114x114.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-120x120.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-144x144.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-152x152.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-16x16.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-180x180.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-192x192.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-228x228.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-256x256.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-310x310.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-32x32.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-384x384.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-48x48.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-512x512.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-57x57.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-60x60.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-70x70.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/base-76x76.png',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/favicon-inactive.ico',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/favicon.ico',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/generated-favicon-alt.svg',
  '7bf92f32-77ae-4e8a-8411-63975a90137f/generated-favicon.svg',
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
