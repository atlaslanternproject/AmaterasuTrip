// Fine del caricamento iniziale (Extra G): l'app avvisa la pagina web
// quando mostra la prima pagina vera (accesso, home o viaggio), così il
// sole di caricamento sparisce solo a caricamento completo.

import 'amaterasu_app_ready_stub.dart'
    if (dart.library.js_interop) 'amaterasu_app_ready_web.dart'
    as platform;

bool _done = false;

/// Hides the web loading screen once; does nothing on other platforms.
void amaterasuAppReady() {
  if (_done) return;
  _done = true;
  platform.notifyReady();
}
