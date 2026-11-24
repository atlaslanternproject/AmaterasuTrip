// Modelli pronti delle checklist: Valigia, Documenti, Prima di partire,
// Prima di uscire di casa, Farmaci e igiene, Elettronica, Vuota. I testi
// stanno in lib/l10n (voci separate da "|"); qui si costruisce la lista.

import 'package:amaterasutrip/l10n/app_localizations.dart';
import 'trip_checklist.dart';

class TripChecklistTemplate {
  const TripChecklistTemplate(this.code, this.title, this.groups);

  final String code;
  final String title;

  /// (category, items) in order.
  final List<(String, List<String>)> groups;

  /// A new list from this template; entry ids are short and readable.
  TripChecklist build({
    required String tripId,
    required String authorUid,
    required String title,
    required bool isPrivate,
  }) {
    final entries = <String, TripChecklistEntry>{};
    for (final (category, items) in groups) {
      for (final (index, text) in items.indexed) {
        final id = 'e${entries.length + 1}';
        entries[id] = TripChecklistEntry(
          id: id,
          text: text,
          category: category,
          order: index,
        );
      }
    }
    return TripChecklist(
      tripId: tripId,
      createdByUid: authorUid,
      title: title,
      isPrivate: isPrivate,
      template: code,
      categories: [for (final (category, _) in groups) category],
      entries: entries,
    );
  }
}

abstract final class TripChecklistTemplates {
  static List<String> _split(String items) => [
    for (final item in items.split('|'))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  static List<TripChecklistTemplate> all(AppLocalizations l10n) => [
    TripChecklistTemplate('packing', l10n.checklistTplPacking, [
      (l10n.checklistCatClothes, _split(l10n.checklistItemsClothes)),
      (l10n.checklistCatBathroom, _split(l10n.checklistItemsBathroom)),
      (l10n.checklistCatAccessories, _split(l10n.checklistItemsAccessories)),
    ]),
    TripChecklistTemplate('documents', l10n.checklistTplDocuments, [
      (l10n.checklistCatDocuments, _split(l10n.checklistItemsDocuments)),
    ]),
    TripChecklistTemplate('beforeTrip', l10n.checklistTplBeforeTrip, [
      (l10n.checklistCatTodo, _split(l10n.checklistItemsBeforeTrip)),
    ]),
    TripChecklistTemplate('leavingHome', l10n.checklistTplLeavingHome, [
      (l10n.checklistCatHome, _split(l10n.checklistItemsLeavingHome)),
    ]),
    TripChecklistTemplate('health', l10n.checklistTplHealth, [
      (l10n.checklistCatMedicines, _split(l10n.checklistItemsMedicines)),
      (l10n.checklistCatHygiene, _split(l10n.checklistItemsHygiene)),
    ]),
    TripChecklistTemplate('electronics', l10n.checklistTplElectronics, [
      (l10n.checklistCatElectronics, _split(l10n.checklistItemsElectronics)),
    ]),
    TripChecklistTemplate('empty', l10n.checklistTplEmpty, const []),
  ];
}
