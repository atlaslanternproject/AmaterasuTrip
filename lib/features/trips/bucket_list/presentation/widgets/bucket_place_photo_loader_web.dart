import 'dart:convert';
import 'dart:js_interop';

import 'bucket_place_photo.dart';

@JS('amaterasuBucketPlacePhoto')
external JSPromise<JSString> _fetchPhoto(
  JSString placeId,
  JSString languageCode,
);

Future<BucketPlacePhotoData?> loadBucketPlacePhoto(
  String placeId, {
  required String languageCode,
}) async {
  final result = await _fetchPhoto(placeId.toJS, languageCode.toJS).toDart;

  final decoded = jsonDecode(result.toDart);

  if (decoded == null) return null;
  if (decoded is! Map) {
    throw const FormatException('Invalid Place photo response');
  }

  final url = decoded['url'];
  if (url is! String || !url.startsWith('https://')) return null;

  final authors = <BucketPhotoAuthor>[];
  final raw = decoded['authors'];

  if (raw is List) {
    for (final author in raw) {
      if (author is! Map) continue;
      final name = author['name'];
      final uri = author['uri'];
      if (name is String && name.trim().isNotEmpty) {
        authors.add(
          BucketPhotoAuthor(
            name: name,
            uri: uri is String ? Uri.tryParse(uri) : null,
          ),
        );
      }
    }
  }

  return BucketPlacePhotoData(url: url, authors: authors);
}
