class TripArchiveNamingService {
  const TripArchiveNamingService();

  String buildTripFolderName({
    required String tripName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final safeTripName = _sanitise(tripName);
    final safeDestination = _sanitise(destination);

    return '${safeTripName}_${safeDestination}_'
        '${_formatDate(startDate)}_${_formatDate(endDate)}';
  }

  String buildImageFileName({
    required DateTime date,
    required String place,
    required int sequence,
    required String extension,
  }) {
    if (sequence < 1) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'Sequence must be greater than zero.',
      );
    }

    final safePlace = _sanitise(place);
    final safeExtension = _normaliseExtension(extension);

    return '${_formatDate(date)}_${safePlace}_'
        '${sequence.toString().padLeft(3, '0')}.$safeExtension';
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year$month$day';
  }

  String _sanitise(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Archive name component cannot be empty.',
      );
    }

    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normaliseExtension(String extension) {
    final normalised = extension.trim().replaceFirst(RegExp(r'^\.+'), '');

    if (normalised.isEmpty) {
      throw ArgumentError.value(
        extension,
        'extension',
        'File extension cannot be empty.',
      );
    }

    return normalised.toLowerCase();
  }
}
