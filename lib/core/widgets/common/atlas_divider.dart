import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
class AtlasDivider extends StatelessWidget {
  final String text;
  const AtlasDivider({
    super.key,
    this.text = "oppure",
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(
            color: AtlasColors.border,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AtlasColors.white54,
            ),
          ),
        ),
        const Expanded(
          child: Divider(
            color: AtlasColors.border,
          ),
        ),
      ],
    );
  }
}
