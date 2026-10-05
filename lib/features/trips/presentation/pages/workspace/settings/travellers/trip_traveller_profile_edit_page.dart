import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_unsaved_changes_dialog.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripTravellerProfileEditPage extends ConsumerStatefulWidget {
  const TripTravellerProfileEditPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripTravellerProfileEditPage> createState() =>
      _TripTravellerProfileEditPageState();
}

class _TripTravellerProfileEditPageState
    extends ConsumerState<TripTravellerProfileEditPage> {
  // Stessa famiglia visiva del questionario reale.
  static const Color _background = Color(0xFF120E0B);
  static const Color _settingsHeader = Color(0xFF100C0A);
  static const Color _surface = Color(0xFF1D1612);
  static const Color _surfaceRaised = Color(0xFF261C16);

  static const Color _cream = Color(0xFFF4E7D3);
  static const Color _muted = Color(0xFFCDBDA8);

  static const Color _gold = Color(0xFFD6A34A);
  static const Color _vermilion = Color(0xFFB9432F);
  static const Color _deepVermilion = Color(0xFF70261D);

  TextEditingController? _allergiesController;
  TextEditingController? _intolerancesController;
  TextEditingController? _accessibilityController;
  TextEditingController? _emergencyNameController;
  TextEditingController? _emergencyPhoneController;

  bool? _hasEsimOrInternet;
  bool? _hasCheckedBaggage;
  bool? _hasCabinBaggage10Kg;
  bool? _hasAllergies;
  bool? _hasIntolerances;
  bool? _hasMedicalAccessibilityInfo;

  String _emergencyCountryFlag = '🇮🇹';
  String _emergencyPhonePrefix = '+39';

  bool _initialized = false;
  bool _dirty = false;
  bool _saving = false;

  bool get _requiredAnswersCompleted =>
      _hasEsimOrInternet != null &&
      _hasCheckedBaggage != null &&
      _hasCabinBaggage10Kg != null &&
      _hasAllergies != null &&
      _hasIntolerances != null &&
      _hasMedicalAccessibilityInfo != null;

  bool get _conditionalDetailsCompleted =>
      (_hasAllergies != true || _allergiesController!.text.trim().isNotEmpty) &&
      (_hasIntolerances != true ||
          _intolerancesController!.text.trim().isNotEmpty) &&
      (_hasMedicalAccessibilityInfo != true ||
          _accessibilityController!.text.trim().isNotEmpty);

  bool get _canSave =>
      _initialized &&
      _requiredAnswersCompleted &&
      _conditionalDetailsCompleted &&
      !_saving;
  void _initialize(TripMember member) {
    if (_initialized) {
      return;
    }

    final profile = member.travellerProfile;

    _hasEsimOrInternet = profile.hasEsimOrInternet;
    _hasCheckedBaggage = profile.hasCheckedBaggage;
    _hasCabinBaggage10Kg = profile.hasCabinBaggage10Kg;

    _hasAllergies =
        profile.hasAllergies ??
        (profile.allergies.trim().isNotEmpty ? true : null);

    _hasIntolerances =
        profile.hasIntolerances ??
        (profile.intolerances.trim().isNotEmpty ? true : null);

    _hasMedicalAccessibilityInfo =
        profile.hasMedicalAccessibilityInfo ??
        (profile.medicalAccessibilityInfo.trim().isNotEmpty ? true : null);

    _allergiesController = TextEditingController(text: profile.allergies);

    _intolerancesController = TextEditingController(text: profile.intolerances);

    _accessibilityController = TextEditingController(
      text: profile.medicalAccessibilityInfo,
    );

    _emergencyNameController = TextEditingController(
      text: profile.emergencyContactName,
    );

    _emergencyPhoneController = TextEditingController(
      text: _prepareEmergencyPhone(profile.emergencyContactPhone),
    );

    _allergiesController!.addListener(_markDirty);
    _intolerancesController!.addListener(_markDirty);
    _accessibilityController!.addListener(_markDirty);
    _emergencyNameController!.addListener(_markDirty);
    _emergencyPhoneController!.addListener(_markDirty);

    _initialized = true;
  }

  void _markDirty() {
    if (!_initialized || !mounted) {
      return;
    }

    setState(() {
      _dirty = true;
    });
  }

  void _setEsim(bool value) {
    setState(() {
      _hasEsimOrInternet = value;
      _dirty = true;
    });
  }

  void _setCheckedBaggage(bool value) {
    setState(() {
      _hasCheckedBaggage = value;
      _dirty = true;
    });
  }

  void _setCabinBaggage(bool value) {
    setState(() {
      _hasCabinBaggage10Kg = value;
      _dirty = true;
    });
  }

  void _setAllergies(bool value) {
    setState(() {
      _hasAllergies = value;
      _dirty = true;
    });

    if (!value) {
      _allergiesController!.clear();
    }
  }

  void _setIntolerances(bool value) {
    setState(() {
      _hasIntolerances = value;
      _dirty = true;
    });

    if (!value) {
      _intolerancesController!.clear();
    }
  }

  void _setMedicalAccessibility(bool value) {
    setState(() {
      _hasMedicalAccessibilityInfo = value;
      _dirty = true;
    });

    if (!value) {
      _accessibilityController!.clear();
    }
  }

  String _prepareEmergencyPhone(String storedPhone) {
    final value = storedPhone.trim();

    if (value.isEmpty) {
      _emergencyCountryFlag = '🇮🇹';
      _emergencyPhonePrefix = '+39';
      return '';
    }

    final match = RegExp(r'^(\+\d{1,4})\s+(.+)$').firstMatch(value);

    if (match == null) {
      return value;
    }

    final prefix = match.group(1)!;

    _emergencyPhonePrefix = prefix;

    if (prefix == '+39') {
      _emergencyCountryFlag = '🇮🇹';
    } else {
      _emergencyCountryFlag = '🌐';
    }

    return match.group(2)!.trim();
  }

  String _buildEmergencyPhone() {
    final number = _emergencyPhoneController!.text.trim();

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
          labelStyle: const TextStyle(color: _muted),
          hintStyle: const TextStyle(color: _muted),
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
          _dirty = true;
        });
      },
    );
  }

  TripTravellerProfileData _currentProfile() {
    return TripTravellerProfileData(
      hasEsimOrInternet: _hasEsimOrInternet,
      hasCheckedBaggage: _hasCheckedBaggage,
      hasCabinBaggage10Kg: _hasCabinBaggage10Kg,
      hasAllergies: _hasAllergies,
      hasIntolerances: _hasIntolerances,
      hasMedicalAccessibilityInfo: _hasMedicalAccessibilityInfo,
      allergies: _hasAllergies == true ? _allergiesController!.text.trim() : '',
      intolerances: _hasIntolerances == true
          ? _intolerancesController!.text.trim()
          : '',
      medicalAccessibilityInfo: _hasMedicalAccessibilityInfo == true
          ? _accessibilityController!.text.trim()
          : '',
      emergencyContactName: _emergencyNameController!.text.trim(),
      emergencyContactPhone: _buildEmergencyPhone(),
    );
  }

  Future<bool> _save() async {
    if (!_canSave) {
      return false;
    }

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _saving = true;
    });

    try {
      await ref
          .read(tripMemberRepositoryProvider)
          .updateMyTravellerProfile(
            tripId: widget.tripId,
            profile: _currentProfile(),
          );

      ref.invalidate(tripMembersProvider(widget.tripId));

      _dirty = false;

      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(l10n.tripTravellersProfileUpdateError)),
          );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _saveAndExit() async {
    final saved = await _save();

    if (!mounted || !saved) {
      return;
    }

    context.pop(true);
  }

  void _discardAndExit() {
    if (!mounted) {
      return;
    }

    context.pop(false);
  }

  Future<void> _requestExit() async {
    if (_saving) {
      return;
    }

    if (!_initialized || !_dirty) {
      context.pop(false);
      return;
    }

    final action = await showAmaterasuUnsavedChangesDialog(context);

    if (!mounted) {
      return;
    }

    switch (action) {
      case AmaterasuUnsavedChangesAction.saveAndExit:
        await _saveAndExit();

      case AmaterasuUnsavedChangesAction.discard:
        _discardAndExit();

      case AmaterasuUnsavedChangesAction.cancel:
        return;
    }
  }

  @override
  void dispose() {
    _allergiesController?.dispose();
    _intolerancesController?.dispose();
    _accessibilityController?.dispose();
    _emergencyNameController?.dispose();
    _emergencyPhoneController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final membersAsync = ref.watch(tripMembersProvider(widget.tripId));

    final tripAsync = ref.watch(tripProvider(widget.tripId));

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _requestExit();
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Column(
            children: [
              _EditHeader(
                title: l10n.tripTravellersEditProfileTitle,
                subtitle: l10n.tripTravellersEditProfileNote,
                saving: _saving,
                onBack: _requestExit,
              ),
              Expanded(
                child: membersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) {
                    return _StateMessage(
                      icon: Icons.error_outline_rounded,
                      text: l10n.tripTravellersLoadError,
                    );
                  },
                  data: (members) {
                    TripMember? currentMember;

                    for (final member in members) {
                      if (member.uid == currentUid) {
                        currentMember = member;
                        break;
                      }
                    }

                    if (currentMember == null) {
                      return _StateMessage(
                        icon: Icons.person_off_outlined,
                        text: l10n.tripTravellersLoadError,
                      );
                    }

                    _initialize(currentMember);

                    final trip = tripAsync.asData?.value;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _QuestionnaireHero(
                                tripName: trip?.name ?? '',
                                coverUrl: trip?.coverUrl,
                                subtitle: l10n.tripQuestionnaireIntro,
                              ),
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
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              _QuestionnaireSection(
                                icon: Icons.route_rounded,
                                title:
                                    l10n.tripQuestionnaireOrganisationSection,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _YesNoQuestion(
                                      title: l10n.tripQuestionnaireEsim,
                                      required: true,
                                      value: _hasEsimOrInternet,
                                      yesLabel: l10n.tripQuestionnaireYes,
                                      noLabel: l10n.tripQuestionnaireNo,
                                      enabled: !_saving,
                                      onChanged: _setEsim,
                                    ),

                                    const SizedBox(height: 24),

                                    _YesNoQuestion(
                                      title:
                                          l10n.tripQuestionnaireCheckedBaggage,
                                      required: true,
                                      value: _hasCheckedBaggage,
                                      yesLabel: l10n.tripQuestionnaireYes,
                                      noLabel: l10n.tripQuestionnaireNo,
                                      enabled: !_saving,
                                      onChanged: _setCheckedBaggage,
                                    ),

                                    const SizedBox(height: 24),

                                    _YesNoQuestion(
                                      title: l10n.tripQuestionnaireCabinBaggage,
                                      required: true,
                                      value: _hasCabinBaggage10Kg,
                                      yesLabel: l10n.tripQuestionnaireYes,
                                      noLabel: l10n.tripQuestionnaireNo,
                                      enabled: !_saving,
                                      onChanged: _setCabinBaggage,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              _QuestionnaireSection(
                                icon: Icons.health_and_safety_outlined,
                                title: l10n.tripQuestionnaireOptionalSection,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _YesNoQuestion(
                                      title: l10n
                                          .tripQuestionnaireAllergiesQuestion,
                                      required: true,
                                      value: _hasAllergies,
                                      yesLabel: l10n.tripQuestionnaireYes,
                                      noLabel: l10n.tripQuestionnaireNo,
                                      enabled: !_saving,
                                      onChanged: _setAllergies,
                                    ),

                                    if (_hasAllergies == true) ...[
                                      const SizedBox(height: 14),
                                      _QuestionnaireTextField(
                                        controller: _allergiesController!,
                                        label: l10n.tripQuestionnaireAllergies,
                                        hint: l10n.tripQuestionnaireDetailsHint,
                                        enabled: !_saving,
                                      ),
                                    ],

                                    const SizedBox(height: 24),

                                    _YesNoQuestion(
                                      title: l10n
                                          .tripQuestionnaireIntolerancesQuestion,
                                      required: true,
                                      value: _hasIntolerances,
                                      yesLabel: l10n.tripQuestionnaireYes,
                                      noLabel: l10n.tripQuestionnaireNo,
                                      enabled: !_saving,
                                      onChanged: _setIntolerances,
                                    ),

                                    if (_hasIntolerances == true) ...[
                                      const SizedBox(height: 14),
                                      _QuestionnaireTextField(
                                        controller: _intolerancesController!,
                                        label:
                                            l10n.tripQuestionnaireIntolerances,
                                        hint: l10n.tripQuestionnaireDetailsHint,
                                        enabled: !_saving,
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
                                      enabled: !_saving,
                                      onChanged: _setMedicalAccessibility,
                                    ),

                                    if (_hasMedicalAccessibilityInfo ==
                                        true) ...[
                                      const SizedBox(height: 14),
                                      _QuestionnaireTextField(
                                        controller: _accessibilityController!,
                                        label:
                                            l10n.tripQuestionnaireAccessibility,
                                        hint: l10n.tripQuestionnaireDetailsHint,
                                        enabled: !_saving,
                                        minLines: 2,
                                        maxLines: 4,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.shield_outlined,
                                            color: _gold,
                                            size: 21,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                    color: _muted,
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

                              _QuestionnaireSection(
                                icon: Icons.emergency_outlined,
                                title: l10n.tripQuestionnaireEmergencySection,
                                child: Column(
                                  children: [
                                    _QuestionnaireTextField(
                                      controller: _emergencyNameController!,
                                      label:
                                          l10n.tripQuestionnaireEmergencyName,
                                      enabled: !_saving,
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),

                                    const SizedBox(height: 14),

                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 126,
                                          height: 58,
                                          child: OutlinedButton(
                                            onPressed: _saving
                                                ? null
                                                : _selectEmergencyCountry,
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _cream,
                                              backgroundColor: _surfaceRaised,
                                              side: BorderSide(
                                                color: _gold.withValues(
                                                  alpha: 0.28,
                                                ),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                  ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _emergencyCountryFlag,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    _emergencyPhonePrefix,
                                                    style: const TextStyle(
                                                      color: _cream,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                const Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  size: 18,
                                                  color: _gold,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: _QuestionnaireTextField(
                                            controller:
                                                _emergencyPhoneController!,
                                            label: l10n
                                                .tripQuestionnaireEmergencyPhone,
                                            hint:
                                                l10n.tripQuestionnairePhoneHint,
                                            enabled: !_saving,
                                            keyboardType: TextInputType.phone,
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _deepVermilion.withValues(
                                      alpha: 0.20,
                                    ),
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
                                            color: _muted,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              FilledButton.icon(
                                onPressed: _canSave ? _saveAndExit : null,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: Text(l10n.unsavedChangesSaveAndExit),
                              ),

                              const SizedBox(height: 8),

                              TextButton.icon(
                                onPressed: _saving ? null : _discardAndExit,
                                icon: const Icon(Icons.logout_rounded),
                                label: Text(l10n.unsavedChangesDiscard),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.title,
    required this.subtitle,
    required this.saving,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final bool saving;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _TripTravellerProfileEditPageState._settingsHeader,
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: saving ? null : onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _TripTravellerProfileEditPageState._cream,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _TripTravellerProfileEditPageState._cream,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TripTravellerProfileEditPageState._muted,
                    fontSize: 12,
                    height: 1.3,
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

class _QuestionnaireHero extends StatelessWidget {
  const _QuestionnaireHero({
    required this.tripName,
    required this.coverUrl,
    required this.subtitle,
  });

  final String tripName;
  final String? coverUrl;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final normalized = coverUrl?.trim();
    final hasCover = normalized != null && normalized.isNotEmpty;

    return Container(
      height: 238,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _TripTravellerProfileEditPageState._deepVermilion,
            Color(0xFF321A13),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _TripTravellerProfileEditPageState._gold.withValues(
            alpha: 0.45,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _TripTravellerProfileEditPageState._vermilion.withValues(
              alpha: 0.14,
            ),
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
              normalized,
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
                stops: [0, 0.42, 1],
                colors: [
                  Color(0x33120E0B),
                  Color(0x8A120E0B),
                  Color(0xF0120E0B),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  _TripTravellerProfileEditPageState._deepVermilion,
                  Color(0x6670261D),
                  Colors.transparent,
                ],
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
                    border: Border.all(
                      color: _TripTravellerProfileEditPageState._gold
                          .withValues(alpha: 0.72),
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    color: _TripTravellerProfileEditPageState._gold,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  tripName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TripTravellerProfileEditPageState._cream,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                    shadows: [Shadow(color: Color(0xCC000000), blurRadius: 8)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _TripTravellerProfileEditPageState._cream,
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

class _QuestionnaireSection extends StatelessWidget {
  const _QuestionnaireSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _TripTravellerProfileEditPageState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _TripTravellerProfileEditPageState._gold.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: _TripTravellerProfileEditPageState._gold,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _TripTravellerProfileEditPageState._cream,
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

  @override
  Widget build(BuildContext context) {
    final selected = value == null ? <bool>{} : <bool>{value!};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: _TripTravellerProfileEditPageState._cream,
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
                    color: _TripTravellerProfileEditPageState._vermilion,
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
                return _TripTravellerProfileEditPageState._vermilion;
              }

              return _TripTravellerProfileEditPageState._surfaceRaised;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (!enabled) {
                return _TripTravellerProfileEditPageState._muted.withValues(
                  alpha: 0.35,
                );
              }

              if (states.contains(WidgetState.selected)) {
                return _TripTravellerProfileEditPageState._cream;
              }

              return _TripTravellerProfileEditPageState._muted;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const BorderSide(
                  color: _TripTravellerProfileEditPageState._gold,
                  width: 1.2,
                );
              }

              return BorderSide(
                color: _TripTravellerProfileEditPageState._gold.withValues(
                  alpha: 0.20,
                ),
              );
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

class _QuestionnaireTextField extends StatelessWidget {
  const _QuestionnaireTextField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      cursorColor: _TripTravellerProfileEditPageState._gold,
      style: const TextStyle(color: _TripTravellerProfileEditPageState._cream),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: _TripTravellerProfileEditPageState._muted,
        ),
        hintStyle: TextStyle(
          color: _TripTravellerProfileEditPageState._muted.withValues(
            alpha: 0.65,
          ),
        ),
        filled: true,
        fillColor: _TripTravellerProfileEditPageState._surfaceRaised,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _TripTravellerProfileEditPageState._gold.withValues(
              alpha: 0.22,
            ),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _TripTravellerProfileEditPageState._gold,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: _TripTravellerProfileEditPageState._gold.withValues(
              alpha: 0.10,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: _TripTravellerProfileEditPageState._muted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _TripTravellerProfileEditPageState._muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
