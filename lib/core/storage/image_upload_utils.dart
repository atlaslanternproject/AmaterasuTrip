String normalizedImageExtension(String fileNameOrPath) {
  final value = fileNameOrPath.trim();

  if (value.isEmpty) {
    return 'jpg';
  }

  final lastDot = value.lastIndexOf('.');

  if (lastDot == -1 || lastDot == value.length - 1) {
    return 'jpg';
  }

  final extension = value.substring(lastDot + 1).toLowerCase();

  return switch (extension) {
    'jpg' => 'jpg',
    'jpeg' => 'jpeg',
    'png' => 'png',
    'webp' => 'webp',
    'heic' => 'heic',
    'heif' => 'heif',
    _ => 'jpg',
  };
}

String imageContentTypeForExtension(String extension) {
  return switch (extension.trim().toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'jpg' || 'jpeg' => 'image/jpeg',
    _ => 'image/jpeg',
  };
}
