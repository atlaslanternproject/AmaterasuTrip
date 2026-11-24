// Blocco di un editor delle sezioni: sezione a tendina condivisa
// (AmaterasuFoldSection) con icona, titolo, riepilogo da chiusa e freccia.
// Si apre da solo quando contiene un errore ([forceOpen]).

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/widgets/inputs/amaterasu_fold_section.dart';

class TripSectionBlock extends StatelessWidget {
  const TripSectionBlock({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.summary,
    this.initiallyOpen = true,
    this.forceOpen = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? summary;
  final bool initiallyOpen;
  final bool forceOpen;

  @override
  Widget build(BuildContext context) => AmaterasuFoldSection(
    title: title,
    icon: icon,
    summary: summary,
    initiallyOpen: initiallyOpen,
    forceOpen: forceOpen,
    children: children,
  );
}
