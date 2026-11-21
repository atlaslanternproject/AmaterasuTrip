// Sceglie il caricatore dei dati Google degli alloggi (Web o altre
// piattaforme, dove non è disponibile).
export 'trip_stay_place_loader_stub.dart'
    if (dart.library.js_interop) 'trip_stay_place_loader_web.dart';
