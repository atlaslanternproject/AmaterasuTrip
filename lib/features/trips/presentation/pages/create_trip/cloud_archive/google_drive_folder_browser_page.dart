import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amaterasutrip/features/trips/data/models/trip_cloud_archive.dart';
import 'package:amaterasutrip/features/trips/data/services/google_drive_archive_service.dart';
import 'package:amaterasutrip/features/trips/providers/trip_cloud_archive_provider.dart';

class GoogleDriveFolderBrowserPage extends ConsumerStatefulWidget {
  const GoogleDriveFolderBrowserPage({super.key, required this.tripFolderName});

  final String tripFolderName;

  @override
  ConsumerState<GoogleDriveFolderBrowserPage> createState() =>
      _GoogleDriveFolderBrowserPageState();
}

class _GoogleDriveFolderBrowserPageState
    extends ConsumerState<GoogleDriveFolderBrowserPage> {
  static const Color _backgroundColor = Color(0xFF100C0A);
  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _surfaceStrongColor = Color(0xFF241B17);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);

  final List<_DrivePathEntry> _path = <_DrivePathEntry>[
    const _DrivePathEntry(id: 'root', name: 'Il mio Drive'),
  ];

  List<GoogleDriveFolder> _folders = const <GoogleDriveFolder>[];
  bool _loading = true;
  bool _creatingTripFolder = false;
  bool _creatingFolder = false;

  String get _currentFolderId => _path.last.id;

  String get _currentFolderName => _path.last.name;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final service = ref.read(googleDriveArchiveServiceProvider);

      final folders = await service.listFolders(
        parentFolderId: _currentFolderId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _folders = folders;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Impossibile caricare le cartelle di Google Drive.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openFolder(GoogleDriveFolder folder) async {
    setState(() {
      _path.add(_DrivePathEntry(id: folder.id, name: folder.name));
    });

    await _loadFolders();
  }

  Future<void> _goToPathIndex(int index) async {
    if (index < 0 || index >= _path.length) {
      return;
    }

    if (index == _path.length - 1) {
      return;
    }

    setState(() {
      _path.removeRange(index + 1, _path.length);
    });

    await _loadFolders();
  }

  Future<void> _goUp() async {
    if (_path.length <= 1) {
      return;
    }

    setState(() {
      _path.removeLast();
    });

    await _loadFolders();
  }

  Future<void> _createNewFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surfaceColor,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Nuova cartella',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: _titleColor),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome cartella',
              labelStyle: TextStyle(color: _secondaryTextColor),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _accentColor),
              ),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();

              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: _secondaryTextColor),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final trimmed = controller.text.trim();

                if (trimmed.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmed);
                }
              },
              child: const Text('Crea'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      _creatingFolder = true;
    });

    try {
      final service = ref.read(googleDriveArchiveServiceProvider);

      final created = await service.createFolder(
        folderName: name,
        parentFolderId: _currentFolderId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _path.add(_DrivePathEntry(id: created.id, name: created.name));
      });

      await _loadFolders();
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Impossibile creare la cartella.');
    } finally {
      if (mounted) {
        setState(() {
          _creatingFolder = false;
        });
      }
    }
  }

  Future<void> _createTripFolderHere() async {
    if (_creatingTripFolder) {
      return;
    }

    setState(() {
      _creatingTripFolder = true;
    });

    try {
      final service = ref.read(googleDriveArchiveServiceProvider);

      final archive = await service.createTripArchive(
        tripName: widget.tripFolderName,
        parentFolderId: _currentFolderId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop<TripCloudArchive>(archive);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('Impossibile creare la cartella del viaggio.');
    } finally {
      if (mounted) {
        setState(() {
          _creatingTripFolder = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _path.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _path.length > 1) {
          _goUp();
        }
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _backgroundColor,
          foregroundColor: _titleColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Scegli dove salvare',
            style: TextStyle(color: _titleColor, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildLocationHeader(),
              _buildBreadcrumb(),
              Expanded(child: _buildFolderList()),
              _buildBottomArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.add_to_drive_outlined,
              color: _accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Drive',
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _currentFolderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: _path.length,
        separatorBuilder: (context, index) => const Icon(
          Icons.chevron_right_rounded,
          color: _secondaryTextColor,
          size: 18,
        ),
        itemBuilder: (context, index) {
          final item = _path[index];
          final current = index == _path.length - 1;

          return TextButton(
            onPressed: current ? null : () => _goToPathIndex(index),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              foregroundColor: current ? _titleColor : _accentColor,
              disabledForegroundColor: _titleColor,
            ),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: current ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentColor),
      );
    }

    if (_folders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_rounded,
                color: _secondaryTextColor,
                size: 44,
              ),
              SizedBox(height: 14),
              Text(
                'Questa cartella è vuota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Puoi creare qui la cartella del viaggio oppure aggiungere una nuova cartella.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      itemCount: _folders.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final folder = _folders[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openFolder(folder),
            borderRadius: BorderRadius.circular(15),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: _surfaceColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_rounded,
                    color: _accentColor,
                    size: 25,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _secondaryTextColor,
                    size: 21,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: _borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: _creatingFolder || _creatingTripFolder
                ? null
                : _createNewFolder,
            style: OutlinedButton.styleFrom(
              foregroundColor: _titleColor,
              side: const BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _creatingFolder
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accentColor,
                    ),
                  )
                : const Icon(Icons.create_new_folder_outlined),
            label: const Text('Nuova cartella'),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceStrongColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cartella del viaggio',
                  style: TextStyle(color: _secondaryTextColor, fontSize: 11.5),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.tripFolderName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _creatingTripFolder || _creatingFolder
                ? null
                : _createTripFolderHere,
            style: FilledButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accentColor.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            icon: _creatingTripFolder
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.create_new_folder_rounded),
            label: Text(
              _creatingTripFolder
                  ? 'Creazione in corso...'
                  : 'Crea la cartella qui',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrivePathEntry {
  const _DrivePathEntry({required this.id, required this.name});

  final String id;
  final String name;
}
