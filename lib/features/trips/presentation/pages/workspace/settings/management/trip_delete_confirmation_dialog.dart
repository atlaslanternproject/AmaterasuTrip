import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripDeleteConfirmationDialog extends StatefulWidget {
  const TripDeleteConfirmationDialog({super.key, required this.tripName});

  final String tripName;

  @override
  State<TripDeleteConfirmationDialog> createState() =>
      _TripDeleteConfirmationDialogState();
}

class _TripDeleteConfirmationDialogState
    extends State<TripDeleteConfirmationDialog> {
  static const Color _surfaceColor = Color(0xFF1A1512);

  static const Color _titleColor = Color(0xFFF2E7D5);

  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  late final TextEditingController _controller;

  bool _matchesTripName = false;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _handleTextChanged(String value) {
    final matches = value == widget.tripName;

    if (matches == _matchesTripName) {
      return;
    }

    setState(() {
      _matchesTripName = matches;
    });
  }

  void _cancel() {
    Navigator.of(context).pop(false);
  }

  void _confirm() {
    if (!_matchesTripName) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: _surfaceColor,
      surfaceTintColor: Colors.transparent,
      title: Text(
        l10n.tripManagementDeleteTitle,
        style: const TextStyle(color: _titleColor, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
              ),
              child: Text(
                l10n.tripManagementFinalDeleteCloudWarning,
                style: TextStyle(
                  color: Colors.red.shade200,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.tripManagementFinalDeleteConfirmInstruction(widget.tripName),
              style: const TextStyle(color: _secondaryTextColor, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: _handleTextChanged,
              style: const TextStyle(color: _titleColor),
              decoration: InputDecoration(
                labelText: l10n.tripManagementFinalDeleteInputLabel,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _cancel, child: Text(l10n.tripManagementCancel)),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: _matchesTripName ? _confirm : null,
          child: Text(l10n.tripManagementDeleteConfirm),
        ),
      ],
    );
  }
}
