part of 'trip_bucket_list_page.dart';

extension _BucketActivityEditor on _TripBucketListPageState {
  Future<void> _openEditor([BucketListItem? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final city = TextEditingController(text: existing?.city ?? '');
    final country = TextEditingController(text: existing?.country ?? '');
    final duration = TextEditingController(
      text: existing?.durationMinutes?.toString() ?? '',
    );
    final notes = TextEditingController(text: existing?.notes ?? '');
    final customCategory = TextEditingController(
      text: existing?.customCategory ?? '',
    );
    final linkControllers = <TextEditingController>[
      for (final link in existing?.usefulLinks ?? const <String>[])
        TextEditingController(text: link),
    ];
    if (linkControllers.isEmpty) {
      linkControllers.add(TextEditingController());
    }
    final search = TextEditingController();

    var type = (existing?.customCategory?.trim().isNotEmpty ?? false)
        ? BucketItemType.other
        : (existing?.type ?? BucketItemType.attraction);
    var saving = false;
    var searching = false;
    var selecting = false;
    var predictions = <DestinationPrediction>[];
    String? searchError;

    String? placeId = existing?.googlePlaceId;
    String? address = existing?.address;
    double? latitude = existing?.latitude;
    double? longitude = existing?.longitude;

    final language = Localizations.localeOf(context).languageCode;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> findPlaces() async {
              final query = search.text.trim();
              if (query.length < 2 || searching || selecting) return;

              setDialogState(() {
                searching = true;
                searchError = null;
                predictions = [];
              });

              try {
                final result = await _places.search(
                  query,
                  languageCode: language,
                );
                if (!dialogContext.mounted) return;
                setDialogState(() => predictions = result);
              } catch (_) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  searchError = _t(
                    'Ricerca non disponibile. Riprova.',
                    'Search unavailable. Please retry.',
                  );
                });
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => searching = false);
                }
              }
            }

            Future<void> selectPlace(DestinationPrediction prediction) async {
              if (selecting || saving) return;
              setDialogState(() {
                selecting = true;
                searchError = null;
              });
              try {
                final result = await _places.getDetails(
                  prediction.placeId,
                  languageCode: language,
                );
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  placeId = result.placeId;
                  address = result.formattedAddress;
                  latitude = result.latitude;
                  longitude = result.longitude;
                  name.text = result.displayName;
                  city.text =
                      result.locality ??
                      result.administrativeArea ??
                      result.displayName;
                  country.text = result.country ?? '';
                  predictions = [];
                  search.text = '';
                });
              } catch (_) {
                if (!dialogContext.mounted) return;
                setDialogState(() {
                  searchError = _t(
                    'Impossibile caricare questo luogo.',
                    'Unable to load this place.',
                  );
                });
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => selecting = false);
                }
              }
            }

            InputDecoration decoration(String label, IconData icon) {
              return InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: const OutlineInputBorder(),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF211914),
              elevation: 16,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 20,
              ),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFF68402B), width: 1.4),
                borderRadius: BorderRadius.circular(22),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              scrollable: false,
              title: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFFF2B45C),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      existing == null
                          ? _t('Nuova attività', 'New activity')
                          : _t('Modifica attività', 'Edit activity'),
                      style: const TextStyle(
                        color: Color(0xFFF5E9DA),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      (MediaQuery.sizeOf(dialogContext).height -
                              MediaQuery.viewInsetsOf(dialogContext).bottom -
                              180)
                          .clamp(160.0, 620.0),
                ),
                child: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t(
                            'Trova un luogo su Google Maps oppure inserisci '
                                'i dati manualmente.',
                            'Find a place on Google Maps or enter '
                                'details manually.',
                          ),
                          style: const TextStyle(color: Color(0xFFC4B2A3)),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.travel_explore_outlined,
                                color: const Color(0xFFF2B45C),
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                _t('Cerca un luogo', 'Find a place'),
                                style: const TextStyle(
                                  color: Color(0xFFF5E9DA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: search,
                                onSubmitted: (_) => findPlaces(),
                                decoration: decoration(
                                  _t('Cerca un luogo', 'Search places'),
                                  Icons.travel_explore_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: _t('Cerca', 'Search'),
                              onPressed: searching || selecting || saving
                                  ? null
                                  : findPlaces,
                              icon: searching
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.search),
                            ),
                          ],
                        ),
                        if (searchError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            searchError!,
                            style: const TextStyle(color: Color(0xFFFF9B80)),
                          ),
                        ],
                        if (predictions.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 235),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: predictions.length,
                              itemBuilder: (context, index) {
                                final prediction = predictions[index];
                                return ListTile(
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(prediction.primaryText),
                                  subtitle: Text(prediction.secondaryText),
                                  enabled: !selecting && !saving,
                                  onTap: () => selectPlace(prediction),
                                );
                              },
                            ),
                          ),
                        if (selecting) const LinearProgressIndicator(),
                        if (placeId != null) ...[
                          const SizedBox(height: 10),
                          BucketPlacePhoto(
                            key: ValueKey<String>(placeId!),
                            placeId: placeId,
                            height: 136,
                            languageCode: language,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFFF2B45C),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _t(
                                    'Luogo Google Maps collegato',
                                    'Google Maps place linked',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFF2B45C),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: _t('Rimuovi luogo', 'Remove place'),
                                onPressed: saving
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          placeId = null;
                                          address = null;
                                          latitude = null;
                                          longitude = null;
                                        });
                                      },
                                icon: const Icon(Icons.link_off),
                              ),
                            ],
                          ),
                          if (address != null && address!.isNotEmpty)
                            Text(address!),
                          if (placeId != null)
                            TextButton.icon(
                              onPressed: () async {
                                final url = Uri.https(
                                  'www.google.com',
                                  '/maps/search/',
                                  {
                                    'api': '1',
                                    'query': name.text.isNotEmpty
                                        ? name.text
                                        : 'Place',
                                    'query_place_id': placeId!,
                                  },
                                );
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.platformDefault,
                                );
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: Text(_t('Apri mappa', 'Open map')),
                            ),
                        ],
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_note_outlined,
                                color: const Color(0xFFF2B45C),
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                _t(
                                  'Dettagli dell’attività',
                                  'Activity details',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFF5E9DA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextField(
                          controller: name,
                          maxLength: 200,
                          decoration: decoration(
                            _t('Nome attività *', 'Activity name *'),
                            Icons.edit_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: city,
                          maxLength: 150,
                          decoration: decoration(
                            _t('Città / area *', 'City / area *'),
                            Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: country,
                          maxLength: 150,
                          decoration: decoration(
                            _t('Paese *', 'Country *'),
                            Icons.public_outlined,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<BucketItemType>(
                          initialValue: type,
                          isExpanded: true,
                          decoration: decoration(
                            _t('Categoria', 'Category'),
                            Icons.category_outlined,
                          ),
                          items: BucketItemType.values.map((value) {
                            return DropdownMenuItem(
                              value: value,
                              child: Text(_typeLabel(value)),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(() => type = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 14),
                        if (type == BucketItemType.other)
                          TextField(
                            controller: customCategory,
                            maxLength: 60,
                            decoration: decoration(
                              _t(
                                'Categoria personalizzata (facoltativa)',
                                'Custom category (optional)',
                              ),
                              Icons.label_outline,
                            ),
                          ),
                        if (type == BucketItemType.other &&
                            _categories.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final label in _categories.take(12))
                                ActionChip(
                                  label: Text(label),
                                  onPressed: () => setDialogState(
                                    () => customCategory.text = label,
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: duration,
                          keyboardType: TextInputType.number,
                          decoration: decoration(
                            _t(
                              'Durata in minuti (facoltativa)',
                              'Duration in minutes (optional)',
                            ),
                            Icons.schedule_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _t('Link utili', 'Useful links'),
                          style: const TextStyle(color: Color(0xFFF5E9DA)),
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < linkControllers.length; i++) ...[
                          Row(
                            key: ObjectKey(linkControllers[i]),
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: linkControllers[i],
                                  keyboardType: TextInputType.url,
                                  decoration: decoration(
                                    [
                                      _t('Link', 'Link'),
                                      (i + 1).toString(),
                                    ].join(' '),
                                    Icons.link_outlined,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: _t('Rimuovi link', 'Remove link'),
                                onPressed: saving
                                    ? null
                                    : () {
                                        setDialogState(() {
                                          final removed = linkControllers
                                              .removeAt(i);
                                          // Dispose after the dialog frame.
                                          WidgetsBinding.instance
                                              .addPostFrameCallback(
                                                (_) => removed.dispose(),
                                              );
                                          if (linkControllers.isEmpty) {
                                            linkControllers.add(
                                              TextEditingController(),
                                            );
                                          }
                                        });
                                      },
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: saving || linkControllers.length >= 20
                              ? null
                              : () => setDialogState(
                                  () => linkControllers.add(
                                    TextEditingController(),
                                  ),
                                ),
                          icon: const Icon(Icons.add_link),
                          label: Text(_t('Aggiungi un link', 'Add a link')),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notes_outlined,
                                color: const Color(0xFFF2B45C),
                                size: 19,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                _t(
                                  'Note personali e informazioni',
                                  'Notes and information',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFFF5E9DA),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextField(
                          controller: notes,
                          maxLines: 4,
                          maxLength: 10000,
                          decoration: decoration(
                            _t('Note', 'Notes'),
                            Icons.notes_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      if (existing != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: saving || selecting
                                ? null
                                : () async {
                                    final requested =
                                        await _confirmDeletionRequest(
                                          dialogContext,
                                          existing,
                                        );
                                    if (requested && dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFFF9B80),
                            ),
                            label: Text(
                              _t('Elimina', 'Delete'),
                              style: const TextStyle(color: Color(0xFFFF9B80)),
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: Text(_t('Annulla', 'Cancel')),
                        ),
                      ),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: saving || selecting
                              ? null
                              : () async {
                                  final durationText = duration.text.trim();
                                  final minutes = durationText.isEmpty
                                      ? null
                                      : int.tryParse(durationText);

                                  final usefulLinks = linkControllers
                                      .map(
                                        (controller) => controller.text.trim(),
                                      )
                                      .where((link) => link.isNotEmpty)
                                      .toList();

                                  final validLinks =
                                      usefulLinks.length <= 20 &&
                                      usefulLinks.every((link) {
                                        final url = Uri.tryParse(link);
                                        return link.length <= 2048 &&
                                            url != null &&
                                            (url.scheme == 'https' ||
                                                url.scheme == 'http') &&
                                            url.host.isNotEmpty;
                                      });

                                  if (name.text.trim().isEmpty ||
                                      city.text.trim().isEmpty ||
                                      country.text.trim().isEmpty ||
                                      (durationText.isNotEmpty &&
                                          (minutes == null ||
                                              minutes <= 0 ||
                                              minutes > 10080)) ||
                                      !validLinks) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _t(
                                            'Controlla campi obbligatori, durata '
                                                'e link (massimo 20 URL validi).',
                                            'Check required fields, duration '
                                                'and links (up to 20 valid URLs).',
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setDialogState(() => saving = true);
                                  try {
                                    await _saveActivity(
                                      existing: existing,
                                      name: name.text,
                                      city: city.text,
                                      country: country.text,
                                      type: type,
                                      duration: minutes,
                                      notes: notes.text,
                                      customCategory:
                                          type == BucketItemType.other
                                          ? customCategory.text
                                          : '',
                                      usefulLinks: usefulLinks,
                                      placeId: placeId,
                                      address: address,
                                      latitude: latitude,
                                      longitude: longitude,
                                    );
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    await _refresh();
                                  } catch (error) {
                                    if (dialogContext.mounted) {
                                      setDialogState(() => saving = false);
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            _t(
                                              error is StateError
                                                  ? error.message.toString()
                                                  : 'Impossibile salvare l’attività.',
                                              error is StateError
                                                  ? error.message.toString()
                                                  : 'Unable to save activity.',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.check),
                          label: Text(
                            saving
                                ? _t('Salvataggio...', 'Saving...')
                                : _t('Salva', 'Save'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      name.dispose();
      city.dispose();
      country.dispose();
      duration.dispose();
      notes.dispose();
      customCategory.dispose();
      for (final controller in linkControllers) {
        controller.dispose();
      }
      search.dispose();
    }
  }
}
