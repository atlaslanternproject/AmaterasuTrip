import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripTravellerQuestionnairePage extends ConsumerStatefulWidget {
  const TripTravellerQuestionnairePage({
    super.key,
    required this.tripId,
    required this.token,
    required this.tripName,
    this.coverUrl,
  });

  final String tripId;
  final String token;
  final String tripName;
  final String? coverUrl;

  @override
  ConsumerState<TripTravellerQuestionnairePage> createState() =>
      _TripTravellerQuestionnairePageState();
}

class _TripTravellerQuestionnairePageState
    extends ConsumerState<TripTravellerQuestionnairePage> {
  static const _background = Color(0xFF120E0B);
  static const _surface = Color(0xFF1D1612);
  static const _surfaceRaised = Color(0xFF261C16);
  static const _cream = Color(0xFFF4E7D3);
  static const _mutedCream = Color(0xFFCDBDA8);
  static const _gold = Color(0xFFD6A34A);
  static const _vermilion = Color(0xFFB9432F);
  static const _deepVermilion = Color(0xFF70261D);

  final _allergiesController = TextEditingController();
  final _intolerancesController = TextEditingController();
  final _medicalAccessibilityController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();

  bool? _hasEsimOrInternet;
  bool? _hasCheckedBaggage;
  bool? _hasCabinBaggage10Kg;
  bool? _hasAllergies;
  bool? _hasIntolerances;
  bool? _hasMedicalAccessibilityInfo;

  bool _presenceConfirmed = false;
  bool _isSubmitting = false;

  String _emergencyCountryFlag = '🇮🇹';
  String _emergencyPhonePrefix = '+39';

  bool get _requiredAnswersCompleted =>
      _hasEsimOrInternet != null &&
      _hasCheckedBaggage != null &&
      _hasCabinBaggage10Kg != null &&
      _hasAllergies != null &&
      _hasIntolerances != null &&
      _hasMedicalAccessibilityInfo != null;

  bool get _conditionalDetailsCompleted =>
      (_hasAllergies != true || _allergiesController.text.trim().isNotEmpty) &&
      (_hasIntolerances != true ||
          _intolerancesController.text.trim().isNotEmpty) &&
      (_hasMedicalAccessibilityInfo != true ||
          _medicalAccessibilityController.text.trim().isNotEmpty);

  bool get _canSubmit =>
      _requiredAnswersCompleted &&
      _conditionalDetailsCompleted &&
      _presenceConfirmed &&
      !_isSubmitting;

  @override
  void dispose() {
    _allergiesController.dispose();
    _intolerancesController.dispose();
    _medicalAccessibilityController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  String _trimOrEmpty(String value) {
    return value.trim();
  }

  String _buildEmergencyPhone() {
    final number = _emergencyContactPhoneController.text.trim();

    if (number.isEmpty) {
      return '';
    }

    return '$_emergencyPhonePrefix $number';
  }

  void _selectEmergencyCountry() {
    final l10n = AppLocalizations.of(context)!;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      useSafeArea: true,
      favorite: const ['IT', 'GB', 'US', 'JP'],
      countryListTheme: CountryListThemeData(
        flagSize: 26,
        backgroundColor: _surface,
        textStyle: const TextStyle(color: _cream, fontSize: 16),
        searchTextStyle: const TextStyle(color: _cream, fontSize: 16),
        bottomSheetHeight: MediaQuery.sizeOf(context).height * 0.72,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        inputDecoration: InputDecoration(
          labelText: l10n.tripQuestionnaireCountrySearch,
          hintText: l10n.tripQuestionnaireCountrySearchHint,
          labelStyle: const TextStyle(color: _mutedCream),
          hintStyle: const TextStyle(color: _mutedCream),
          prefixIcon: const Icon(Icons.search_rounded, color: _gold),
          filled: true,
          fillColor: _surfaceRaised,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: _gold.withValues(alpha: 0.28)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _gold, width: 1.5),
          ),
        ),
      ),
      onSelect: (country) {
        if (!mounted) {
          return;
        }

        setState(() {
          _emergencyCountryFlag = country.flagEmoji;
          _emergencyPhonePrefix = '+${country.phoneCode}';
        });
      },
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _mutedCream),
      hintStyle: TextStyle(color: _mutedCream.withValues(alpha: 0.65)),
      filled: true,
      fillColor: _surfaceRaised,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _gold.withValues(alpha: 0.22)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _gold.withValues(alpha: 0.10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final profile = TripTravellerProfile(
        hasEsimOrInternet: _hasEsimOrInternet!,
        hasCheckedBaggage: _hasCheckedBaggage!,
        hasCabinBaggage10Kg: _hasCabinBaggage10Kg!,
        hasAllergies: _hasAllergies!,
        hasIntolerances: _hasIntolerances!,
        hasMedicalAccessibilityInfo: _hasMedicalAccessibilityInfo!,
        allergies: _hasAllergies == true
            ? _trimOrEmpty(_allergiesController.text)
            : '',
        intolerances: _hasIntolerances == true
            ? _trimOrEmpty(_intolerancesController.text)
            : '',
        medicalAccessibilityInfo: _hasMedicalAccessibilityInfo == true
            ? _trimOrEmpty(_medicalAccessibilityController.text)
            : '',
        emergencyContactName: _trimOrEmpty(
          _emergencyContactNameController.text,
        ),
        emergencyContactPhone: _buildEmergencyPhone(),
      );
      await ref
          .read(tripInviteRepositoryProvider)
          .acceptTripInvite(
            tripId: widget.tripId,
            token: widget.token,
            travellerProfile: profile,
          );

      if (!mounted) {
        return;
      }

      context.go('/trips/${widget.tripId}');
    } catch (error, stackTrace) {
      debugPrint('Trip invite acceptance failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.tripQuestionnaireSubmitError)),
        );

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.tripQuestionnaireTitle,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(l10n),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Text(
                        '*',
                        style: TextStyle(
                          color: _vermilion,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.tripQuestionnaireRequiredLegend,
                        style: const TextStyle(
                          color: _mutedCream,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionCard(
                    icon: Icons.route_rounded,
                    title: l10n.tripQuestionnaireOrganisationSection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _YesNoQuestion(
                          title: l10n.tripQuestionnaireEsim,
                          required: true,
                          value: _hasEsimOrInternet,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasEsimOrInternet = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _YesNoQuestion(
                          title: l10n.tripQuestionnaireCheckedBaggage,
                          required: true,
                          value: _hasCheckedBaggage,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasCheckedBaggage = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _YesNoQuestion(
                          title: l10n.tripQuestionnaireCabinBaggage,
                          required: true,
                          value: _hasCabinBaggage10Kg,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasCabinBaggage10Kg = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.health_and_safety_outlined,
                    title: l10n.tripQuestionnaireOptionalSection,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _YesNoQuestion(
                          title: l10n.tripQuestionnaireAllergiesQuestion,
                          required: true,
                          value: _hasAllergies,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasAllergies = value;

                              if (!value) {
                                _allergiesController.clear();
                              }
                            });
                          },
                        ),
                        if (_hasAllergies == true) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _allergiesController,
                            enabled: !_isSubmitting,
                            cursorColor: _gold,
                            style: const TextStyle(color: _cream),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              label: l10n.tripQuestionnaireAllergies,
                              hint: l10n.tripQuestionnaireDetailsHint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _YesNoQuestion(
                          title: l10n.tripQuestionnaireIntolerancesQuestion,
                          required: true,
                          value: _hasIntolerances,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasIntolerances = value;

                              if (!value) {
                                _intolerancesController.clear();
                              }
                            });
                          },
                        ),
                        if (_hasIntolerances == true) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _intolerancesController,
                            enabled: !_isSubmitting,
                            cursorColor: _gold,
                            style: const TextStyle(color: _cream),
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              label: l10n.tripQuestionnaireIntolerances,
                              hint: l10n.tripQuestionnaireDetailsHint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        _YesNoQuestion(
                          title: l10n
                              .tripQuestionnaireMedicalAccessibilityQuestion,
                          required: true,
                          value: _hasMedicalAccessibilityInfo,
                          yesLabel: l10n.tripQuestionnaireYes,
                          noLabel: l10n.tripQuestionnaireNo,
                          enabled: !_isSubmitting,
                          onChanged: (value) {
                            setState(() {
                              _hasMedicalAccessibilityInfo = value;

                              if (!value) {
                                _medicalAccessibilityController.clear();
                              }
                            });
                          },
                        ),
                        if (_hasMedicalAccessibilityInfo == true) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _medicalAccessibilityController,
                            enabled: !_isSubmitting,
                            cursorColor: _gold,
                            style: const TextStyle(color: _cream),
                            minLines: 2,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              label: l10n.tripQuestionnaireAccessibility,
                              hint: l10n.tripQuestionnaireDetailsHint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.24),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: _gold,
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.tripQuestionnaireSafetyNoticeTitle,
                                      style: const TextStyle(
                                        color: _cream,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      l10n.tripQuestionnaireSafetyNoticeBody,
                                      style: const TextStyle(
                                        color: _mutedCream,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.emergency_outlined,
                    title: l10n.tripQuestionnaireEmergencySection,
                    child: Column(
                      children: [
                        TextField(
                          controller: _emergencyContactNameController,
                          enabled: !_isSubmitting,
                          cursorColor: _gold,
                          style: const TextStyle(color: _cream),
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration(
                            label: l10n.tripQuestionnaireEmergencyName,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 126,
                              height: 58,
                              child: OutlinedButton(
                                onPressed: _isSubmitting
                                    ? null
                                    : _selectEmergencyCountry,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _cream,
                                  backgroundColor: _surfaceRaised,
                                  side: BorderSide(
                                    color: _gold.withValues(alpha: 0.28),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _emergencyCountryFlag,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        _emergencyPhonePrefix,
                                        style: const TextStyle(
                                          color: _cream,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: _gold,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _emergencyContactPhoneController,
                                enabled: !_isSubmitting,
                                cursorColor: _gold,
                                style: const TextStyle(color: _cream),
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  label: l10n.tripQuestionnaireEmergencyPhone,
                                  hint: l10n.tripQuestionnairePhoneHint,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_requiredAnswersCompleted ||
                      !_conditionalDetailsCompleted)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _deepVermilion.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _vermilion.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: _gold,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.tripQuestionnaireRequiredHint,
                              style: const TextStyle(
                                color: _mutedCream,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_requiredAnswersCompleted ||
                      !_conditionalDetailsCompleted)
                    const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      checkboxTheme: CheckboxThemeData(
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return _vermilion;
                          }

                          return Colors.transparent;
                        }),
                        checkColor: const WidgetStatePropertyAll<Color>(_cream),
                        side: const BorderSide(color: _gold, width: 1.4),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _presenceConfirmed,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _presenceConfirmed = value ?? false;
                              });
                            },
                      activeColor: _vermilion,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: _cream,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          children: [
                            TextSpan(
                              text: l10n.tripQuestionnairePresenceConfirm,
                            ),
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(
                                color: _vermilion,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _vermilion,
                      foregroundColor: _cream,
                      disabledBackgroundColor: _surfaceRaised.withValues(
                        alpha: 0.85,
                      ),
                      disabledForegroundColor: _mutedCream.withValues(
                        alpha: 0.45,
                      ),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _cream,
                            ),
                          )
                        : Text(
                            l10n.tripQuestionnaireSubmit,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final coverUrl = widget.coverUrl?.trim();
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return Container(
      height: 238,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepVermilion, Color(0xFF321A13)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: _vermilion.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasCover)
            Image.network(
              coverUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.42, 1.0],
                colors: [
                  Color(0x33120E0B),
                  Color(0x8A120E0B),
                  Color(0xF0120E0B),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [_deepVermilion, Color(0x6670261D), Colors.transparent],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xB3120E0B),
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withValues(alpha: 0.72)),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: _gold,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  widget.tripName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tripQuestionnaireIntro,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 14,
                    height: 1.38,
                    shadows: [Shadow(color: Color(0xDD000000), blurRadius: 7)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  static const _surface = Color(0xFF1D1612);
  static const _cream = Color(0xFFF4E7D3);
  static const _gold = Color(0xFFD6A34A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: _gold, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _YesNoQuestion extends StatelessWidget {
  const _YesNoQuestion({
    required this.title,
    required this.required,
    required this.value,
    required this.yesLabel,
    required this.noLabel,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final bool required;
  final bool? value;
  final String yesLabel;
  final String noLabel;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  static const _cream = Color(0xFFF4E7D3);
  static const _mutedCream = Color(0xFFCDBDA8);
  static const _gold = Color(0xFFD6A34A);
  static const _vermilion = Color(0xFFB9432F);
  static const _surfaceRaised = Color(0xFF261C16);

  @override
  Widget build(BuildContext context) {
    final selected = value == null ? <bool>{} : <bool>{value!};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: _cream,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
            children: [
              TextSpan(text: title),
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: _vermilion,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment<bool>(
              value: true,
              label: Text(yesLabel),
              icon: const Icon(Icons.check_rounded),
            ),
            ButtonSegment<bool>(
              value: false,
              label: Text(noLabel),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
          selected: selected,
          emptySelectionAllowed: true,
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _vermilion;
              }

              return _surfaceRaised;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (!enabled) {
                return _mutedCream.withValues(alpha: 0.35);
              }

              if (states.contains(WidgetState.selected)) {
                return _cream;
              }

              return _mutedCream;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const BorderSide(color: _gold, width: 1.2);
              }

              return BorderSide(color: _gold.withValues(alpha: 0.20));
            }),
          ),
          onSelectionChanged: enabled
              ? (selection) {
                  if (selection.isNotEmpty) {
                    onChanged(selection.first);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
