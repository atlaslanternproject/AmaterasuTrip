// Controllo "Cosa c'è di nuovo" all'apertura dell'app: dopo il primo
// disegno legge la versione installata e, se è cambiata dall'ultima volta,
// mostra le novità una volta sola. Avvolge la shell globale.

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'amaterasu_changelog.dart';
import 'amaterasu_whats_new.dart';

class AmaterasuWhatsNewGate extends StatefulWidget {
  const AmaterasuWhatsNewGate({super.key, required this.child, this.version});

  final Widget child;

  /// Installed version; read from the app when null (tests pass it).
  final Future<String> Function()? version;

  @override
  State<AmaterasuWhatsNewGate> createState() => _AmaterasuWhatsNewGateState();
}

class _AmaterasuWhatsNewGateState extends State<AmaterasuWhatsNewGate> {
  static bool _checked = false;

  @override
  void initState() {
    super.initState();
    if (_checked) return;
    _checked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    try {
      final version =
          await (widget.version ??
              () async => (await PackageInfo.fromPlatform()).version)();
      final entry = await AmaterasuWhatsNew.pending(
        version,
        await AmaterasuChangelog.load(),
      );
      if (entry != null && mounted) {
        await AmaterasuWhatsNew.show(context, entry);
      }
    } catch (_) {
      // The news are a bonus: never block the app.
    }
  }

  /// Lets tests check again.
  @visibleForTesting
  static void reset() => _checked = false;

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Test helper to run the check again.
@visibleForTesting
void resetAmaterasuWhatsNewGate() => _AmaterasuWhatsNewGateState.reset();
