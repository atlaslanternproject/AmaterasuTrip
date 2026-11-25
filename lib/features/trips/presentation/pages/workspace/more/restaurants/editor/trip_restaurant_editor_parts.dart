// Parte di trip_restaurant_editor.dart: campo di testo dell'editor e
// blocco stato (con voto e nota quando è "provato"), cucina e prezzo.

// ignore_for_file: invalid_use_of_protected_member
part of 'trip_restaurant_editor.dart';

extension _TripRestaurantEditorParts on _TripRestaurantEditorState {
  Widget _text(
    String key,
    TextEditingController c,
    String label, {
    int max = 120,
    TextInputType? type,
    int lines = 1,
  }) => TextField(
    key: Key('restaurant-$key'),
    controller: c,
    maxLength: max,
    keyboardType: type,
    minLines: lines,
    maxLines: lines == 1 ? 1 : lines + 3,
    decoration: InputDecoration(labelText: label),
  );

  Widget _kindBlock(AppLocalizations l10n, TripRestaurantDraft d) =>
      TripSectionBlock(
        title: l10n.restaurantBlockKind,
        icon: Icons.ramen_dining_outlined,
        children: [
          TripSectionChoices<TripRestaurantStatus>(
            keyPrefix: 'restaurant-status',
            values: TripRestaurantStatus.values,
            codeOf: (s) => s.code,
            labelOf: (s) => TripRestaurantLabels.status(s, l10n),
            selected: d.status,
            onChanged: (s) => setState(() => d.status = s ?? d.status),
          ),
          if (d.status == TripRestaurantStatus.tried) ...[
            const SizedBox(height: 12),
            Text(l10n.restaurantTriedRating),
            const SizedBox(height: 6),
            TripSectionChoices<int>(
              keyPrefix: 'restaurant-rating',
              values: const [1, 2, 3, 4, 5],
              codeOf: (r) => '$r',
              labelOf: tripSectionStars,
              selected: d.triedRating,
              allowNone: true,
              onChanged: (r) => setState(() => d.triedRating = r),
            ),
            const SizedBox(height: 8),
            _text(
              'tried-note',
              d.triedNote,
              l10n.restaurantTriedNote,
              max: TripRestaurantCodec.triedNoteMax,
              lines: 2,
            ),
          ],
          const SizedBox(height: 8),
          _text('cuisine', d.cuisine, l10n.restaurantCuisine),
          TripSectionChoices<int>(
            keyPrefix: 'restaurant-price',
            values: const [1, 2, 3, 4],
            codeOf: (p) => '$p',
            labelOf: TripRestaurantLabels.price,
            selected: d.priceLevel,
            allowNone: true,
            onChanged: (p) => setState(() => d.priceLevel = p),
          ),
        ],
      );
}
