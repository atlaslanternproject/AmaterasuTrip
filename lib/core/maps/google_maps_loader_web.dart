import 'dart:js_interop';

@JS('amaterasuLoadGoogleMaps')
external JSPromise<JSBoolean> _loadGoogleMaps(JSString apiKey);

Future<void> initializeGoogleMaps() async {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY');

  final normalizedApiKey = apiKey.trim();

  if (normalizedApiKey.isEmpty) {
    throw StateError('Missing GOOGLE_MAPS_WEB_API_KEY for Flutter Web.');
  }

  await _loadGoogleMaps(normalizedApiKey.toJS).toDart;
}
