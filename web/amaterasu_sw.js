// Service worker minimo di Amaterasu Trip: serve solo a rendere il sito
// installabile come app (Android "Installa app"). Nessun offline e nessuna
// cache: ogni richiesta va in rete come senza service worker.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
// Fetch handler present for installability; it does not answer, so the
// browser loads everything from the network as usual.
self.addEventListener('fetch', () => {});
