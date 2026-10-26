enum BucketPriority {
  ss(10),
  s(7),
  a(4),
  b(1);

  const BucketPriority(this.points);

  final int points;

  static BucketPriority fromCode(String code) {
    return BucketPriority.values.firstWhere(
      (priority) => priority.name.toUpperCase() == code.toUpperCase(),
      orElse: () =>
          throw ArgumentError.value(code, 'code', 'Unknown bucket priority'),
    );
  }
}
