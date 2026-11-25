// Blocco "Link utili" degli editor delle sezioni: il campo comune
// AmaterasuLinksField dentro la sezione a tendina delle sezioni, chiusa
// quando non ci sono link.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_links_field.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_section_block.dart';

class TripSectionLinksBlock extends StatelessWidget {
  const TripSectionLinksBlock({
    super.key,
    required this.keyPrefix,
    required this.draft,
    required this.onChanged,
  });

  final String keyPrefix;
  final AmaterasuLinksDraft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TripSectionBlock(
    title: AppLocalizations.of(context)!.commonUsefulLinks,
    icon: Icons.link_rounded,
    initiallyOpen: draft.links.isNotEmpty,
    children: [
      AmaterasuLinksField(
        keyPrefix: keyPrefix,
        draft: draft,
        onChanged: onChanged,
      ),
    ],
  );
}
