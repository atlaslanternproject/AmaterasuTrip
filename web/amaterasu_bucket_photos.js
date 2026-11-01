
(() => {
  // Do not persist or cache Place Photo URLs.
  globalThis.amaterasuBucketPlacePhoto = async (placeId, languageCode) => {
    const id = String(placeId || '').trim();
    if (!id) return JSON.stringify(null);

    const { Place } = await google.maps.importLibrary('places');

    const place = new Place({
      id,
      requestedLanguage: String(languageCode || 'it'),
    });

    await place.fetchFields({ fields: ['photos'] });

    const photo = place.photos?.[0];
    if (!photo) return JSON.stringify(null);

    const url = photo.getURI({ maxWidth: 1000 });

    const authors = (photo.authorAttributions || [])
      .filter((author) => author.displayName)
      .map((author) => ({
        name: String(author.displayName),
        uri: author.uri ? String(author.uri) : null,
      }));

    return JSON.stringify({ url, authors });
  };
})();
