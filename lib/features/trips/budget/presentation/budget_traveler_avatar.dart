import 'package:flutter/material.dart';

/// Traveler avatar using Amaterasu's existing profile fallback.
///
/// Profile URL comes from the membership-checked listTripMembers
/// projection. Broken or absent images use the official asset.
class BudgetTravelerAvatar extends StatelessWidget {
  const BudgetTravelerAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 34,
  });

  final String name;
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
    final uri = Uri.tryParse(normalized);

    final validUrl =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.hasAuthority;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD96C32), width: 1.5),
      ),
      child: ClipOval(
        child: !validUrl
            ? _fallback()
            : Image.network(
                normalized,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(),
              ),
      ),
    );
  }
}
