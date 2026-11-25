// Controllo segmentato comune delle viste (stesso SegmentedButton della
// bucket list e delle sezioni) su una sola riga: con [compact] e poco
// spazio (telefono, testo grande) mostra solo le icone, con il nome come
// suggerimento.

import 'package:flutter/material.dart';

class TripSectionSegments<T> extends StatelessWidget {
  const TripSectionSegments({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.labelOf,
    required this.iconOf,
    required this.selected,
    required this.onChanged,
    this.codeOf,
    this.compact = false,
  });

  final String keyPrefix;
  final List<T> values;
  final String Function(T value) labelOf;
  final IconData Function(T value) iconOf;
  final String Function(T value)? codeOf;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Icons only when the labels would not fit.
  final bool compact;

  /// Width each labelled segment needs, at the current text size.
  static double labelledWidth(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) * 9 + 48;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final iconsOnly =
          compact && box.maxWidth < values.length * labelledWidth(context);
      return SingleChildScrollView(
        key: Key('$keyPrefix-view'),
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<T>(
          showSelectedIcon: !iconsOnly,
          segments: [
            for (final v in values)
              ButtonSegment(
                value: v,
                icon: Icon(
                  iconOf(v),
                  key: Key('$keyPrefix-view-${codeOf?.call(v) ?? v}'),
                ),
                label: iconsOnly ? null : Text(labelOf(v)),
                tooltip: labelOf(v),
              ),
          ],
          selected: {selected},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      );
    },
  );
}
