import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
class AtlasBackground extends StatelessWidget {
  final Widget child;
  const AtlasBackground({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AtlasColors.background,
            AtlasColors.backgroundSecondary,
            AtlasColors.background,
          ],
        ),
      ),
      child: child,
    );
  }
}
