// Problema trovato controllando un elemento di una sezione: tipo (campo
// obbligatorio, testo lungo, link, costo…), campo interessato e limite.
// L'editor lo trasforma in un messaggio chiaro.

enum TripSectionProblemKind {
  required,
  tooLong,
  link,
  cost,
  members,
  expense,
  place,
  other,
}

class TripSectionProblem {
  const TripSectionProblem(this.kind, this.field, {this.max});

  final TripSectionProblemKind kind;

  /// Field code, e.g. 'name' or 'bookingUrl'.
  final String field;
  final int? max;

  @override
  bool operator ==(Object other) =>
      other is TripSectionProblem &&
      other.kind == kind &&
      other.field == field &&
      other.max == max;

  @override
  int get hashCode => Object.hash(kind, field, max);

  @override
  String toString() => '${kind.name}:$field';
}

/// Collects problems with short helpers.
class TripSectionChecks {
  final found = <TripSectionProblem>[];

  void check(bool bad, TripSectionProblemKind kind, String field, {int? max}) {
    if (bad) found.add(TripSectionProblem(kind, field, max: max));
  }

  void required(String? value, String field) => check(
    (value?.trim() ?? '').isEmpty,
    TripSectionProblemKind.required,
    field,
  );

  void maxLength(String? value, int max, String field) => check(
    (value?.length ?? 0) > max,
    TripSectionProblemKind.tooLong,
    field,
    max: max,
  );
}
