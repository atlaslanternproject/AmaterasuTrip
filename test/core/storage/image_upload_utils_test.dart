import 'package:amaterasutrip/core/storage/image_upload_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizedImageExtension', () {
    test('normalizes supported extensions', () {
      expect(normalizedImageExtension('photo.JPG'), 'jpg');
      expect(normalizedImageExtension('photo.JPEG'), 'jpeg');
      expect(normalizedImageExtension('photo.PNG'), 'png');
      expect(normalizedImageExtension('photo.WEBP'), 'webp');
      expect(normalizedImageExtension('photo.HEIC'), 'heic');
      expect(normalizedImageExtension('photo.HEIF'), 'heif');
    });

    test('falls back to jpg without extension', () {
      expect(normalizedImageExtension('photo'), 'jpg');
    });

    test('falls back to jpg for unsupported extension', () {
      expect(normalizedImageExtension('photo.txt'), 'jpg');
    });

    test('falls back to jpg for an empty value', () {
      expect(normalizedImageExtension(''), 'jpg');
    });
  });

  group('imageContentTypeForExtension', () {
    test('maps supported image extensions', () {
      expect(imageContentTypeForExtension('jpg'), 'image/jpeg');
      expect(imageContentTypeForExtension('jpeg'), 'image/jpeg');
      expect(imageContentTypeForExtension('png'), 'image/png');
      expect(imageContentTypeForExtension('webp'), 'image/webp');
      expect(imageContentTypeForExtension('heic'), 'image/heic');
      expect(imageContentTypeForExtension('heif'), 'image/heif');
    });

    test('falls back to image/jpeg', () {
      expect(imageContentTypeForExtension('unknown'), 'image/jpeg');
    });
  });
}
