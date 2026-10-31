import 'dart:js_interop';

@JS('amaterasuDriveAuthorize')
external JSPromise<JSString> _authorizeGoogleDrive(JSString clientId);

Future<String> authorizeGoogleDriveWeb() async {
  const clientId = String.fromEnvironment('GOOGLE_DRIVE_WEB_CLIENT_ID');

  if (clientId.trim().isEmpty) {
    throw StateError('GOOGLE_DRIVE_WEB_CLIENT_ID is not configured.');
  }

  final response = await _authorizeGoogleDrive(clientId.trim().toJS).toDart;
  final token = response.toDart.trim();

  if (token.isEmpty) {
    throw StateError('Google Drive did not return an access token.');
  }

  return token;
}
