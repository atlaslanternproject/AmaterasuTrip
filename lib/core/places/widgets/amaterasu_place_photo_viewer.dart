// Visore delle foto Google di un luogo, aperto toccando la foto della card:
// fino a 5 foto con frecce e puntini; ogni immagine si scarica solo quando
// la sua pagina è visibile. Gli autori compaiono qui in piccolo, come
// chiedono i termini di Google Places.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_place_photo_parts.dart';

Future<void> showAmaterasuPhotoViewer(
  BuildContext context, {
  required List<AmaterasuPlacePhoto> photos,
  required String keyPrefix,
  required IconData placeholderIcon,
}) => showDialog<void>(
  context: context,
  builder: (_) => Dialog(
    backgroundColor: AmaterasuColors.surfaceDeep,
    insetPadding: const EdgeInsets.all(12),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820, maxHeight: 560),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: _Viewer(
          photos: photos,
          keyPrefix: keyPrefix,
          placeholderIcon: placeholderIcon,
        ),
      ),
    ),
  ),
);

class _Viewer extends StatefulWidget {
  const _Viewer({
    required this.photos,
    required this.keyPrefix,
    required this.placeholderIcon,
  });

  final List<AmaterasuPlacePhoto> photos;
  final String keyPrefix;
  final IconData placeholderIcon;

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photos = widget.photos;
    final photo = photos[_index.clamp(0, photos.length - 1)];
    final prefix = widget.keyPrefix;
    return Stack(
      key: Key('$prefix-photo-viewer'),
      fit: StackFit.expand,
      children: [
        PageView.builder(
          key: Key('$prefix-photo-pages'),
          controller: _pages,
          itemCount: photos.length,
          onPageChanged: (page) => setState(() => _index = page),
          itemBuilder: (_, page) => Image.network(
            photos[page].url,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => AmaterasuPhotoPlaceholder(
              icon: widget.placeholderIcon,
              keyPrefix: prefix,
            ),
          ),
        ),
        if (_index > 0)
          AmaterasuPhotoArrow(
            key: Key('$prefix-photo-prev'),
            left: true,
            tooltip: l10n.placesPhotoPrevious,
            onPressed: () => _go(_index - 1),
          ),
        if (_index < photos.length - 1)
          AmaterasuPhotoArrow(
            key: Key('$prefix-photo-next'),
            left: false,
            tooltip: l10n.placesPhotoNext,
            onPressed: () => _go(_index + 1),
          ),
        if (photos.length > 1)
          AmaterasuPhotoDots(count: photos.length, index: _index),
        if (photo.authors.isNotEmpty)
          AmaterasuPhotoAuthors(authors: photo.authors),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            key: Key('$prefix-photo-close'),
            tooltip: l10n.placesContactClose,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AmaterasuColors.textCream),
          ),
        ),
      ],
    );
  }
}
