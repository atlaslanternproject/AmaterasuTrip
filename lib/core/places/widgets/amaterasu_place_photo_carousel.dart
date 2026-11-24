// Foto Google in testa alle card (alloggi e sezioni). Nella card c'è solo la
// prima foto: si chiede una volta per luogo, quando la card sta per apparire
// (elenco "pigro", cache di sessione). Toccandola si apre il visore con fino
// a 5 foto, scaricate solo lì. Nella card solo la scritta "Google Maps".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_place_photo_marks.dart';
import 'amaterasu_place_photo_parts.dart';
import 'amaterasu_place_photo_viewer.dart';

class AmaterasuPlacePhotoCarousel extends ConsumerStatefulWidget {
  const AmaterasuPlacePhotoCarousel({
    super.key,
    required this.placeId,
    this.placeholderIcon = Icons.place_outlined,
    this.keyPrefix = 'place',
    required this.height,
    this.controls = true,
  });

  final String? placeId;

  /// Icon of the placeholder (e.g. the type of stay).
  final IconData placeholderIcon;

  /// Start of the widget keys (e.g. "stay" gives "stay-photos").
  final String keyPrefix;
  final double height;

  /// False in the small photo of the "Elenco" view: no count, no viewer.
  final bool controls;

  @override
  ConsumerState<AmaterasuPlacePhotoCarousel> createState() => _CarouselState();
}

class _CarouselState extends ConsumerState<AmaterasuPlacePhotoCarousel> {
  Future<List<AmaterasuPlacePhoto>>? _photos;
  String? _loadedFor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  /// Asks for the photos only when the place or the language changes.
  void _load() {
    final id = widget.placeId?.trim() ?? '';
    final language = Localizations.localeOf(context).languageCode;
    final key = '$id|$language';
    if (key == _loadedFor) return;
    _loadedFor = key;
    _photos = id.isEmpty
        ? Future.value(const [])
        : ref
              .read(amaterasuPlaceInfoProvider)
              .photos(id, languageCode: language);
  }

  @override
  void didUpdateWidget(covariant AmaterasuPlacePhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefix = widget.keyPrefix;
    final placeholder = AmaterasuPhotoPlaceholder(
      icon: widget.placeholderIcon,
      keyPrefix: prefix,
    );
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<List<AmaterasuPlacePhoto>>(
        future: _photos,
        builder: (context, snapshot) {
          final photos = snapshot.data ?? const <AmaterasuPlacePhoto>[];
          if (snapshot.hasError || photos.isEmpty) return placeholder;
          return GestureDetector(
            key: Key('$prefix-photos'),
            onTap: widget.controls
                ? () => showAmaterasuPhotoViewer(
                    context,
                    photos: photos,
                    keyPrefix: prefix,
                    placeholderIcon: widget.placeholderIcon,
                  )
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photos.first.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                ),
                if (widget.controls && photos.length > 1)
                  AmaterasuPhotoCount(
                    key: Key('$prefix-photo-count'),
                    count: photos.length,
                    tooltip: l10n.placesPhotoOpen,
                  ),
                if (widget.controls) const AmaterasuGoogleMark(),
              ],
            ),
          );
        },
      ),
    );
  }
}
