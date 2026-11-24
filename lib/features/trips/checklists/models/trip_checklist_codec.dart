// Conversione delle checklist da e verso Firestore (trips/{tripId}/checklists)
// e controlli con i limiti di firestore.rules: al massimo 30 categorie e
// 300 voci, testi brevi, quantità da 1 a 999.

import 'package:amaterasutrip/features/trips/sections/models/trip_section_fields.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_item.dart';
import 'package:amaterasutrip/features/trips/sections/models/trip_section_problem.dart';
import 'trip_checklist.dart';

class TripChecklistCodec implements TripSectionCodec<TripChecklist> {
  const TripChecklistCodec();

  static const categoriesMax = 30;
  static const entriesMax = 300;
  static const textMax = 200;
  static const categoryMax = 60;
  static const quantityMax = 999;
  static final idPattern = RegExp(r'^[A-Za-z0-9_-]{1,40}$');

  @override
  String get collection => 'checklists';

  @override
  List<String> get optionalKeys => const ['template', 'categories', 'items'];

  static Map<String, dynamic> entryMap(TripChecklistEntry e) => {
    'text': e.text.trim(),
    'category': e.category.trim(),
    'done': e.done,
    'order': e.order,
    'quantity': ?e.quantity,
    'assigneeUid': ?TripSectionFields.clean(e.assigneeUid),
  };

  @override
  Map<String, dynamic> toMap(TripChecklist item) => {
    'tripId': item.tripId,
    'createdByUid': item.createdByUid,
    'title': item.title.trim(),
    'visibility': item.isPrivate ? 'private' : 'shared',
    'template': ?TripSectionFields.clean(item.template),
    if (item.categories.isNotEmpty) 'categories': List.of(item.categories),
    if (item.entries.isNotEmpty)
      'items': {for (final e in item.entries.values) e.id: entryMap(e)},
  };

  @override
  TripChecklist fromMap(String id, Map<String, dynamic> data) {
    String? text(String key) => TripSectionFields.readText(data, key);
    final title = text('title');
    final visibility = data['visibility'];
    final tripId = text('tripId');
    final author = text('createdByUid');
    if (title == null ||
        (visibility != 'shared' && visibility != 'private') ||
        tripId == null ||
        author == null) {
      throw FormatException('Invalid checklist $id.');
    }
    final raw = data['items'];
    final entries = <String, TripChecklistEntry>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! Map) continue;
        final textValue = value['text'];
        if (textValue is! String || textValue.trim().isEmpty) continue;
        final key = entry.key as String;
        entries[key] = TripChecklistEntry(
          id: key,
          text: textValue,
          category: value['category'] is String
              ? value['category'] as String
              : '',
          quantity: value['quantity'] is int ? value['quantity'] as int : null,
          assigneeUid: value['assigneeUid'] is String
              ? value['assigneeUid'] as String
              : null,
          done: value['done'] == true,
          order: value['order'] is int ? value['order'] as int : 0,
        );
      }
    }
    final categories = data['categories'];
    return TripChecklist(
      id: id,
      tripId: tripId,
      createdByUid: author,
      title: title,
      isPrivate: visibility == 'private',
      template: text('template'),
      categories: categories is List
          ? categories.whereType<String>().toList()
          : const [],
      entries: entries,
    );
  }

  /// Problems of one entry (also used before saving a single entry).
  static List<TripSectionProblem> entryProblems(TripChecklistEntry e) {
    final quantity = e.quantity;
    final c = TripSectionChecks()
      ..required(e.text, 'text')
      ..maxLength(e.text.trim(), textMax, 'text')
      ..maxLength(e.category.trim(), categoryMax, 'category');
    c
      ..check(!idPattern.hasMatch(e.id), TripSectionProblemKind.other, 'id')
      ..check(
        quantity != null && (quantity < 1 || quantity > quantityMax),
        TripSectionProblemKind.other,
        'quantity',
      );
    return c.found;
  }

  @override
  List<TripSectionProblem> problems(TripChecklist item) {
    final c = TripSectionChecks()
      ..required(item.title, 'title')
      ..maxLength(item.title.trim(), TripSectionFields.nameMax, 'title');
    c
      ..check(
        item.categories.length > categoriesMax,
        TripSectionProblemKind.other,
        'categories',
      )
      ..check(
        item.entries.length > entriesMax,
        TripSectionProblemKind.other,
        'entries',
      );
    for (final e in item.entries.values) {
      c.found.addAll(entryProblems(e));
    }
    return c.found;
  }
}
