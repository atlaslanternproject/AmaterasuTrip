import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:amaterasutrip/core/notifications/firebase_messaging_service.dart';
import 'package:amaterasutrip/features/settings/providers/notification_permission_provider.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_notification_preferences.dart';
import 'package:amaterasutrip/features/trips/data/repositories/trip_notification_preferences_repository.dart';
import 'package:amaterasutrip/features/trips/domain/access/trip_access.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripNotificationsSettingsPage extends ConsumerStatefulWidget {
  const TripNotificationsSettingsPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripNotificationsSettingsPage> createState() =>
      _TripNotificationsSettingsPageState();
}

class _TripNotificationsSettingsPageState
    extends ConsumerState<TripNotificationsSettingsPage>
    with WidgetsBindingObserver {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _cardColor = Color(0xFF1A1411);
  static const Color _accentColor = Color(0xFFE28A32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _subtitleColor = Color(0xFF9E9287);
  static const Color _disabledColor = Color(0xFF5E554F);
  static const Color _dividerColor = Color(0xFF302722);

  static const TripNotificationPreferencesRepository _repository =
      TripNotificationPreferencesRepository();

  TripNotificationPreferences _preferences =
      const TripNotificationPreferences();

  bool _loading = true;
  bool _saving = false;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationPermissionProvider.notifier).refreshStatus();
    }
  }

  Future<void> _load() async {
    final uid = _uid;

    if (uid == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      return;
    }

    try {
      final loaded = await _repository.load(uid: uid, tripId: widget.tripId);

      if (!mounted) return;

      setState(() {
        _preferences = loaded;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showError();
    }
  }

  Future<void> _setMaster(bool value) async {
    if (_saving) return;

    final uid = _uid;

    if (uid == null) {
      _showError();
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      var finalValue = value;

      if (value) {
        final status = await ref
            .read(notificationPermissionProvider.notifier)
            .requestPermission();

        if (!status.isGranted) {
          finalValue = false;

          if (mounted) {
            _showPermissionDenied(status);
          }
        } else {
          await FirebaseMessagingService.instance.syncCurrentUserToken();
        }
      }

      await _repository.setMaster(
        uid: uid,
        tripId: widget.tripId,
        value: finalValue,
      );

      if (!mounted) return;

      setState(() {
        _preferences = _preferences.copyWith(masterEnabled: finalValue);
      });
    } catch (_) {
      _showError();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _setCategory(
    TripNotificationCategory category,
    bool value,
  ) async {
    if (_saving) return;

    final uid = _uid;

    if (uid == null) {
      _showError();
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _repository.setCategory(
        uid: uid,
        tripId: widget.tripId,
        category: category,
        value: value,
      );

      if (!mounted) return;

      setState(() {
        _preferences = _preferences.withCategory(category, value);
      });
    } catch (_) {
      _showError();
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showError() {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.tripNotificationsSaveError)));
  }

  void _showPermissionDenied(PermissionStatus status) {
    final l10n = AppLocalizations.of(context)!;

    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.tripNotificationsPermissionDenied),
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: l10n.tripNotificationsOpenAndroidSettings,
                  onPressed: _openAndroidSettings,
                )
              : null,
        ),
      );
  }

  Future<void> _openAndroidSettings() async {
    await ref.read(notificationPermissionProvider.notifier).openSettings();
  }

  List<_TripNotificationSection> _sections(AppLocalizations l10n) {
    return [
      _TripNotificationSection(
        title: l10n.tripNotificationsTimingSection,
        items: [
          _TripNotificationItem(
            category: TripNotificationCategory.departureDates,
            title: l10n.tripNotificationsDepartureDates,
            subtitle: l10n.tripNotificationsDepartureDatesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.itineraryReminders,
            title: l10n.tripNotificationsItineraryReminders,
            subtitle: l10n.tripNotificationsItineraryRemindersSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.itineraryUpdates,
            title: l10n.tripNotificationsItineraryUpdates,
            subtitle: l10n.tripNotificationsItineraryUpdatesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.bookingReminders,
            title: l10n.tripNotificationsBookingReminders,
            subtitle: l10n.tripNotificationsBookingRemindersSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.bookingUpdates,
            title: l10n.tripNotificationsBookingUpdates,
            subtitle: l10n.tripNotificationsBookingUpdatesSubtitle,
          ),
        ],
      ),
      _TripNotificationSection(
        title: l10n.tripNotificationsPlanningSection,
        items: [
          _TripNotificationItem(
            category: TripNotificationCategory.bucketList,
            title: l10n.tripNotificationsBucketList,
            subtitle: l10n.tripNotificationsBucketListSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.bucketListVotes,
            title: l10n.tripNotificationsBucketListVotes,
            subtitle: l10n.tripNotificationsBucketListVotesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.budget,
            title: l10n.tripNotificationsBudget,
            subtitle: l10n.tripNotificationsBudgetSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.newExpenses,
            title: l10n.tripNotificationsNewExpenses,
            subtitle: l10n.tripNotificationsNewExpensesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.expenseChanges,
            title: l10n.tripNotificationsExpenseChanges,
            subtitle: l10n.tripNotificationsExpenseChangesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.reimbursements,
            title: l10n.tripNotificationsReimbursements,
            subtitle: l10n.tripNotificationsReimbursementsSubtitle,
          ),
        ],
      ),
      _TripNotificationSection(
        title: l10n.tripNotificationsGroupSection,
        items: [
          _TripNotificationItem(
            category: TripNotificationCategory.travellers,
            title: l10n.tripNotificationsTravellers,
            subtitle: l10n.tripNotificationsTravellersSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.invitations,
            title: l10n.tripNotificationsInvitations,
            subtitle: l10n.tripNotificationsInvitationsSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.rolesPermissions,
            title: l10n.tripNotificationsRolesPermissions,
            subtitle: l10n.tripNotificationsRolesPermissionsSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.groupActivity,
            title: l10n.tripNotificationsGroupActivity,
            subtitle: l10n.tripNotificationsGroupActivitySubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.sharedNotes,
            title: l10n.tripNotificationsSharedNotes,
            subtitle: l10n.tripNotificationsSharedNotesSubtitle,
          ),
        ],
      ),
      _TripNotificationSection(
        title: l10n.tripNotificationsContentSection,
        items: [
          _TripNotificationItem(
            category: TripNotificationCategory.media,
            title: l10n.tripNotificationsMedia,
            subtitle: l10n.tripNotificationsMediaSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.memories,
            title: l10n.tripNotificationsMemories,
            subtitle: l10n.tripNotificationsMemoriesSubtitle,
          ),
        ],
      ),
      _TripNotificationSection(
        title: l10n.tripNotificationsSystemSection,
        items: [
          _TripNotificationItem(
            category: TripNotificationCategory.cloudArchive,
            title: l10n.tripNotificationsCloudArchive,
            subtitle: l10n.tripNotificationsCloudArchiveSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.sync,
            title: l10n.tripNotificationsSync,
            subtitle: l10n.tripNotificationsSyncSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.tripInformationChanges,
            title: l10n.tripNotificationsTripInformationChanges,
            subtitle: l10n.tripNotificationsTripInformationChangesSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.tripStatus,
            title: l10n.tripNotificationsTripStatus,
            subtitle: l10n.tripNotificationsTripStatusSubtitle,
          ),
          _TripNotificationItem(
            category: TripNotificationCategory.importantCommunications,
            title: l10n.tripNotificationsImportantCommunications,
            subtitle: l10n.tripNotificationsImportantCommunicationsSubtitle,
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tripAsync = ref.watch(tripProvider(widget.tripId));

    final access = ref.watch(tripAccessProvider(widget.tripId));

    final permission = ref.watch(notificationPermissionProvider).asData?.value;

    if (tripAsync.isLoading || _loading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(child: CircularProgressIndicator(color: _accentColor)),
      );
    }

    final canView = access?.can(TripPermission.viewNotifications) ?? false;

    final canManage = access?.can(TripPermission.manageNotifications) ?? false;

    if (!canView) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                title: l10n.tripSettingsNotifications,
                onBack: () => context.go('/trips/${widget.tripId}/settings'),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    l10n.tripNotificationsAccessDenied,
                    style: const TextStyle(color: _subtitleColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final sections = _sections(l10n);

    final categoriesEnabled =
        _preferences.masterEnabled && canManage && !_saving;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tripSettingsNotifications,
              onBack: () => context.go('/trips/${widget.tripId}/settings'),
            ),
            Expanded(
              child: ListView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text(
                    l10n.tripNotificationsIntro,
                    style: const TextStyle(
                      color: _subtitleColor,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),

                  _NotificationSettingsCard(
                    children: [
                      _NotificationSwitchTile(
                        title: l10n.tripNotificationsMaster,
                        subtitle: l10n.tripNotificationsMasterSubtitle,
                        value: _preferences.masterEnabled,
                        enabled: canManage && !_saving,
                        onChanged: _setMaster,
                      ),
                    ],
                  ),

                  if (permission != null && !permission.isGranted) ...[
                    const SizedBox(height: 12),
                    _PermissionNotice(
                      title: l10n.tripNotificationsSystemPermission,
                      body: l10n.tripNotificationsSystemPermissionBlocked,
                      buttonLabel: l10n.tripNotificationsOpenAndroidSettings,
                      onPressed: _openAndroidSettings,
                    ),
                  ],

                  const SizedBox(height: 22),

                  for (final section in sections) ...[
                    _SectionTitle(section.title),
                    const SizedBox(height: 8),

                    _NotificationSettingsCard(
                      children: [
                        for (
                          var index = 0;
                          index < section.items.length;
                          index++
                        ) ...[
                          _NotificationSwitchTile(
                            title: section.items[index].title,
                            subtitle: section.items[index].subtitle,
                            value: _preferences.isEnabled(
                              section.items[index].category,
                            ),
                            enabled: categoriesEnabled,
                            onChanged: (value) => _setCategory(
                              section.items[index].category,
                              value,
                            ),
                          ),
                          if (index < section.items.length - 1)
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: _dividerColor,
                            ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 22),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripNotificationSection {
  const _TripNotificationSection({required this.title, required this.items});

  final String title;
  final List<_TripNotificationItem> items;
}

class _TripNotificationItem {
  const _TripNotificationItem({
    required this.category,
    required this.title,
    required this.subtitle,
  });

  final TripNotificationCategory category;
  final String title;
  final String subtitle;
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: _TripNotificationsSettingsPageState._titleColor,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _TripNotificationsSettingsPageState._titleColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _TripNotificationsSettingsPageState._cardColor,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  const _NotificationSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeThumbColor: _TripNotificationsSettingsPageState._accentColor,
        activeTrackColor: _TripNotificationsSettingsPageState._accentColor
            .withValues(alpha: 0.35),
        inactiveThumbColor: _TripNotificationsSettingsPageState._disabledColor,
        title: Text(
          title,
          style: const TextStyle(
            color: _TripNotificationsSettingsPageState._titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: _TripNotificationsSettingsPageState._subtitleColor,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TripNotificationsSettingsPageState._cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _TripNotificationsSettingsPageState._accentColor.withValues(
            alpha: 0.28,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_off_outlined,
                color: _TripNotificationsSettingsPageState._accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _TripNotificationsSettingsPageState._titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: _TripNotificationsSettingsPageState._subtitleColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.settings_outlined),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: _TripNotificationsSettingsPageState._subtitleColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
