// Testi e colori comuni delle sezioni: stato di prenotazione (nome, colore
// ed etichetta), costo previsto formattato e messaggi dei problemi trovati
// dai controlli.

import 'package:flutter/material.dart';

import 'package:amaterasutrip/core/links/amaterasu_web_link.dart';

import 'package:amaterasutrip/core/theme/amaterasu_colors.dart';
import 'package:amaterasutrip/features/trips/budget/calculations/budget_money_formatter.dart';
import 'package:amaterasutrip/l10n/app_localizations.dart';
import '../models/trip_booking_status.dart';
import '../models/trip_section_problem.dart';
import 'trip_section_chip.dart';

abstract final class TripSectionLabels {
  static String status(TripBookingStatus status, AppLocalizations l10n) =>
      switch (status) {
        TripBookingStatus.toBook => l10n.sectionsStatusToBook,
        TripBookingStatus.booked => l10n.sectionsStatusBooked,
        TripBookingStatus.cancelled => l10n.sectionsStatusCancelled,
      };

  /// Booked = green, to book = gold, cancelled = muted.
  static Color statusColor(TripBookingStatus status) => switch (status) {
    TripBookingStatus.booked => AmaterasuColors.success,
    TripBookingStatus.toBook => AmaterasuColors.accentGold,
    TripBookingStatus.cancelled => AmaterasuColors.textMuted,
  };

  static Widget statusChip(TripBookingStatus status, AppLocalizations l10n) =>
      TripSectionChip(
        label: TripSectionLabels.status(status, l10n),
        color: statusColor(status),
      );

  /// "Costo previsto: € 45,00", or null without a cost.
  /// Amount in its currency, e.g. "€ 12,50"; null without an amount.
  static String? money(int? minor, String? currency) =>
      minor == null || currency == null
      ? null
      : BudgetMoneyFormatter.format(minor, currency);

  static String? cost(int? minor, String? currency, AppLocalizations l10n) =>
      minor == null || currency == null
      ? null
      : l10n.sectionsCostEstimated(
          BudgetMoneyFormatter.format(minor, currency),
        );

  /// "Useful links" as (site name, link) for the card chips.
  static List<(String, String)> usefulLinks(
    List<String> links,
    AppLocalizations l10n,
  ) => [
    for (final link in links)
      (AmaterasuWebLink.label(link, l10n.commonLinkOpen), link),
  ];

  /// Message for [problem]; [fieldLabel] names the field, [other] gives
  /// the text of section-specific problems.
  static String problem(
    TripSectionProblem problem,
    AppLocalizations l10n, {
    required String Function(String field) fieldLabel,
    String Function(TripSectionProblem problem)? other,
  }) => switch (problem.kind) {
    TripSectionProblemKind.required => l10n.sectionsErrRequired(
      fieldLabel(problem.field),
    ),
    TripSectionProblemKind.tooLong => l10n.sectionsErrTooLong(problem.max ?? 0),
    TripSectionProblemKind.link => l10n.sectionsErrLink,
    TripSectionProblemKind.cost => l10n.sectionsErrCost,
    TripSectionProblemKind.members => l10n.sectionsErrMembers,
    TripSectionProblemKind.expense => l10n.sectionsErrExpense,
    TripSectionProblemKind.place => l10n.sectionsErrPlace,
    TripSectionProblemKind.other =>
      other?.call(problem) ?? l10n.sectionsSaveError,
  };
}
