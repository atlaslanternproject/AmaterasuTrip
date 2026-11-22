// Sceglie il caricatore dei dati Google dei luoghi (Web o altre
// piattaforme, dove non è disponibile).
export 'amaterasu_place_loader_stub.dart'
    if (dart.library.js_interop) 'amaterasu_place_loader_web.dart';
