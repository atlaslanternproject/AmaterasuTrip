// File dal browser: scarica un testo (es. CSV) e apre una pagina da
// stampare o salvare come PDF. Sul web usa web/amaterasu_files.js; altrove
// non è disponibile (Android è deprecato).

export 'amaterasu_files_stub.dart'
    if (dart.library.js_interop) 'amaterasu_files_web.dart';
