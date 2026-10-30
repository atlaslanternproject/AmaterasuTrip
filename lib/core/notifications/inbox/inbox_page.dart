import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:amaterasutrip/core/notifications/inbox/inbox_notification.dart';
import 'package:amaterasutrip/core/notifications/inbox/inbox_repository.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  static const background = Color(0xFF100C0A);
  static const surface = Color(0xFF1A1411);
  static const accent = Color(0xFFE28A32);
  static const primary = Color(0xFFF2E7D5);
  static const secondary = Color(0xFF9E9287);

  final InboxRepository _repository = InboxRepository();
  bool _archived = false;
  String? _pendingId;

  void _error() {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.inboxActionError)),
      );
  }

  Future<void> _perform(String id, Future<void> Function() action) async {
    if (_pendingId != null) return;

    setState(() => _pendingId = id);

    try {
      await action();
    } catch (_) {
      _error();
    } finally {
      if (mounted) {
        setState(() => _pendingId = null);
      }
    }
  }

  Future<void> _delete(InboxNotification item) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.inboxDeleteTitle),
        content: Text(l10n.inboxDeleteDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.inboxCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.inboxDelete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _perform(item.id, () => _repository.delete(item.id));
    }
  }

  Widget _notificationTile(InboxNotification item, AppLocalizations l10n) {
    final busy = _pendingId != null;
    final date = MaterialLocalizations.of(
      context,
    ).formatMediumDate(item.createdAt.toLocal());

    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isRead
                      ? Icons.notifications_none_rounded
                      : Icons.notifications_active_outlined,
                  color: item.isRead ? secondary : accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: primary,
                          fontWeight: item.isRead
                              ? FontWeight.w500
                              : FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.body,
                        style: const TextStyle(color: secondary, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        date,
                        style: const TextStyle(color: secondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                if (!item.isRead)
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => _perform(
                            item.id,
                            () => _repository.markRead(item.id),
                          ),
                    icon: const Icon(Icons.done_rounded, size: 18),
                    label: Text(l10n.inboxMarkRead),
                  ),
                if (_archived)
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => _perform(
                            item.id,
                            () => _repository.restore(item.id),
                          ),
                    icon: const Icon(Icons.unarchive_outlined, size: 18),
                    label: Text(l10n.inboxRestore),
                  )
                else
                  TextButton.icon(
                    onPressed: busy
                        ? null
                        : () => _perform(
                            item.id,
                            () => _repository.archive(item.id),
                          ),
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: Text(l10n.inboxArchive),
                  ),
                TextButton.icon(
                  onPressed: busy ? null : () => _delete(item),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.inboxDelete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: primary,
        title: Text(l10n.inboxTitle),
        leading: IconButton(
          onPressed: () => context.go('/settings/notifications'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: user == null
          ? Center(
              child: Text(
                l10n.inboxAuthenticationRequired,
                style: const TextStyle(color: primary),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          selected: {_archived},
                          onSelectionChanged: (values) {
                            setState(() => _archived = values.first);
                          },
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l10n.inboxActive),
                              icon: const Icon(Icons.inbox_outlined),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l10n.inboxArchived),
                              icon: const Icon(Icons.archive_outlined),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<InboxNotification>>(
                    key: ValueKey('${user.uid}:$_archived'),
                    stream: _archived
                        ? _repository.watchArchived()
                        : _repository.watchActive(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.inboxLoadError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: secondary),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: accent),
                        );
                      }

                      final items = snapshot.data!;

                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mark_email_read_outlined,
                                  color: accent,
                                  size: 42,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _archived
                                      ? l10n.inboxEmptyArchive
                                      : l10n.inboxEmpty,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: primary),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _notificationTile(items[index], l10n),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
