// Pagina "Cerca" di Altro (nuova tappa 2a): campo di ricerca, ricerche
// recenti, filtro per sezione e risultati a pagine da 20. I dati si
// leggono alla prima ricerca e restano per la sessione ("Aggiorna" li
// rilegge); il tocco su un risultato apre la sua sezione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_search_parts.dart';
import 'trip_search_recent.dart';
import 'trip_search_results.dart';
import 'trip_search_sources.dart';

class TripSearchPage extends ConsumerStatefulWidget {
  const TripSearchPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripSearchPage> createState() => _TripSearchPageState();
}

class _TripSearchPageState extends ConsumerState<TripSearchPage> {
  final _field = TextEditingController();
  List<String> _recent = const [];
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = ref.read(tripSearchUidProvider);
    TripSearchRecent.load(_uid, widget.tripId).then((list) {
      if (mounted) setState(() => _recent = list);
    });
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _remember(String query) {
    final list = TripSearchRecent.add(_recent, query);
    setState(() => _recent = list);
    TripSearchRecent.save(_uid, widget.tripId, list);
  }

  void _clearRecent() {
    setState(() => _recent = const []);
    TripSearchRecent.save(_uid, widget.tripId, const []);
  }

  void _open(TripSearchDoc doc) {
    _remember(_field.text);
    context.go(doc.section.route(widget.tripId, doc.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = _field.text.trim();
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(
              tripId: widget.tripId,
              title: l10n.searchTitle,
              action: IconButton(
                key: const Key('search-refresh'),
                tooltip: l10n.searchRefresh,
                onPressed: () =>
                    ref.invalidate(tripSearchDocsProvider(widget.tripId)),
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AmaterasuColors.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: TextField(
                  key: const Key('search-field'),
                  controller: _field,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: _remember,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            key: const Key('search-clear'),
                            onPressed: () => setState(_field.clear),
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: query.isEmpty
                      ? TripSearchStart(
                          recent: _recent,
                          onPick: (q) {
                            _field.text = q;
                            setState(() {});
                          },
                          onClear: _clearRecent,
                        )
                      : TripSearchResults(
                          tripId: widget.tripId,
                          query: query,
                          onOpen: _open,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
