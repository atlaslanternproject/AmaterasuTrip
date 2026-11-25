// Pannello per scrivere una segnalazione o un'idea (Extra F): testo fino
// a 2000 caratteri, invio con il limite di 5 al giorno, messaggio chiaro se
// il limite è raggiunto o l'invio non riesce. Nessun dato automatico.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/core/widgets/buttons/amaterasu_button.dart';
import 'package:amaterasutrip/core/widgets/dialogs/amaterasu_sheet.dart';
import 'package:amaterasutrip/features/support/data/feedback_repository.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

Future<void> showFeedbackSheet(BuildContext context, FeedbackKind kind) =>
    showAmaterasuSheet<void>(context, builder: (_) => _FeedbackSheet(kind));

class _FeedbackSheet extends ConsumerStatefulWidget {
  const _FeedbackSheet(this.kind);

  final FeedbackKind kind;

  @override
  ConsumerState<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends ConsumerState<_FeedbackSheet> {
  final _text = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    if (_text.text.trim().isEmpty) {
      setState(() => _error = l10n.supportFeedbackEmpty);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final language = Localizations.localeOf(context).languageCode;
    String version = '1.0.0';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    final result = await ref
        .read(feedbackRepositoryProvider)
        .send(widget.kind, _text.text, appVersion: version, language: language);
    if (!mounted) return;
    if (result == FeedbackResult.sent) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(SnackBar(content: Text(l10n.supportFeedbackSent)));
      return;
    }
    setState(() {
      _sending = false;
      _error = result == FeedbackResult.dailyLimit
          ? l10n.supportFeedbackLimit
          : l10n.supportFeedbackFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bug = widget.kind == FeedbackKind.bug;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bug ? l10n.supportReportProblem : l10n.supportSuggestIdea,
            style: const TextStyle(
              color: AmaterasuColors.textCream,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bug ? l10n.supportFeedbackBugHint : l10n.supportFeedbackIdeaHint,
            style: const TextStyle(color: AmaterasuColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('support-feedback-text'),
            controller: _text,
            minLines: 4,
            maxLines: 8,
            maxLength: FirestoreFeedbackRepository.textMax,
            enabled: !_sending,
          ),
          if (_error != null)
            Text(
              _error!,
              key: const Key('support-feedback-error'),
              style: const TextStyle(color: AmaterasuColors.error),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: AmaterasuButton.primary(
              key: const Key('support-feedback-send'),
              label: l10n.supportFeedbackSend,
              onPressed: _sending ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}
