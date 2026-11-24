// Versione web: chiama le funzioni di web/amaterasu_files.js per scaricare
// un file di testo o aprire una pagina da stampare / salvare come PDF.

import 'dart:js_interop';

@JS('amaterasuDownloadText')
external void _download(JSString name, JSString mime, JSString text);

@JS('amaterasuPrintHtml')
external JSBoolean _print(JSString html);

/// Saves [text] as a file named [name]; false when not possible.
bool amaterasuDownloadText(String name, String mime, String text) {
  try {
    _download(name.toJS, mime.toJS, text.toJS);
    return true;
  } catch (_) {
    return false;
  }
}

/// Opens [html] in a new tab and starts printing; false when not possible
/// (e.g. pop-ups blocked).
bool amaterasuPrintHtml(String html) {
  try {
    return _print(html.toJS).toDart;
  } catch (_) {
    return false;
  }
}
