import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/core/navigation/invite_auth_return.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/providers/trip_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripInvitePage extends ConsumerStatefulWidget {
  const TripInvitePage({super.key, required this.tripId, required this.token});

  final String tripId;
  final String token;

  @override
  ConsumerState<TripInvitePage> createState() => _TripInvitePageState();
}

class _TripInvitePageState extends ConsumerState<TripInvitePage> {
  late final Future<ValidatedTripInvite> _inviteFuture;

  @override
  void initState() {
    super.initState();

    _inviteFuture = ref
        .read(tripInviteRepositoryProvider)
        .validateTripInvite(tripId: widget.tripId, token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tripInviteAppBarTitle)),
      body: SafeArea(
        child: FutureBuilder<ValidatedTripInvite>(
          future: _inviteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _InviteError(
                onRetry: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => TripInvitePage(
                        tripId: widget.tripId,
                        token: widget.token,
                      ),
                    ),
                  );
                },
              );
            }

            final invite = snapshot.data;

            if (invite == null) {
              return const _InviteError();
            }

            return _InviteContent(
              invite: invite,
              onContinue: () async {
                final returnTo = Uri(
                  path: '/trip-invite/${widget.tripId}',
                  queryParameters: {'token': widget.token},
                ).toString();

                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  context.go(InviteAuthReturn.route('/', returnTo));
                  return;
                }

                if (!user.emailVerified) {
                  context.go(InviteAuthReturn.route('/verify-email', returnTo));
                  return;
                }

                try {
                  await ref
                      .read(tripInviteRepositoryProvider)
                      .joinTripInvite(
                        tripId: widget.tripId,
                        token: widget.token,
                      );
                  if (!mounted) return;
                  this.context.go('/trips/${widget.tripId}');
                } on FirebaseFunctionsException catch (error) {
                  if (!mounted) return;
                  final message = switch (error.code) {
                    'already-exists' => 'Sei gia membro del viaggio.',
                    'permission-denied' => 'Invito non valido o revocato.',
                    'failed-precondition' => 'Verifica la tua email.',
                    _ => 'Impossibile confermare la partecipazione.',
                  };
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                } catch (error) {
                  debugPrint('AMATERASU_JOIN_ERROR_TYPE: ${error.runtimeType}');
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Impossibile confermare la partecipazione.',
                      ),
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _InviteContent extends StatelessWidget {
  const _InviteContent({required this.invite, required this.onContinue});

  final ValidatedTripInvite invite;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final materialLocalizations = MaterialLocalizations.of(context);

    final startDate = invite.startDate == null
        ? null
        : materialLocalizations.formatMediumDate(invite.startDate!);

    final endDate = invite.endDate == null
        ? null
        : materialLocalizations.formatMediumDate(invite.endDate!);

    final dateLabel = switch ((startDate, endDate)) {
      (final String start, final String end) => '$start - $end',
      (final String start, null) => start,
      (null, final String end) => end,
      _ => null,
    };

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.card_travel_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.tripInviteHeading,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invite.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined),
                          const SizedBox(width: 8),
                          Expanded(child: Text(invite.destination)),
                        ],
                      ),
                      if (dateLabel != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined),
                            const SizedBox(width: 8),
                            Expanded(child: Text(dateLabel)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onContinue,
                child: Text(
                  Localizations.localeOf(context).languageCode == 'it'
                      ? 'Partecipa al viaggio'
                      : 'Join the trip',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteError extends StatelessWidget {
  const _InviteError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.tripInviteUnavailableTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.tripInviteUnavailableBody, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: onRetry,
                  child: Text(l10n.tripInviteRetry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
