import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_radius.dart';
import '../../theme/atlas_spacing.dart';
class AtlasCard extends StatelessWidget {
  final Widget child;
  const AtlasCard({
    super.key,
    required this.child,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      padding: const EdgeInsets.all(
        AtlasSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AtlasColors.card,
        borderRadius: BorderRadius.circular(
          AtlasRadius.lg,
        ),
        border: Border.all(
          color: AtlasColors.border,
        ),
      ),
      child: child,
    );
  }
}
