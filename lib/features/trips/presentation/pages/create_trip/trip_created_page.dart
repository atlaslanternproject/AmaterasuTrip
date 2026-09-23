import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripCreatedPage extends StatelessWidget {
  const TripCreatedPage({
    super.key,
    required this.tripName,
    required this.onInviteTravellers,
    required this.onCopyLink,
    required this.onShare,
    required this.onEnterTrip,
  });

  final String tripName;
  final VoidCallback onInviteTravellers;
  final VoidCallback onCopyLink;
  final VoidCallback onShare;
  final VoidCallback onEnterTrip;

  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE35B28);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 34, 22, 32),
          child: Column(
            children: [
              const _SuccessHero(),
              const SizedBox(height: 30),

              Text(
                l10n.tripCreatedTitle(tripName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _creamColor,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                l10n.tripCreatedSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 30),

              _PrimaryButton(
                label: l10n.tripCreatedInviteTravellers,
                icon: Icons.group_add_outlined,
                onTap: onInviteTravellers,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      label: l10n.tripCreatedCopyLink,
                      icon: Icons.link_rounded,
                      onTap: onCopyLink,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      label: l10n.tripCreatedShare,
                      icon: Icons.ios_share_rounded,
                      onTap: onShare,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _SecondaryButton(
                label: l10n.tripCreatedEnterTrip,
                icon: Icons.arrow_forward_rounded,
                onTap: onEnterTrip,
              ),
              const SizedBox(height: 30),

              const _BottomDecoration(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 190,
        height: 190,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: TripCreatedPage._accentColor.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: TripCreatedPage._accentColor.withValues(alpha: 0.18),
              blurRadius: 38,
              spreadRadius: 4,
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7A2E1D), Color(0xFF351711), Color(0xFF160D0A)],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              top: 35,
              child: Icon(
                Icons.wb_sunny_outlined,
                color: Color(0x55F4A261),
                size: 76,
              ),
            ),
            const Positioned(
              bottom: 31,
              child: Icon(
                Icons.temple_buddhist_rounded,
                color: TripCreatedPage._creamColor,
                size: 92,
              ),
            ),
            Positioned(
              right: 25,
              top: 30,
              child: Transform.rotate(
                angle: 0.45,
                child: const Icon(
                  Icons.local_florist_outlined,
                  color: Color(0x99F2B5A7),
                  size: 22,
                ),
              ),
            ),
            Positioned(
              left: 24,
              top: 65,
              child: Transform.rotate(
                angle: -0.4,
                child: const Icon(
                  Icons.local_florist_outlined,
                  color: Color(0x77F2B5A7),
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: double.infinity,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: const LinearGradient(
              colors: [Color(0xFFB93622), Color(0xFFE35B28), Color(0xFFF08A38)],
            ),
            boxShadow: [
              BoxShadow(
                color: TripCreatedPage._accentColor.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: TripCreatedPage._creamColor, size: 21),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: TripCreatedPage._creamColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: TripCreatedPage._surfaceColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: TripCreatedPage._borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: TripCreatedPage._creamColor, size: 20),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TripCreatedPage._creamColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomDecoration extends StatelessWidget {
  const _BottomDecoration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TripCreatedPage._borderColor),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1711), Color(0xFF18100D), Color(0xFF100C0A)],
        ),
      ),
      child: const Stack(
        children: [
          Positioned(
            left: 20,
            bottom: 10,
            child: Icon(
              Icons.landscape_outlined,
              color: Color(0x33F2E7D5),
              size: 70,
            ),
          ),
          Positioned(
            right: 22,
            bottom: 12,
            child: Icon(
              Icons.flight_takeoff_rounded,
              color: Color(0x55E35B28),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}
