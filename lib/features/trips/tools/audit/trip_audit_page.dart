// Pagina "Audit Trail" di Altro (v1.58.0): spiegazione, rimando allo
// Storico del budget per le spese, filtri con il componente condiviso
// (sezione, persona, azione, periodo) e voci a pagine da 30, lette solo
// all'apertura, al cambio dei filtri o con "Mostra altre". Sola lettura.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/filters/amaterasu_filter_bar.dart';
import 'package:amaterasutrip/features/trips/sections/widgets/trip_section_header.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'trip_audit_data.dart';
import 'trip_audit_filters.dart';
import 'trip_audit_names.dart';
import 'trip_audit_tile.dart';

class TripAuditPage extends ConsumerStatefulWidget {
  const TripAuditPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripAuditPage> createState() => _TripAuditPageState();
}

class _TripAuditPageState extends ConsumerState<TripAuditPage> {
  final _filters = ValueNotifier(const TripAuditFilters());
  final _entries = <TripAuditEntry>[];
  Object? _next;
  bool _loading = false;
  bool _failed = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _filters.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _entries.clear();
        _next = null;
        _done = false;
      }
    });
    try {
      final page = await ref
          .read(tripAuditSourceProvider)
          .page(widget.tripId, _filters.value, after: _next);
      if (!mounted) return;
      setState(() {
        _entries.addAll(page.entries);
        _next = page.next;
        _done = page.next == null;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _apply(TripAuditFilters f) {
    _filters.value = f;
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.watch(tripAuditMembersProvider(widget.tripId));
    const muted = TextStyle(color: AmaterasuColors.textSecondary);
    return Scaffold(
      backgroundColor: AmaterasuColors.surfaceDeep,
      body: SafeArea(
        child: Column(
          children: [
            TripSectionHeader(tripId: widget.tripId, title: l10n.auditTitle),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: ListView(
                    key: const Key('audit-page'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      Text(l10n.auditIntro, style: muted),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.auditExpenses, style: muted),
                          ),
                          AmaterasuButton.tertiary(
                            key: const Key('audit-expenses'),
                            onPressed: () => context.go(
                              '/trips/${widget.tripId}/more/expenses',
                            ),
                            label: l10n.auditOpenExpenses,
                          ),
                        ],
                      ),
                      ValueListenableBuilder(
                        valueListenable: _filters,
                        builder: (context, f, _) => AmaterasuFilterBar(
                          keyPrefix: 'audit',
                          activeCount: tripAuditActiveCount(f),
                          onOpen: () => showTripAuditFilters(
                            context,
                            filters: _filters,
                            members: members,
                            onChanged: _apply,
                          ),
                          onClear: () => _apply(const TripAuditFilters()),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                      for (final e in _entries)
                        TripAuditTile(
                          entry: e,
                          who: tripAuditName(l10n, members, e.actorUid),
                        ),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AmaterasuColors.primary,
                            ),
                          ),
                        )
                      else if (_failed)
                        AmaterasuButton.tertiary(
                          key: const Key('audit-retry'),
                          onPressed: () => _load(reset: _entries.isEmpty),
                          label: '${l10n.auditError} ${l10n.auditRetry}',
                        )
                      else if (_entries.isEmpty)
                        Text(
                          l10n.auditEmpty,
                          key: const Key('audit-empty'),
                          style: muted,
                        )
                      else if (!_done)
                        AmaterasuButton.tertiary(
                          key: const Key('audit-more'),
                          onPressed: () => _load(reset: false),
                          label: l10n.auditMore,
                        ),
                    ],
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
