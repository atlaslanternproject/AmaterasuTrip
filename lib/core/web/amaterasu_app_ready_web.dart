// Nel browser chiama amaterasuAppReady() di web/index.html, che toglie il
// sole di caricamento. Se la funzione manca non succede nulla.

import 'dart:js_interop';

@JS('amaterasuAppReady')
external JSFunction? get _ready;

void notifyReady() {
  try {
    _ready?.callAsFunction();
  } catch (_) {}
}
