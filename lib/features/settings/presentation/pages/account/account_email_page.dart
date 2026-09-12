import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:amaterasutrip/core/widgets/auth/amaterasu_email_verification_card.dart';
import 'package:amaterasutrip/features/auth/providers/auth_controller.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

part 'account_email_actions.dart';
part 'account_email_dialogs.dart';
part 'account_email_widgets.dart';

class AccountEmailPage extends ConsumerStatefulWidget {
  const AccountEmailPage({super.key});

  @override
  ConsumerState<AccountEmailPage> createState() => _AccountEmailPageState();
}

class _AccountEmailPageState extends ConsumerState<AccountEmailPage>
    with _AccountEmailActions {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final user = ref.watch(authControllerProvider).currentUser;

    final email = user?.email ?? l10n.accountEmailUnavailable;

    return Column(
      children: [
        _AccountSubItem(
          icon: Icons.alternate_email,
          title: l10n.accountEmailCurrent,
          subtitle: email,
          onTap: () {},
        ),
        _AccountSubItem(
          icon: _verified
              ? Icons.verified_outlined
              : Icons.mark_email_unread_outlined,
          title: _verified
              ? l10n.accountEmailVerified
              : l10n.accountEmailNotVerified,
          subtitle: _verified
              ? l10n.accountEmailVerifiedDescription
              : l10n.accountEmailVerify,
          onTap: _verified
              ? _refreshVerificationStatus
              : _resendVerificationEmail,
        ),
        _AccountSubItem(
          icon: Icons.edit_outlined,
          title: l10n.accountEmailChange,
          subtitle: l10n.accountEmailChangeDescription,
          onTap: _showChangeEmailDialog,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
