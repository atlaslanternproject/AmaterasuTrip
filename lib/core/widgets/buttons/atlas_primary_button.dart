import 'package:flutter/material.dart';
import '../../theme/atlas_colors.dart';
import '../../theme/atlas_radius.dart';
class AtlasPrimaryButton extends StatelessWidget {
  final String text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final bool loading;
  const AtlasPrimaryButton({
  super.key,
  required this.text,
  required this.onPressed,
  this.loading = false,
  this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              AtlasRadius.md,
            ),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 12),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
