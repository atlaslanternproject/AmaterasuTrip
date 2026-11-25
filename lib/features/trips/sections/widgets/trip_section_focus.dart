// Elemento da evidenziare all'apertura di una sezione (nuova tappa 2b):
// "Cerca" lo segna prima di aprire la sezione, l'elenco comune lo raggiunge
// scorrendo, lo mette in risalto per qualche secondo e poi lo dimentica.
// Solo in memoria: nessun dato salvato.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TripSectionFocus extends Notifier<String?> {
  @override
  String? build() => null;

  /// Item ID to highlight in the next section list that shows it.
  void set(String? id) => state = id;
}

final tripSectionFocusProvider = NotifierProvider<TripSectionFocus, String?>(
  TripSectionFocus.new,
);

/// Scrolls [controller] until the widget with [key] is built, then shows
/// it. Lists build their items lazily, so it moves one screen at a time.
Future<bool> tripSectionReveal(
  ScrollController controller,
  GlobalKey key, {
  int maxSteps = 60,
}) async {
  for (var step = 0; step < maxSteps; step++) {
    final context = key.currentContext;
    if (context != null) {
      if (!context.mounted) return false;
      await Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 250),
      );
      return true;
    }
    if (!controller.hasClients) return false;
    final position = controller.position;
    if (position.pixels >= position.maxScrollExtent) return false;
    controller.jumpTo(
      (position.pixels + position.viewportDimension * 0.8).clamp(
        0,
        position.maxScrollExtent,
      ),
    );
    await WidgetsBinding.instance.endOfFrame;
  }
  return false;
}
