// Carosello delle foto Google di un luogo (al massimo 5), in testa alle
// card di alloggi e altre sezioni. Le foto si chiedono solo quando la card viene costruita, cioè
// quando sta per apparire sullo schermo (l'elenco è "pigro"), e una volta
// sola per luogo grazie alla cache; ogni immagine si scarica solo quando la
// sua pagina è visibile. Nessuna foto viene salvata.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/core/places/amaterasu_place_providers.dart';
import 'package:amaterasutrip/core/places/amaterasu_place_info.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'amaterasu_place_photo_parts.dart';

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

  /// False in the small photo of the "Elenco" view: first photo only.
  final bool controls;

  @override
  ConsumerState<AmaterasuPlacePhotoCarousel> createState() => _CarouselState();
}

class _CarouselState extends ConsumerState<AmaterasuPlacePhotoCarousel> {
  final _pages = PageController();
  Future<List<AmaterasuPlacePhoto>>? _photos;
  String? _loadedFor;
  int _index = 0;

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
    _index = 0;
    _photos = id.isEmpty
        ? Future.value(const [])
        : ref
              .read(amaterasuPlaceInfoProvider)
              .photos(id, languageCode: language);
  }

  @override
  void didUpdateWidget(covariant AmaterasuPlacePhotoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId) {
      _load();
      if (_pages.hasClients) _pages.jumpToPage(0);
    }
  }

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
    final placeholder = AmaterasuPhotoPlaceholder(
      icon: widget.placeholderIcon,
      keyPrefix: widget.keyPrefix,
    );
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<List<AmaterasuPlacePhoto>>(
        future: _photos,
        builder: (context, snapshot) {
          final photos = snapshot.data ?? const <AmaterasuPlacePhoto>[];
          if (snapshot.hasError || photos.isEmpty) return placeholder;
          final photo = photos[_index.clamp(0, photos.length - 1)];
          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                key: Key('${widget.keyPrefix}-photos'),
                controller: _pages,
                itemCount: widget.controls ? photos.length : 1,
                onPageChanged: (page) => setState(() => _index = page),
                itemBuilder: (_, page) => Image.network(
                  photos[page].url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => placeholder,
                ),
              ),
              if (widget.controls && photos.length > 1) ...[
                if (_index > 0)
                  AmaterasuPhotoArrow(
                    key: Key('${widget.keyPrefix}-photo-prev'),
                    left: true,
                    tooltip: l10n.placesPhotoPrevious,
                    onPressed: () => _go(_index - 1),
                  ),
                if (_index < photos.length - 1)
                  AmaterasuPhotoArrow(
                    key: Key('${widget.keyPrefix}-photo-next'),
                    left: false,
                    tooltip: l10n.placesPhotoNext,
                    onPressed: () => _go(_index + 1),
                  ),
                AmaterasuPhotoDots(count: photos.length, index: _index),
              ],
              if (photo.authors.isNotEmpty)
                AmaterasuPhotoAuthors(
                  authors: photo.authors,
                  compact: !widget.controls,
                ),
            ],
          );
        },
      ),
    );
  }
}
