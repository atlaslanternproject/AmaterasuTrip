// Pezzi del carosello foto degli alloggi: segnaposto con sfumatura calda e
// icona del tipo, frecce, puntini della pagina e autori della foto (da
// mostrare sempre, come chiede Google).

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_radius.dart';
import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'trip_stay_labels.dart';

/// Dark translucent background used on top of the photos.
const _veil = Color(0xE81F1714);

class TripStayPhotoPlaceholder extends StatelessWidget {
  const TripStayPhotoPlaceholder({super.key, this.type});

  final TripStayType? type;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('stay-photo-placeholder'),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AmaterasuColors.backgroundSecondary,
          AmaterasuColors.surfaceRaised,
        ],
      ),
    ),
    child: Center(
      child: Icon(
        TripStayLabels.typeIcon(type),
        size: 48,
        color: AmaterasuColors.accentBudget.withValues(alpha: 0.55),
      ),
    ),
  );
}

class TripStayPhotoArrow extends StatelessWidget {
  const TripStayPhotoArrow({
    super.key,
    required this.left,
    required this.tooltip,
    required this.onPressed,
  });

  final bool left;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left ? 6 : null,
    right: left ? null : 6,
    top: 0,
    bottom: 0,
    child: Center(
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: _veil,
          foregroundColor: AmaterasuColors.textPrimary,
          minimumSize: const Size(34, 34),
        ),
        iconSize: 20,
        onPressed: onPressed,
        icon: Icon(
          left ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
        ),
      ),
    ),
  );
}

class TripStayPhotoDots extends StatelessWidget {
  const TripStayPhotoDots({
    super.key,
    required this.count,
    required this.index,
  });

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) => Positioned(
    right: 10,
    bottom: 10,
    child: Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(left: 4),
            width: i == index ? 16 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index
                  ? AmaterasuColors.textPrimary
                  : AmaterasuColors.textPrimary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    ),
  );
}

class AmaterasuPhotoAuthors extends StatelessWidget {
  const AmaterasuPhotoAuthors({
    super.key,
    required this.authors,
    this.compact = false,
  });

  final List<AmaterasuPhotoAuthor> authors;

  /// Small photo: no room is kept for the page dots.
  final bool compact;

  @override
  Widget build(BuildContext context) => Positioned(
    left: compact ? 4 : 8,
    bottom: compact ? 4 : 8,
    right: compact ? 4 : 90,
    child: Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _veil,
          borderRadius: BorderRadius.circular(AmaterasuRadius.sm),
        ),
        child: Wrap(
          spacing: 8,
          children: [
            for (final author in authors)
              InkWell(
                onTap: author.uri == null
                    ? null
                    : () => launchUrl(author.uri!, webOnlyWindowName: '_blank'),
                child: Text(
                  author.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AmaterasuColors.textCream,
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
