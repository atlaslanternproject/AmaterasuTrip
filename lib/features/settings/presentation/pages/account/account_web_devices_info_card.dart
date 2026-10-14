import 'package:flutter/material.dart';

import 'package:amaterasutrip/l10n/app_localizations.dart';

/// Informational Web device-security panel.
///
/// The Android enrollment scanner must not be exposed as if it
/// could authorise Web devices. This panel grants no trust.
class AccountWebDevicesInfoCard extends StatelessWidget {
  const AccountWebDevicesInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF211A16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF74502C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.devices_other_outlined,
                color: Color(0xFFE7A044),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l.accountE2eeDeviceTitle,
                  style: const TextStyle(
                    color: Color(0xFFF2E7D5),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l.accountWebDevicesInfo,
            style: const TextStyle(
              color: Color(0xFFE2D1BD),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
