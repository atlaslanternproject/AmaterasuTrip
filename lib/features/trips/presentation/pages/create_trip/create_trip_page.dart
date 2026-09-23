import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

import 'trip_created_page.dart';
import 'widgets/create_trip_button.dart';
import 'widgets/trip_cloud_selector.dart';
import 'widgets/trip_cover_picker.dart';
import 'widgets/trip_currency_selector.dart';
import 'widgets/trip_date_selector.dart';
import 'widgets/trip_destination_field.dart';
import 'widgets/trip_name_field.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  final TextEditingController _nameController = TextEditingController();

  String? _destination;
  DateTime? _departureDate;
  DateTime? _returnDate;
  String? _currency;
  String? _cloudProvider;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_onFormChanged)
      ..dispose();

    super.dispose();
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _canCreateTrip {
    return _nameController.text.trim().isNotEmpty &&
        _destination != null &&
        _departureDate != null &&
        _returnDate != null &&
        _currency != null;
  }

  Future<void> _selectDepartureDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _departureDate = selectedDate;

      if (_returnDate != null && _returnDate!.isBefore(selectedDate)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _selectReturnDate() async {
    final now = DateTime.now();
    final firstDate = _departureDate ?? now;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(now.year + 10),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _returnDate = selectedDate;
    });
  }

  void _selectDestination() {
    setState(() {
      _destination = '🇯🇵 Giappone';
      _currency ??= 'JPY · Yen giapponese';
    });
  }

  void _selectCurrency() {
    setState(() {
      _currency = 'JPY · Yen giapponese';
    });
  }

  void _selectCloudProvider() {
    setState(() {
      _cloudProvider = 'Google Drive';
    });
  }

  void _changeCover() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Placeholder: selezione copertina')),
    );
  }

  void _createTrip() {
    if (!_canCreateTrip) {
      return;
    }

    final tripName = _nameController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TripCreatedPage(
          tripName: tripName,
          onInviteTravellers: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Placeholder: invita viaggiatori')),
            );
          },
          onCopyLink: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.tripCreatedLinkCopied,
                ),
              ),
            );
          },
          onShare: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Placeholder: condividi viaggio')),
            );
          },
          onEnterTrip: () {
            // Collegamento al workspace nel prossimo step.
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.createTripTitle,
          style: const TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TripCoverPicker(
                changePhotoLabel: l10n.createTripChangePhoto,
                onTap: _changeCover,
              ),
              const SizedBox(height: 20),

              TripNameField(
                controller: _nameController,
                label: l10n.createTripName,
                hint: l10n.createTripNameHint,
              ),
              const SizedBox(height: 12),

              TripDestinationField(
                label: l10n.createTripDestination,
                hint: l10n.createTripDestinationHint,
                destination: _destination,
                onTap: _selectDestination,
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 9),
                child: Text(
                  l10n.createTripDates,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              TripDateSelector(
                departureLabel: l10n.createTripDepartureDate,
                returnLabel: l10n.createTripReturnDate,
                departureDate: _departureDate,
                returnDate: _returnDate,
                onDepartureTap: _selectDepartureDate,
                onReturnTap: _selectReturnDate,
              ),
              const SizedBox(height: 20),

              TripCurrencySelector(
                label: l10n.createTripCurrency,
                hint: l10n.createTripCurrencyHint,
                currency: _currency,
                onTap: _selectCurrency,
              ),
              const SizedBox(height: 24),

              TripCloudSelector(
                sectionLabel: l10n.createTripStorageSection,
                title: l10n.createTripStorage,
                subtitle: l10n.createTripStorageSubtitle,
                selectedProvider: _cloudProvider,
                onTap: _selectCloudProvider,
              ),
              const SizedBox(height: 28),

              CreateTripButton(
                label: l10n.createTripCreate,
                isEnabled: _canCreateTrip,
                onPressed: _createTrip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
