import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/domain/access/trip_access.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';
import 'package:amaterasutrip/features/trips/providers/trip_member_provider.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripTravellersSettingsPage extends ConsumerStatefulWidget {
  const TripTravellersSettingsPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<TripTravellersSettingsPage> createState() =>
      _TripTravellersSettingsPageState();
}

enum _InviteAction { copy, share, regenerate, revoke }

class _TripTravellersSettingsPageState
    extends ConsumerState<TripTravellersSettingsPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _surfaceColor = Color(0xFF1A1310);
  static const Color _surfaceRaisedColor = Color(0xFF221915);
  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _dangerColor = Color(0xFFE05A54);

  TripInviteCredentials? _activeInvite;
  Future<TripInviteCredentials>? _inviteRequest;

  String? _busyMemberUid;
  bool _inviteBusy = false;

  Future<TripInviteCredentials> _ensureInvite({bool forceNew = false}) async {
    if (forceNew) {
      _activeInvite = null;
    }

    final cached = _activeInvite;

    if (cached != null) {
      return cached;
    }

    final pending = _inviteRequest;

    if (pending != null) {
      return pending;
    }

    final request = ref
        .read(tripInviteRepositoryProvider)
        .createTripInvite(tripId: widget.tripId);

    _inviteRequest = request;

    try {
      final invite = await request;
      _activeInvite = invite;
      return invite;
    } finally {
      if (identical(_inviteRequest, request)) {
        _inviteRequest = null;
      }
    }
  }

  String _buildInvitationUrl(TripInviteCredentials invite) {
    final encodedTripId = Uri.encodeComponent(invite.tripId);

    final encodedToken = Uri.encodeQueryComponent(invite.token);

    return 'https://amaterasutrip.web.app/invite/'
        '$encodedTripId?token=$encodedToken';
  }

  Future<void> _copyInvitation() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final invite = await _ensureInvite();
      final url = _buildInvitationUrl(invite);

      await Clipboard.setData(ClipboardData(text: url));

      if (!mounted) {
        return;
      }

      _showMessage(l10n.tripTravellersInviteCopied);
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripCreatedInviteError);
      }
    }
  }

  Future<void> _shareInvitation(String tripName) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final invite = await _ensureInvite();
      final url = _buildInvitationUrl(invite);

      if (!mounted) {
        return;
      }

      await SharePlus.instance.share(
        ShareParams(
          subject: l10n.tripCreatedInviteShareSubject(tripName),
          text: l10n.tripCreatedInviteShareText(tripName, url),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripCreatedInviteError);
      }
    }
  }

  Future<void> _revokeInvite() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.tripTravellersRevokeInviteTitle),
          content: Text(l10n.tripTravellersRevokeInviteBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.tripTravellersCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.tripTravellersRevoke),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _inviteBusy = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('revokeTripInvite');

      await callable.call<Map<String, dynamic>>({'tripId': widget.tripId});

      _activeInvite = null;

      if (mounted) {
        _showMessage(l10n.tripTravellersInviteRevoked);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripTravellersInviteActionError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _inviteBusy = false;
        });
      }
    }
  }

  Future<void> _regenerateInvite(String tripName) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _inviteBusy = true;
    });

    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('revokeTripInvite');

      await callable.call<Map<String, dynamic>>({'tripId': widget.tripId});

      _activeInvite = null;

      final invite = await _ensureInvite(forceNew: true);

      final url = _buildInvitationUrl(invite);

      if (!mounted) {
        return;
      }

      _showMessage(l10n.tripTravellersInviteRegenerated);

      await SharePlus.instance.share(
        ShareParams(
          subject: l10n.tripCreatedInviteShareSubject(tripName),
          text: l10n.tripCreatedInviteShareText(tripName, url),
        ),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripTravellersInviteActionError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _inviteBusy = false;
        });
      }
    }
  }

  Future<void> _handleInviteAction({
    required _InviteAction action,
    required String tripName,
  }) async {
    switch (action) {
      case _InviteAction.copy:
        await _copyInvitation();

      case _InviteAction.share:
        await _shareInvitation(tripName);

      case _InviteAction.regenerate:
        await _regenerateInvite(tripName);

      case _InviteAction.revoke:
        await _revokeInvite();
    }
  }

  Future<void> _openMember(TripMember member, TripAccess? access) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final isCurrentUser = currentUid == member.uid;

    final canManage = access?.can(TripPermission.manageTravellers) ?? false;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surfaceColor,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _MemberDetailsSheet(
          member: member,
          isCurrentUser: isCurrentUser,
          canManage: canManage,
          busy: _busyMemberUid == member.uid,
          onEdit: isCurrentUser
              ? () {
                  Navigator.of(context).pop();

                  _editMyProfile(member);
                }
              : null,
          onRemove: !member.isAdmin && (isCurrentUser || canManage)
              ? () {
                  Navigator.of(context).pop();

                  _removeMember(member, isCurrentUser: isCurrentUser);
                }
              : null,
        );
      },
    );
  }

  Future<void> _editMyProfile(TripMember member) async {
    final saved = await context.push<bool>(
      '/trips/${widget.tripId}/settings/travellers/profile/edit',
    );

    if (!mounted || saved != true) {
      return;
    }

    ref.invalidate(tripMembersProvider(widget.tripId));

    _showMessage(AppLocalizations.of(context)!.tripTravellersProfileUpdated);
  }

  Future<void> _removeMember(
    TripMember member, {
    required bool isCurrentUser,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isCurrentUser
                ? l10n.tripTravellersLeaveTitle
                : l10n.tripTravellersRemoveTitle,
          ),
          content: Text(
            isCurrentUser
                ? l10n.tripTravellersLeaveBody
                : l10n.tripTravellersRemoveBody(
                    member.displayName ??
                        member.username ??
                        l10n.tripTravellersTravelerRole,
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.tripTravellersCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _dangerColor),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                isCurrentUser
                    ? l10n.tripTravellersLeaveConfirm
                    : l10n.tripTravellersRemoveConfirm,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busyMemberUid = member.uid;
    });

    try {
      final result = await ref
          .read(tripMemberRepositoryProvider)
          .removeMember(tripId: widget.tripId, targetUid: member.uid);

      if (!mounted) {
        return;
      }

      if (result.leftTrip) {
        context.go('/trips');
        return;
      }

      ref.invalidate(tripMembersProvider(widget.tripId));

      _showMessage(l10n.tripTravellersRemovedSuccess);
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.tripTravellersRemoveError);
      }
    } finally {
      if (mounted) {
        setState(() {
          _busyMemberUid = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    ref.invalidate(tripMembersProvider(widget.tripId));

    await ref.read(tripMembersProvider(widget.tripId).future);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final membersAsync = ref.watch(tripMembersProvider(widget.tripId));

    final tripAsync = ref.watch(tripProvider(widget.tripId));

    final access = ref.watch(tripAccessProvider(widget.tripId));

    final canInvite = access?.can(TripPermission.manageInvitations) ?? false;

    final trip = tripAsync.asData?.value;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l10n.tripSettingsTravellers,
              subtitle: l10n.tripTravellersSettingsIntro,
              onBack: () {
                context.go('/trips/${widget.tripId}/settings');
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    _InviteCard(
                      enabled: canInvite && trip != null,
                      busy: _inviteBusy,
                      title: l10n.tripTravellersInvite,
                      subtitle: l10n.tripTravellersInviteSubtitle,
                      onTap: trip == null
                          ? null
                          : () => _shareInvitation(trip.name),
                      onAction: trip == null
                          ? null
                          : (action) => _handleInviteAction(
                              action: action,
                              tripName: trip.name,
                            ),
                    ),
                    const SizedBox(height: 14),
                    _PrivacyNotice(
                      text: l10n.tripTravellersSensitiveDataNotice,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.tripTravellersParticipants,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    membersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, stackTrace) => _MessageCard(
                        icon: Icons.error_outline_rounded,
                        message: l10n.tripTravellersLoadError,
                      ),
                      data: (members) {
                        if (members.isEmpty) {
                          return _MessageCard(
                            icon: Icons.group_off_outlined,
                            message: l10n.tripTravellersEmpty,
                          );
                        }

                        return Column(
                          children: [
                            for (
                              var index = 0;
                              index < members.length;
                              index++
                            ) ...[
                              _MemberCard(
                                member: members[index],
                                currentUser: FirebaseAuth.instance.currentUser,
                                l10n: l10n,
                                busy: _busyMemberUid == members[index].uid,
                                onTap: () =>
                                    _openMember(members[index], access),
                              ),
                              if (index != members.length - 1)
                                const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
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
              color: _TripTravellersSettingsPageState._titleColor,
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
                    color: _TripTravellersSettingsPageState._titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _TripTravellersSettingsPageState._secondaryTextColor,
                    fontSize: 13,
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.enabled,
    required this.busy,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onAction,
  });

  final bool enabled;
  final bool busy;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final ValueChanged<_InviteAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: _TripTravellersSettingsPageState._surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _TripTravellersSettingsPageState._borderColor.withValues(
              alpha: 0.6,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: enabled && !busy ? onTap : null,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _TripTravellersSettingsPageState._accentColor
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: busy
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: _TripTravellersSettingsPageState
                                    ._accentColor,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: _TripTravellersSettingsPageState
                                    ._titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: _TripTravellersSettingsPageState
                                    ._secondaryTextColor,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (enabled && !busy)
              PopupMenuButton<_InviteAction>(
                color: _TripTravellersSettingsPageState._surfaceRaisedColor,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: _TripTravellersSettingsPageState._secondaryTextColor,
                ),
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _InviteAction.copy,
                    child: Text(l10n.tripTravellersCopyInvite),
                  ),
                  PopupMenuItem(
                    value: _InviteAction.share,
                    child: Text(l10n.tripTravellersShareInvite),
                  ),
                  PopupMenuItem(
                    value: _InviteAction.regenerate,
                    child: Text(l10n.tripTravellersRegenerateInvite),
                  ),
                  PopupMenuItem(
                    value: _InviteAction.revoke,
                    child: Text(l10n.tripTravellersRevokeInvite),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _TripTravellersSettingsPageState._accentColor.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _TripTravellersSettingsPageState._accentColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: _TripTravellersSettingsPageState._accentColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _TripTravellersSettingsPageState._secondaryTextColor,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.currentUser,
    required this.l10n,
    required this.busy,
    required this.onTap,
  });

  final TripMember member;
  final User? currentUser;
  final AppLocalizations l10n;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = currentUser?.uid == member.uid;

    final roleLabel = member.isAdmin
        ? l10n.tripTravellersOwnerRole
        : l10n.tripTravellersTravelerRole;

    final displayName =
        member.displayName ??
        (isCurrentUser
            ? l10n.tripTravellersYou
            : member.username ?? l10n.tripTravellersTravelerRole);

    return Material(
      color: _TripTravellersSettingsPageState._surfaceRaisedColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _TripTravellersSettingsPageState._borderColor.withValues(
                alpha: 0.55,
              ),
            ),
          ),
          child: Row(
            children: [
              _MemberAvatar(photoUrl: member.photoUrl, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                                  _TripTravellersSettingsPageState._titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${l10n.tripTravellersYou}',
                            style: const TextStyle(
                              color: _TripTravellersSettingsPageState
                                  ._secondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (member.username != null &&
                        member.displayName != member.username) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${member.username}',
                        style: const TextStyle(
                          color: _TripTravellersSettingsPageState
                              ._secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _TinyBadge(text: roleLabel),
                        _TinyBadge(
                          text: member.travellerProfileCompleted
                              ? l10n.tripTravellersProfileComplete
                              : l10n.tripTravellersProfileIncomplete,
                          muted: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color:
                          _TripTravellersSettingsPageState._secondaryTextColor,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.photoUrl, required this.size});

  final String? photoUrl;
  final double size;

  Widget _fallback() {
    return Transform.scale(
      scale: 1.33,
      alignment: const Alignment(0, 0.10),
      child: Image.asset(
        'assets/images/profile/amaterasu_profile_fallback.png',
        fit: BoxFit.cover,
        alignment: const Alignment(0, 0.13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = photoUrl?.trim() ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: _TripTravellersSettingsPageState._accentColor,
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: normalized.isEmpty
            ? _fallback()
            : Image.network(
                normalized,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fallback(),
              ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text, this.muted = false});

  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted
            ? _TripTravellersSettingsPageState._secondaryTextColor.withValues(
                alpha: 0.08,
              )
            : _TripTravellersSettingsPageState._accentColor.withValues(
                alpha: 0.12,
              ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: muted
              ? _TripTravellersSettingsPageState._secondaryTextColor
              : _TripTravellersSettingsPageState._accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MemberDetailsSheet extends StatelessWidget {
  const _MemberDetailsSheet({
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
    required this.busy,
    required this.onEdit,
    required this.onRemove,
  });

  final TripMember member;
  final bool isCurrentUser;
  final bool canManage;
  final bool busy;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final profile = member.travellerProfile;

    final role = member.isAdmin
        ? l10n.tripTravellersOwnerRole
        : l10n.tripTravellersTravelerRole;

    final name =
        member.displayName ??
        member.username ??
        l10n.tripTravellersTravelerRole;

    final joinedAt = member.joinedAt == null
        ? l10n.tripTravellersUnknown
        : MaterialLocalizations.of(context).formatMediumDate(member.joinedAt!);

    String yesNo(bool? value) {
      if (value == null) {
        return l10n.tripTravellersNotProvided;
      }

      return value ? l10n.tripTravellersYes : l10n.tripTravellersNo;
    }

    String textOrMissing(String value) {
      final trimmed = value.trim();

      return trimmed.isEmpty ? l10n.tripTravellersNotProvided : trimmed;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _MemberAvatar(photoUrl: member.photoUrl, size: 82)),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _TripTravellersSettingsPageState._titleColor,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (member.username != null) ...[
              const SizedBox(height: 3),
              Text(
                '@${member.username}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _TripTravellersSettingsPageState._secondaryTextColor,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _InfoSection(
              title: l10n.tripTravellersMembership,
              rows: [
                _InfoRowData(label: l10n.tripTravellersRole, value: role),
                _InfoRowData(
                  label: l10n.tripTravellersJoinedAt,
                  value: joinedAt,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: l10n.tripTravellersOrganisation,
              rows: [
                _InfoRowData(
                  label: l10n.tripTravellersEsim,
                  value: yesNo(profile.hasEsimOrInternet),
                ),
                _InfoRowData(
                  label: l10n.tripTravellersCheckedBaggage,
                  value: yesNo(profile.hasCheckedBaggage),
                ),
                _InfoRowData(
                  label: l10n.tripTravellersCabinBaggage,
                  value: yesNo(profile.hasCabinBaggage10Kg),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: l10n.tripTravellersHealth,
              rows: [
                _InfoRowData(
                  label: l10n.tripTravellersAllergies,
                  value: textOrMissing(profile.allergies),
                ),
                _InfoRowData(
                  label: l10n.tripTravellersIntolerances,
                  value: textOrMissing(profile.intolerances),
                ),
                _InfoRowData(
                  label: l10n.tripTravellersAccessibility,
                  value: textOrMissing(profile.medicalAccessibilityInfo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoSection(
              title: l10n.tripTravellersEmergency,
              rows: [
                _InfoRowData(
                  label: l10n.tripTravellersEmergencyName,
                  value: textOrMissing(profile.emergencyContactName),
                ),
                _InfoRowData(
                  label: l10n.tripTravellersEmergencyPhone,
                  value: textOrMissing(profile.emergencyContactPhone),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (onEdit != null)
              FilledButton.icon(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.tripTravellersEditMyProfile),
              ),
            if (onRemove != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _TripTravellersSettingsPageState._dangerColor,
                ),
                onPressed: busy ? null : onRemove,
                icon: Icon(
                  isCurrentUser
                      ? Icons.logout_rounded
                      : Icons.person_remove_alt_1_rounded,
                ),
                label: Text(
                  isCurrentUser
                      ? l10n.tripTravellersLeave
                      : l10n.tripTravellersRemove,
                ),
              ),
            ],
            if (member.isAdmin) ...[
              const SizedBox(height: 12),
              Text(
                l10n.tripTravellersOwnerProtected,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _TripTravellersSettingsPageState._secondaryTextColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TripTravellersSettingsPageState._surfaceRaisedColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _TripTravellersSettingsPageState._borderColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _TripTravellersSettingsPageState._titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < rows.length; index++) ...[
            _InfoRow(data: rows[index]),
            if (index != rows.length - 1) const Divider(height: 20),
          ],
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({required this.label, required this.value});

  final String label;
  final String value;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            data.label,
            style: const TextStyle(
              color: _TripTravellersSettingsPageState._secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            data.value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _TripTravellersSettingsPageState._titleColor,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _TripTravellersSettingsPageState._surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _TripTravellersSettingsPageState._borderColor.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _TripTravellersSettingsPageState._secondaryTextColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _TripTravellersSettingsPageState._secondaryTextColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
