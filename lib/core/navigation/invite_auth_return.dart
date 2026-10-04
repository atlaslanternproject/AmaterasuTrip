class InviteAuthReturn {
  const InviteAuthReturn._();

  static String? normalize(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);

    if (uri == null || uri.scheme.isNotEmpty || uri.host.isNotEmpty) {
      return null;
    }

    final segments = uri.pathSegments;

    if (segments.length != 2 ||
        segments.first != 'trip-invite' ||
        segments[1].trim().isEmpty) {
      return null;
    }

    final token = uri.queryParameters['token'];

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return uri.toString();
  }

  static String route(String path, String? returnTo) {
    final normalized = normalize(returnTo);

    if (normalized == null) {
      return path;
    }

    return Uri(
      path: path,
      queryParameters: {'returnTo': normalized},
    ).toString();
  }

  static String destinationOrHome(String? returnTo) {
    return normalize(returnTo) ?? '/home';
  }
}
