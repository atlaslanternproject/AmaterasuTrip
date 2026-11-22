// Carosello delle foto Google di un alloggio (al massimo 5), in testa alla
// card. Le foto si chiedono solo quando la card viene costruita, cioè
// quando sta per apparire sullo schermo (l'elenco è "pigro"), e una volta
// sola per luogo grazie alla cache; ogni immagine si scarica solo quando la
// sua pagina è visibile. Nessuna foto viene salvata.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/stays/models/trip_stay_type.dart';
import 'package:amaterasutrip/features/trips/stays/places/trip_stay_place_info.dart';
import 'package:amaterasutrip/features/trips/stays/providers/trip_stays_context_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_stay_photo_parts.dart';

class TripStayPhotoCarousel extends ConsumerStatefulWidget {
  const TripStayPhotoCarousel({
    super.key,
    required this.placeId,
    required this.type,
    required this.height,
    this.controls = true,
  });

  final String? placeId;
  final TripStayType? type;
  final double height;

  /// False in the small photo of the "Elenco" view: first photo only.
  final bool controls;

  @override
  ConsumerState<TripStayPhotoCarousel> createState() => _CarouselState();
}

class _CarouselState extends ConsumerState<TripStayPhotoCarousel> {
  final _pages = PageController();
  Future<List<TripStayPlacePhoto>>? _photos;
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
              .read(tripStayPlaceInfoProvider)
              .photos(id, languageCode: language);
  }

  @override
  void didUpdateWidget(covariant TripStayPhotoCarousel oldWidget) {
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
    final placeholder = TripStayPhotoPlaceholder(type: widget.type);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: FutureBuilder<List<TripStayPlacePhoto>>(
        future: _photos,
        builder: (context, snapshot) {
          final photos = snapshot.data ?? const <TripStayPlacePhoto>[];
          if (snapshot.hasError || photos.isEmpty) return placeholder;
          final photo = photos[_index.clamp(0, photos.length - 1)];
          return Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                key: const Key('stay-photos'),
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
                  TripStayPhotoArrow(
                    key: const Key('stay-photo-prev'),
                    left: true,
                    tooltip: l10n.staysPhotoPrevious,
                    onPressed: () => _go(_index - 1),
                  ),
                if (_index < photos.length - 1)
                  TripStayPhotoArrow(
                    key: const Key('stay-photo-next'),
                    left: false,
                    tooltip: l10n.staysPhotoNext,
                    onPressed: () => _go(_index + 1),
                  ),
                TripStayPhotoDots(count: photos.length, index: _index),
              ],
              if (photo.authors.isNotEmpty)
                TripStayPhotoAuthors(
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
