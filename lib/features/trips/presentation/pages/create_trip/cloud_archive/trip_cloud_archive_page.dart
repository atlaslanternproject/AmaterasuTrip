import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive_selection.dart';
import 'package:amaterasutrip/features/trips/providers/trip_cloud_archive_provider.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';

class TripCloudArchivePage extends ConsumerStatefulWidget {
  const TripCloudArchivePage({super.key, this.currentArchive});

  final TripCloudArchive? currentArchive;

  @override
  ConsumerState<TripCloudArchivePage> createState() =>
      _TripCloudArchivePageState();
}

class _TripCloudArchivePageState extends ConsumerState<TripCloudArchivePage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);

  bool _authorizingGoogleDrive = false;

  Future<void> _openGoogleDriveOptions() async {
    if (_authorizingGoogleDrive) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    final option = await showModalBottomSheet<_GoogleDriveLocationOption>(
      context: context,
      backgroundColor: const Color(0xFF1A1715),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tripCloudGoogleDriveLocationTitle,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tripCloudGoogleDriveLocationDescription,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _LocationOptionTile(
                  icon: Icons.cloud_outlined,
                  title: l10n.tripCloudGoogleDriveRoot,
                  subtitle: l10n.tripCloudGoogleDriveRootSubtitle,
                  onTap: () {
                    Navigator.of(context).pop(_GoogleDriveLocationOption.root);
                  },
                ),
                const SizedBox(height: 10),
                _LocationOptionTile(
                  icon: Icons.folder_open_rounded,
                  title: l10n.tripCloudGoogleDriveChooseFolder,
                  subtitle: l10n.tripCloudGoogleDriveChooseFolderSubtitle,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pop(_GoogleDriveLocationOption.folder);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || option == null) {
      return;
    }

    switch (option) {
      case _GoogleDriveLocationOption.root:
        await _authorizeGoogleDriveRoot();
      case _GoogleDriveLocationOption.folder:
        await _authorizeGoogleDriveFolder();
    }
  }

  Future<void> _authorizeGoogleDriveRoot() async {
    final rootFolderName = AppLocalizations.of(
      context,
    )!.tripCloudGoogleDriveRoot;

    await _runGoogleDriveAuthorization(() async {
      final service = ref.read(googleDriveArchiveServiceProvider);
      final authorization = await service.authorizeRootNative();

      if (authorization == null) {
        return null;
      }

      return TripCloudArchiveSelection(
        provider: TripCloudProvider.googleDrive,
        parentFolderId: 'root',
        parentFolderName: rootFolderName,
        isRoot: true,
      );
    });
  }

  Future<void> _authorizeGoogleDriveFolder() async {
    await _runGoogleDriveAuthorization(() async {
      final service = ref.read(googleDriveArchiveServiceProvider);
      final authorization = await service.authorizeNative();

      if (authorization == null) {
        return null;
      }

      final folder = await service.getFolder(authorization.folderId);

      if (!mounted) {
        return null;
      }

      return TripCloudArchiveSelection(
        provider: TripCloudProvider.googleDrive,
        parentFolderId: authorization.folderId,
        parentFolderName: folder?.name,
      );
    });
  }

  Future<void> _runGoogleDriveAuthorization(
    Future<TripCloudArchiveSelection?> Function() action,
  ) async {
    if (_authorizingGoogleDrive) {
      return;
    }

    setState(() {
      _authorizingGoogleDrive = true;
    });

    try {
      final selection = await action();

      if (!mounted || selection == null) {
        return;
      }

      Navigator.of(context).pop(selection);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.tripCloudGoogleDriveError,
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _authorizingGoogleDrive = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: _titleColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.tripCloudTitle,
          style: const TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Text(
              l10n.tripCloudHeading,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tripCloudDescription,
              style: const TextStyle(
                color: _secondaryTextColor,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            _ProviderCard(
              icon: Icons.add_to_drive_outlined,
              title: l10n.tripCloudGoogleDrive,
              subtitle: l10n.tripCloudGoogleDriveSubtitle,
              isSelected:
                  widget.currentArchive?.provider ==
                  TripCloudProvider.googleDrive,
              isLoading: _authorizingGoogleDrive,
              onTap: _openGoogleDriveOptions,
            ),
            const SizedBox(height: 12),
            _ProviderCard(
              icon: Icons.cloud_outlined,
              title: l10n.tripCloudOneDrive,
              subtitle: l10n.tripCloudProviderComingSoon,
              isSelected:
                  widget.currentArchive?.provider == TripCloudProvider.oneDrive,
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _ProviderCard(
              icon: Icons.inventory_2_outlined,
              title: l10n.tripCloudDropbox,
              subtitle: l10n.tripCloudProviderComingSoon,
              isSelected:
                  widget.currentArchive?.provider == TripCloudProvider.dropbox,
              enabled: false,
              onTap: () {},
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accentColor.withValues(alpha: 0.24)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: _accentColor,
                    size: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.tripCloudPrivacyNote,
                      style: const TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GoogleDriveLocationOption { root, folder }

class _LocationOptionTile extends StatelessWidget {
  const _LocationOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF241B17),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const SizedBox(width: 2),
              Icon(
                icon,
                color: _TripCloudArchivePageState._accentColor,
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _TripCloudArchivePageState._titleColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _TripCloudArchivePageState._secondaryTextColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _TripCloudArchivePageState._secondaryTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;
  final bool isLoading;

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && !isLoading;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: interactive ? onTap : null,
          borderRadius: BorderRadius.circular(17),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: isSelected
                    ? _accentColor.withValues(alpha: 0.65)
                    : _borderColor,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _accentColor.withValues(alpha: 0.12)
                        : const Color(0xFF241B17),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: _accentColor,
                          ),
                        )
                      : Icon(
                          icon,
                          color: isSelected ? _accentColor : _titleColor,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _titleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (!isLoading)
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: isSelected ? _accentColor : _secondaryTextColor,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
