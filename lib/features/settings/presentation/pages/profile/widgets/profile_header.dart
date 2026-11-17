import 'package:flutter/material.dart';

import 'package:amaterasutrip/features/profile/models/user_profile.dart';
import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/theme/amaterasu_spacing.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onChangePhoto,
  });

  static const Color _accentColor = AmaterasuColors.accentSettings;
  static const Color _titleColor = AmaterasuColors.textPrimary;
  static const Color _subtitleColor = AmaterasuColors.textMuted;

  final UserProfile profile;
  final VoidCallback onChangePhoto;

  String get _fullName {
    final parts = <String>[
      if (profile.firstName?.trim().isNotEmpty ?? false)
        profile.firstName!.trim(),
      if (profile.lastName?.trim().isNotEmpty ?? false)
        profile.lastName!.trim(),
    ];

    return parts.join(' ');
  }

  Widget _buildProfileImage() {
    final photoUrl = profile.photoUrl?.trim();

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackImage();
        },
      );
    }

    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
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
    return Column(
      children: [
        GestureDetector(
          onTap: onChangePhoto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _accentColor, width: 2),
                ),
                child: ClipOval(child: _buildProfileImage()),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 17,
                    color: AmaterasuColors.surfaceDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.username,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _titleColor,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (_fullName.isNotEmpty) ...[
          const SizedBox(height: AmaterasuSpacing.xs),
          Text(
            _fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _subtitleColor, fontSize: 14),
          ),
        ],
      ],
    );
  }
}
