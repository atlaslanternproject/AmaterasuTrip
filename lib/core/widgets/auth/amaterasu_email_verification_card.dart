import 'package:flutter/material.dart';
import 'package:amaterasutrip/core/widgets/buttons/Amaterasu_primary_button.dart';

class AmaterasuEmailVerificationCard extends StatelessWidget {
  final String title;
  final String description;
  final String confirmedText;
  final String resendText;
  final String? message;
  final VoidCallback onConfirmed;
  final VoidCallback onResend;
  const AmaterasuEmailVerificationCard({
    super.key,
    required this.title,
    required this.description,
    required this.confirmedText,
    required this.resendText,
    required this.onConfirmed,
    required this.onResend,
    this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1E26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            color: Colors.amber,
            size: 72,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          if (message != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                message!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
          ],
          AmaterasuPrimaryButton(text: confirmedText, onPressed: onConfirmed),
          const SizedBox(height: 12),
          TextButton(onPressed: onResend, child: Text(resendText)),
        ],
      ),
    );
  }
}
