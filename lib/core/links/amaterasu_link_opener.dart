// Apertura dei link come nella card della bucket list: nuova scheda, messaggio
// se il link non è valido, "Copia link" se non si apre; Google Maps con
// messaggio di errore. I testi arrivano da lib/l10n come parametri.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'amaterasu_web_link.dart';

/// Same signature as url_launcher's launchUrl, replaceable in tests.
typedef AmaterasuLaunch =
    Future<bool> Function(
      Uri uri, {
      LaunchMode mode,
      String? webOnlyWindowName,
    });

Future<bool> _defaultLaunch(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
  String? webOnlyWindowName,
}) => launchUrl(uri, mode: mode, webOnlyWindowName: webOnlyWindowName);

abstract final class AmaterasuLinkOpener {
  /// url_launcher's launchUrl: the real opening used by the app.
  static const AmaterasuLaunch defaultLaunch = _defaultLaunch;

  /// Opens a web link in a new tab or the external browser.
  static Future<void> openWebLink(
    BuildContext context,
    String link, {
    required String invalidMessage,
    required String failedMessage,
    required String copyLabel,
    AmaterasuLaunch launch = _defaultLaunch,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = AmaterasuWebLink.parse(link);
    if (uri == null) {
      messenger.showSnackBar(SnackBar(content: Text(invalidMessage)));
      return;
    }

    var opened = false;
    try {
      opened = await launch(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(failedMessage),
        action: SnackBarAction(
          label: copyLabel,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: uri.toString()));
          },
        ),
      ),
    );
  }

  /// Opens a place in Google Maps; shows [failedMessage] if it fails.
  static Future<void> openMaps(
    BuildContext context,
    Uri mapsUri, {
    required String failedMessage,
    AmaterasuLaunch launch = _defaultLaunch,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await launch(mapsUri, mode: LaunchMode.platformDefault);
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
  }
}
