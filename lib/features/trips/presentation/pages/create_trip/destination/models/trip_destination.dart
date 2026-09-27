class TripDestination {
  const TripDestination({
    required this.placeId,
    required this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.country,
    this.countryCode,
    this.administrativeArea,
    this.locality,
    this.suggestedCurrencyCode,
    this.suggestedCurrencyName,
    this.suggestedCurrencySymbol,
  });

  final String placeId;
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  final String? country;
  final String? countryCode;
  final String? administrativeArea;
  final String? locality;

  final String? suggestedCurrencyCode;
  final String? suggestedCurrencyName;
  final String? suggestedCurrencySymbol;

  String get flagEmoji {
    final code = countryCode?.trim().toUpperCase();

    if (code == null || code.length != 2) {
      return '';
    }

    const regionalIndicatorOffset = 0x1F1E6 - 0x41;

    return String.fromCharCodes(
      code.codeUnits.map((character) => character + regionalIndicatorOffset),
    );
  }

  String get displayNameWithFlag {
    final flag = flagEmoji;

    if (flag.isEmpty) {
      return displayName;
    }

    return '$flag $displayName';
  }

  String get label {
    final name = displayName.trim();
    final address = formattedAddress.trim();

    if (address.isEmpty || address == name) {
      return name;
    }

    if (address.toLowerCase().startsWith(name.toLowerCase())) {
      return address;
    }

    return '$name, $address';
  }

  String? get suggestedCurrencyLabel {
    final code = suggestedCurrencyCode?.trim();
    final name = suggestedCurrencyName?.trim();

    if (code == null || code.isEmpty) {
      return null;
    }

    if (name == null || name.isEmpty || name == code) {
      return code;
    }

    return '$code · $name';
  }

  factory TripDestination.fromMap(Map<Object?, Object?> map) {
    return TripDestination(
      placeId: map['placeId'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      formattedAddress: map['formattedAddress'] as String? ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      country: map['country'] as String?,
      countryCode: map['countryCode'] as String?,
      administrativeArea: map['administrativeArea'] as String?,
      locality: map['locality'] as String?,
      suggestedCurrencyCode: map['suggestedCurrencyCode'] as String?,
      suggestedCurrencyName: map['suggestedCurrencyName'] as String?,
      suggestedCurrencySymbol: map['suggestedCurrencySymbol'] as String?,
    );
  }
}

class DestinationPrediction {
  const DestinationPrediction({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;

  factory DestinationPrediction.fromMap(Map<Object?, Object?> map) {
    return DestinationPrediction(
      placeId: map['placeId'] as String? ?? '',
      primaryText: map['primaryText'] as String? ?? '',
      secondaryText: map['secondaryText'] as String? ?? '',
      fullText: map['fullText'] as String? ?? '',
    );
  }
}
