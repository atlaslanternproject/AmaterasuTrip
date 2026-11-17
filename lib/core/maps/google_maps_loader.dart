// Punto di ingresso per caricare Google Maps: sceglie la versione Web
// o quella per le altre piattaforme (import condizionale).

export 'google_maps_loader_stub.dart'
    if (dart.library.js_interop) 'google_maps_loader_web.dart';
