import 'dart:io';

import 'package:flutter/material.dart';

class TripCoverPicker extends StatelessWidget {
  const TripCoverPicker({
    super.key,
    required this.changePhotoLabel,
    required this.onTap,
    this.localImagePath,
  });

  final String changePhotoLabel;
  final VoidCallback onTap;
  final String? localImagePath;

  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _creamColor = Color(0xFFF2E7D5);

  bool get _hasLocalImage =>
      localImagePath != null && localImagePath!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 205,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor.withValues(alpha: 0.75)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF542116), Color(0xFF21100C), Color(0xFF0F0B09)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasLocalImage)
            Image.file(
              File(localImagePath!),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                return const _TripCoverFallback();
              },
            )
          else
            const _TripCoverFallback(),

          if (_hasLocalImage)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x08000000),
                    Color(0x18000000),
                    Color(0xA6000000),
                  ],
                ),
              ),
            ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Material(
                color: const Color(0xCC100C0A),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_camera_outlined,
                          size: 20,
                          color: _creamColor,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          changePhotoLabel,
                          style: const TextStyle(
                            color: _creamColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCoverFallback extends StatelessWidget {
  const _TripCoverFallback();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF542116), Color(0xFF21100C), Color(0xFF0F0B09)],
            ),
          ),
        ),
        Positioned(
          right: 24,
          top: 24,
          child: Icon(
            Icons.temple_buddhist_rounded,
            size: 92,
            color: Color(0x22F59A5B),
          ),
        ),
        Positioned(
          left: 24,
          bottom: 24,
          child: Icon(
            Icons.landscape_rounded,
            size: 100,
            color: Color(0x18F2E7D5),
          ),
        ),
      ],
    );
  }
}
