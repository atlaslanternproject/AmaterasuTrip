// Modulo Luogo condiviso (alloggi e altre sezioni): contatti (telefono,
// sito) e fino a 5 foto di un luogo Google. Separato dal ponte della bucket list. Le risposte restano solo in
// memoria (nessun salvataggio): la cache vera è lato Dart, per sessione.
(() => {
  const placeFor = async (placeId, languageCode) => {
    const id = String(placeId || '').trim();
    if (!id) return null;
    const { Place } = await google.maps.importLibrary('places');
    return new Place({ id, requestedLanguage: String(languageCode || 'it') });
  };

  // Contact fields are billed as "Place Details Enterprise": one request
  // only when a place is chosen in the editor.
  globalThis.amaterasuPlaceInfoContacts = async (placeId, languageCode) => {
    const place = await placeFor(placeId, languageCode);
    if (!place) return JSON.stringify(null);
    await place.fetchFields({
      fields: ['internationalPhoneNumber', 'nationalPhoneNumber', 'websiteURI'],
    });
    return JSON.stringify({
      phone: place.internationalPhoneNumber || place.nationalPhoneNumber || null,
      website: place.websiteURI || null,
    });
  };

  // Do not persist Place Photo URLs: they are used only while the app runs.
  globalThis.amaterasuPlaceInfoPhotos = async (placeId, languageCode, max) => {
    const place = await placeFor(placeId, languageCode);
    if (!place) return JSON.stringify([]);
    await place.fetchFields({ fields: ['photos'] });
    const limit = Math.max(0, Math.min(Number(max) || 5, 5));
    const photos = (place.photos || []).slice(0, limit).map((photo) => ({
      url: photo.getURI({ maxWidth: 1000 }),
      authors: (photo.authorAttributions || [])
        .filter((author) => author.displayName)
        .map((author) => ({
          name: String(author.displayName),
          uri: author.uri ? String(author.uri) : null,
        })),
    }));
    return JSON.stringify(photos);
  };
})();
