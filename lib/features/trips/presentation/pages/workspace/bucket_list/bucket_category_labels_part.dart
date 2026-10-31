part of 'trip_bucket_list_page.dart';

extension _BucketCategoryLabels on _TripBucketListPageState {
  String _typeLabel(BucketItemType value) {
    switch (value) {
      case BucketItemType.attraction:
        return _t('Attrazione', 'Attraction');
      case BucketItemType.area:
        return _t('Zona', 'Area');
      case BucketItemType.city:
        return _t('Città', 'City');
      case BucketItemType.experience:
        return _t('Esperienza', 'Experience');
      case BucketItemType.event:
        return _t('Evento', 'Event');
      case BucketItemType.other:
        return _t('Altro', 'Other');
    }
  }
}
