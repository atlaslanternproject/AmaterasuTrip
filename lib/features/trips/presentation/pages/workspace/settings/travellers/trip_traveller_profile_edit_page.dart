import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/features/trips/models/trip_member.dart';
import 'package:amaterasutrip/features/trips/models/trip_organizational_profile.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';

class TripTravellerProfileEditPage extends ConsumerStatefulWidget {
  const TripTravellerProfileEditPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripTravellerProfileEditPage> createState() =>
      _TripTravellerProfileEditPageState();
}

class _TripTravellerProfileEditPageState
    extends ConsumerState<TripTravellerProfileEditPage> {
  static const _background = Color(0xFF120E0B);
  static const _surface = Color(0xFF211812);
  static const _cream = Color(0xFFF4E7D3);
  static const _muted = Color(0xFFCDBDA8);
  static const _gold = Color(0xFFD6A34A);
  static const _vermilion = Color(0xFFB9432F);

  bool? _internet;
  bool? _checked;
  bool? _cabin;

  bool _initialized = false;
  bool _dirty = false;
  bool _saving = false;

  bool get _complete => _internet != null && _checked != null && _cabin != null;

  String _t(String italian, String english) {
    final language = Localizations.localeOf(context).languageCode;
    return language == 'it' ? italian : english;
  }

  void _load(TripMember member) {
    if (_initialized) return;

    final profile = member.organizationalProfile;

    _internet = profile?.hasEsimOrInternet;
    _checked = profile?.hasCheckedBaggage;
    _cabin = profile?.hasCabinBaggage10Kg;

    _initialized = true;
  }

  void _changeInternet(bool value) {
    setState(() {
      _internet = value;
      _dirty = true;
    });
  }

  void _changeChecked(bool value) {
    setState(() {
      _checked = value;
      _dirty = true;
    });
  }

  void _changeCabin(bool value) {
    setState(() {
      _cabin = value;
      _dirty = true;
    });
  }

  Future<bool> _save() async {
    if (!_complete || _saving) return false;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    setState(() => _saving = true);

    try {
      final profile = TripOrganizationalProfile(
        hasEsimOrInternet: _internet,
        hasCheckedBaggage: _checked,
        hasCabinBaggage10Kg: _cabin,
      );

      await ref
          .read(tripMemberRepositoryProvider)
          .saveMyOrganizationalProfile(tripId: widget.tripId, profile: profile);

      ref.invalidate(tripMembersProvider(widget.tripId));

      if (!mounted) return false;

      setState(() => _dirty = false);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t(
                'Salvataggio non riuscito. Riprova.',
                'Unable to save. Please try again.',
              ),
            ),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Modifiche non salvate', 'Unsaved changes')),
        content: Text(
          _t(
            'Vuoi uscire senza salvare le risposte?',
            'Leave without saving your answers?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Resta', 'Stay')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t('Esci', 'Leave')),
          ),
        ],
      ),
    );

    return result == true;
  }

  Future<void> _back() async {
    if (_saving) return;

    if (await _confirmDiscard() && mounted) {
      context.pop();
    }
  }

  Future<void> _saveAndExit() async {
    if (await _save() && mounted) {
      context.pop();
    }
  }

  Widget _question({
    required String title,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _cream,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            selected: value == null ? <bool>{} : <bool>{value},
            segments: [
              ButtonSegment<bool>(
                value: true,
                label: Text(_t('Sì', 'Yes')),
                icon: const Icon(Icons.check_rounded),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text(_t('No', 'No')),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? _vermilion
                    : const Color(0xFF30231B);
              }),
              foregroundColor: const WidgetStatePropertyAll(_cream),
            ),
            onSelectionChanged: _saving
                ? null
                : (selection) {
                    if (selection.isNotEmpty) {
                      onChanged(selection.first);
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(tripMembersProvider(widget.tripId));
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: !_dirty && !_saving,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) {
          _back();
        }
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: _cream,
          leading: IconButton(
            onPressed: _saving ? null : _back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(_t('Il mio questionario', 'My questionnaire')),
        ),
        body: members.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _gold)),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _t(
                  'Impossibile caricare i dati del viaggio.',
                  'Unable to load trip information.',
                ),
                style: const TextStyle(color: _cream),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (items) {
            TripMember? me;

            for (final item in items) {
              if (item.uid == uid) {
                me = item;
                break;
              }
            }

            if (me == null) {
              return Center(
                child: Text(
                  _t(
                    'Non sei un membro attivo di questo viaggio.',
                    'You are not an active member of this trip.',
                  ),
                  style: const TextStyle(color: _cream),
                ),
              );
            }

            _load(me);

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 660),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF70261D), Color(0xFF302018)],
                            ),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.wb_sunny_outlined,
                                color: _gold,
                                size: 34,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _t(
                                  'Organizza il tuo viaggio',
                                  'Plan your journey',
                                ),
                                style: const TextStyle(
                                  color: _cream,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _t(
                                  'Tre semplici domande per organizzarti '
                                      'insieme agli altri viaggiatori.',
                                  'Three simple questions to help you '
                                      'plan with your fellow travelers.',
                                ),
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _question(
                          title: _t(
                            'Avrai una connessione Internet o una eSIM?',
                            'Will you have Internet access or an eSIM?',
                          ),
                          value: _internet,
                          onChanged: _changeInternet,
                        ),
                        const SizedBox(height: 14),
                        _question(
                          title: _t(
                            'Porterai un bagaglio da stiva?',
                            'Will you bring checked baggage?',
                          ),
                          value: _checked,
                          onChanged: _changeChecked,
                        ),
                        const SizedBox(height: 14),
                        _question(
                          title: _t(
                            'Porterai un bagaglio a mano da 10 kg?',
                            'Will you bring 10 kg cabin baggage?',
                          ),
                          value: _cabin,
                          onChanged: _changeCabin,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _complete && !_saving
                              ? _saveAndExit
                              : null,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving
                                ? _t('Salvataggio...', 'Saving...')
                                : _t(
                                    'Salva e torna al viaggio',
                                    'Save and exit',
                                  ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _vermilion,
                            foregroundColor: _cream,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _saving ? null : _back,
                          child: Text(
                            _t('Indietro', 'Back'),
                            style: const TextStyle(color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
