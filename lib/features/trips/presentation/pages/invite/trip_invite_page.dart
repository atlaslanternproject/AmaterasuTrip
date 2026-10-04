import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/data/repositories/trip_invite_repository.dart';
import 'package:amaterasutrip/features/trips/presentation/pages/invite/trip_traveller_questionnaire_page.dart';
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
              onContinue: () {
                Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    transitionDuration: const Duration(milliseconds: 160),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 140,
                    ),
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        TripTravellerQuestionnairePage(
                          tripId: widget.tripId,
                          token: widget.token,
                          tripName: invite.name,
                          coverUrl: invite.coverUrl,
                        ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          );

                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.025),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                  ),
                );
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
                child: Text(l10n.tripInviteContinue),
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
