// Segni sulla foto della card: quante foto ci sono (si aprono toccando) e
// la piccola scritta "Google Maps" richiesta quando si mostrano dati Google
// fuori da una mappa Google.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_radius.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

const _veil = Color(0xA6000000);

class AmaterasuPhotoCount extends StatelessWidget {
  const AmaterasuPhotoCount({
    super.key,
    required this.count,
    required this.tooltip,
  });

  final int count;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 8,
    right: 8,
    child: Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _veil,
          borderRadius: BorderRadius.circular(AmaterasuRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 14,
              color: AmaterasuColors.textCream,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                color: AmaterasuColors.textCream,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AmaterasuGoogleMark extends StatelessWidget {
  const AmaterasuGoogleMark({super.key});

  @override
  Widget build(BuildContext context) => Positioned(
    left: 6,
    bottom: 6,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _veil,
        borderRadius: BorderRadius.circular(AmaterasuRadius.sm),
      ),
      child: Text(
        AppLocalizations.of(context)!.placesGoogleMark,
        style: const TextStyle(color: AmaterasuColors.textCream, fontSize: 9),
      ),
    ),
  );
}
