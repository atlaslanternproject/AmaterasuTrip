// Parte di trip_transport_editor.dart: i blocchi dell'editor (tipo e stato,
// da/a, partenza e arrivo con fuso orario, compagnia e passeggeri,
// prenotazione).

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_transport_editor.dart';

extension _TripTransportEditorBlocks on _TripTransportEditorState {
  Widget _typeBlock(AppLocalizations l10n) => TripSectionBlock(
    title: l10n.transportBlockType,
    icon: Icons.commute_rounded,
    children: [
      TripSectionChoices<TripTransportType>(
        keyPrefix: 'transport-type',
        values: TripTransportType.values,
        codeOf: (t) => t.code,
        labelOf: (t) => TripTransportLabels.type(t, l10n),
        iconOf: TripTransportLabels.icon,
        selected: _draft.type,
        onChanged: (t) => setState(() => _draft.type = t ?? _draft.type),
      ),
      const SizedBox(height: 12),
      TripSectionChoices<TripBookingStatus>(
        keyPrefix: 'transport-status',
        values: TripBookingStatus.values,
        codeOf: (s) => s.code,
        labelOf: (s) => TripSectionLabels.status(s, l10n),
        selected: _draft.status,
        onChanged: (s) => setState(() => _draft.status = s ?? _draft.status),
      ),
    ],
  );

  Widget _routeBlock(AppLocalizations l10n) => TripSectionBlock(
    title: l10n.transportBlockRoute,
    icon: Icons.alt_route_rounded,
    children: [
      TripSectionPlaceField(
        keyPrefix: 'transport-from',
        label: l10n.transportFrom,
        draft: _draft.from,
        places: widget.places,
        onChanged: _changed,
      ),
      const SizedBox(height: 8),
      TripSectionPlaceField(
        keyPrefix: 'transport-to',
        label: l10n.transportTo,
        draft: _draft.to,
        places: widget.places,
        onChanged: _changed,
      ),
    ],
  );

  Widget _offset(String key, String? value, ValueChanged<String?> onChanged) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String?>(
        key: Key(key),
        initialValue: value,
        isExpanded: true,
        menuMaxHeight: 320,
        decoration: InputDecoration(labelText: l10n.transportTimeZone),
        items: [
          DropdownMenuItem(child: Text(l10n.transportTimeZoneNone)),
          for (final offset in {...TripTransportLabels.offsets, ?value})
            DropdownMenuItem(
              value: offset,
              child: Text(TripTransportLabels.offset(offset)),
            ),
        ],
        onChanged: (v) => setState(() => onChanged(v)),
      ),
    );
  }

  Widget _timesBlock(AppLocalizations l10n) => TripSectionBlock(
    title: l10n.transportBlockTimes,
    icon: Icons.schedule_rounded,
    children: [
      TripSectionDayButton(
        fieldKey: 'transport-departure-day',
        label: l10n.transportDepartureDay,
        value: _draft.departureDate,
        onChanged: (d) => setState(() => _draft.departureDate = d),
      ),
      TripSectionTimeButton(
        fieldKey: 'transport-departure-time',
        label: l10n.transportDepartureTime,
        value: _draft.departureTime,
        onChanged: (t) => setState(() => _draft.departureTime = t),
      ),
      _offset(
        'transport-departure-offset',
        _draft.departureOffset,
        (v) => _draft.departureOffset = v,
      ),
      const SizedBox(height: 12),
      TripSectionDayButton(
        fieldKey: 'transport-arrival-day',
        label: l10n.transportArrivalDay,
        value: _draft.arrivalDate,
        initial: _draft.departureDate,
        onChanged: (d) => setState(() => _draft.arrivalDate = d),
        onClear: () => setState(() => _draft.arrivalDate = null),
      ),
      TripSectionTimeButton(
        fieldKey: 'transport-arrival-time',
        label: l10n.transportArrivalTime,
        value: _draft.arrivalTime,
        onChanged: (t) => setState(() => _draft.arrivalTime = t),
      ),
      _offset(
        'transport-arrival-offset',
        _draft.arrivalOffset,
        (v) => _draft.arrivalOffset = v,
      ),
    ],
  );

  Widget _field(String key, TextEditingController c, String label, int max) =>
      TextField(
        key: Key(key),
        controller: c,
        maxLength: max,
        decoration: InputDecoration(labelText: label),
      );

  Widget _serviceBlock(AppLocalizations l10n) => TripSectionBlock(
    title: l10n.transportBlockService,
    icon: Icons.badge_outlined,
    children: [
      _field('transport-carrier', _draft.carrier, l10n.transportCarrier, 120),
      _field('transport-number', _draft.number, l10n.transportNumber, 120),
      _field('transport-seats', _draft.seats, l10n.transportSeats, 120),
      Text(l10n.transportPassengers),
      const SizedBox(height: 6),
      TripSectionMembers(
        keyPrefix: 'transport-passenger',
        memberNames: widget.memberNames,
        selected: _draft.passengers,
        onChanged: _changed,
      ),
    ],
  );

  Widget _bookingBlock(AppLocalizations l10n) => TripSectionBlock(
    title: l10n.transportBlockBooking,
    icon: Icons.confirmation_number_outlined,
    children: [
      _field(
        'transport-code',
        _draft.bookingCode,
        l10n.sectionsBookingCode,
        100,
      ),
      _field('transport-via', _draft.bookedVia, l10n.transportBookedVia, 120),
      TextField(
        key: const Key('transport-url'),
        controller: _draft.bookingUrl,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(labelText: l10n.transportBookingLink),
      ),
    ],
  );
}
