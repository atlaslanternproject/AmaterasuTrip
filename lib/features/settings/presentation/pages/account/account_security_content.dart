import 'package:flutter/material.dart';

import 'first_root_activation_card.dart';

import 'account_recovery_device_actions.dart';

/// Account security UI shared by Android and Web.
/// No QR-based device authorisation is exposed here.
class AccountSecurityContent extends StatelessWidget {
  const AccountSecurityContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FirstDeviceBootstrapCard(),
        SizedBox(height: 18),
        AccountRecoveryDeviceActions(),
      ],
    );
  }
}
