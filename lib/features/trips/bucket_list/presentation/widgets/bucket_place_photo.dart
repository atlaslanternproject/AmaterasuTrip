import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bucket_place_photo_loader.dart' as loader;

class BucketPhotoAuthor {
  const BucketPhotoAuthor({required this.name, this.uri});
  final String name;
  final Uri? uri;
}

class BucketPlacePhotoData {
  const BucketPlacePhotoData({required this.url, required this.authors});

  final String url;
  final List<BucketPhotoAuthor> authors;
}

/// Place photos are retrieved when this widget is mounted.
/// URLs are never written to Firestore.
class BucketPlacePhoto extends StatefulWidget {
  const BucketPlacePhoto({
    super.key,
    required this.placeId,
    required this.height,
    required this.languageCode,
  });

  final String? placeId;
  final double height;
  final String languageCode;

  @override
  State<BucketPlacePhoto> createState() => _BucketPlacePhotoState();
}

class _BucketPlacePhotoState extends State<BucketPlacePhoto> {
  Future<BucketPlacePhotoData?>? _photo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BucketPlacePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placeId != widget.placeId ||
        oldWidget.languageCode != widget.languageCode) {
      _load();
    }
  }

  void _load() {
    final id = widget.placeId?.trim();

    _photo = (id == null || id.isEmpty)
        ? Future.value(null)
        : loader.loadBucketPlacePhoto(id, languageCode: widget.languageCode);
  }

  Widget _fallback() {
    return ColoredBox(
      color: const Color(0xFF38271E),
      child: SizedBox(
        height: widget.height,
        child: const Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 56,
            color: Color(0xFF8A6250),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: FutureBuilder<BucketPlacePhotoData?>(
          future: _photo,
          builder: (context, snapshot) {
            final photo = snapshot.data;

            if (snapshot.connectionState != ConnectionState.done) {
              return _fallback();
            }

            if (snapshot.hasError || photo == null) {
              return _fallback();
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  photo.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(),
                ),
                if (photo.authors.isNotEmpty)
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 4,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xE81F1714),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final author in photo.authors)
                              InkWell(
                                onTap: author.uri == null
                                    ? null
                                    : () => launchUrl(
                                        author.uri!,
                                        mode: LaunchMode.platformDefault,
                                      ),
                                child: Text(
                                  author.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFF5E9DA),
                                    fontSize: 10,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
