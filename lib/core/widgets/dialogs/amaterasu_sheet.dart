// Pannello dell'app: sul telefono sale dal basso con la barra di
// trascinamento, su schermo largo (almeno 600 punti) è una finestra
// centrale. Uno solo per tutti i popup (docs/design/DIRETTIVE-UI.md).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';

Future<T?> showAmaterasuSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AmaterasuColors.surfaceCard,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: builder(sheetContext),
      ),
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AmaterasuColors.surfaceCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: builder(dialogContext),
      ),
    ),
  );
}
