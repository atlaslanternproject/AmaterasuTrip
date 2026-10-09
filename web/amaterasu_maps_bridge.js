(() => {
  let autocompleteSessionToken = null;
  const predictionsByPlaceId = new Map();

  const normalizeLanguage = (languageCode) => {
    const value = String(languageCode || 'en').trim();

    if (!value) {
      return 'en';
    }

    return value.replace('_', '-');
  };

  const componentValue = (components, type, shortValue = false) => {
    const component = (components || []).find(
      (item) => Array.isArray(item.types) && item.types.includes(type),
    );

    if (!component) {
      return null;
    }

    if (shortValue) {
      return (
        component.shortText ??
        component.short_name ??
        null
      );
    }

    return (
      component.longText ??
      component.long_name ??
      null
    );
  };

  const destinationFromComponents = ({
    placeId,
    displayName,
    formattedAddress,
    latitude,
    longitude,
    components,
  }) => {
    const country = componentValue(components, 'country');

    const countryCode = componentValue(
      components,
      'country',
      true,
    );

    const administrativeArea = componentValue(
      components,
      'administrative_area_level_1',
    );

    const locality =
      componentValue(components, 'locality') ??
      componentValue(components, 'postal_town') ??
      componentValue(components, 'sublocality') ??
      componentValue(components, 'administrative_area_level_2');

    const resolvedDisplayName =
      displayName ||
      locality ||
      administrativeArea ||
      country ||
      formattedAddress ||
      `${Number(latitude).toFixed(5)}, ${Number(longitude).toFixed(5)}`;

    return {
      placeId: placeId || `geo:${latitude},${longitude}`,
      displayName: resolvedDisplayName,
      formattedAddress:
        formattedAddress ||
        [locality, administrativeArea, country]
          .filter(Boolean)
          .filter((value, index, values) => values.indexOf(value) === index)
          .join(', '),
      latitude: Number(latitude),
      longitude: Number(longitude),
      country: country || null,
      countryCode: countryCode
        ? String(countryCode).toUpperCase()
        : null,
      administrativeArea: administrativeArea || null,
      locality: locality || null,

      // Currency selection remains available through getCurrencies().
      // Country -> currency suggestion will be added separately if needed.
      suggestedCurrencyCode: null,
      suggestedCurrencyName: null,
      suggestedCurrencySymbol: null,
    };
  };

  globalThis.amaterasuPlacesSearch = async (
    query,
    languageCode,
  ) => {
    const normalizedQuery = String(query || '').trim();

    if (normalizedQuery.length < 2) {
      return JSON.stringify([]);
    }

    const {
      AutocompleteSessionToken,
      AutocompleteSuggestion,
    } = await google.maps.importLibrary('places');

    if (!autocompleteSessionToken) {
      autocompleteSessionToken = new AutocompleteSessionToken();
    }

    const { suggestions } =
      await AutocompleteSuggestion.fetchAutocompleteSuggestions({
        input: normalizedQuery,
language: normalizeLanguage(languageCode),
        sessionToken: autocompleteSessionToken,
      });

    const predictions = [];

    for (const suggestion of suggestions || []) {
      const prediction = suggestion.placePrediction;

      if (!prediction) {
        continue;
      }

      predictionsByPlaceId.set(
        prediction.placeId,
        prediction,
      );

      predictions.push({
        placeId: prediction.placeId,
        primaryText:
          prediction.mainText?.toString() ??
          prediction.text?.toString() ??
          '',
        secondaryText:
          prediction.secondaryText?.toString() ??
          '',
        fullText:
          prediction.text?.toString() ??
          '',
      });
    }

    return JSON.stringify(predictions);
  };

  globalThis.amaterasuPlaceDetails = async (
    placeId,
    languageCode,
  ) => {
    const normalizedPlaceId = String(placeId || '').trim();

    if (!normalizedPlaceId) {
      throw new Error('Missing place ID.');
    }

    const { Place } = await google.maps.importLibrary('places');

    const prediction = predictionsByPlaceId.get(
      normalizedPlaceId,
    );

    const place = prediction
      ? prediction.toPlace()
      : new Place({
          id: normalizedPlaceId,
          requestedLanguage: normalizeLanguage(languageCode),
        });

    await place.fetchFields({
      fields: [
        'id',
        'displayName',
        'formattedAddress',
        'location',
        'addressComponents',
      ],
    });

    if (!place.location) {
      throw new Error('Place has no location.');
    }

    const destination = destinationFromComponents({
      placeId: place.id || normalizedPlaceId,
      displayName: place.displayName || '',
      formattedAddress: place.formattedAddress || '',
      latitude: place.location.lat(),
      longitude: place.location.lng(),
      components: place.addressComponents || [],
    });

    autocompleteSessionToken = null;
    predictionsByPlaceId.clear();

    return JSON.stringify(destination);
  };

  globalThis.amaterasuReverseGeocode = async (
    latitude,
    longitude,
    languageCode,
  ) => {
    const lat = Number(latitude);
    const lng = Number(longitude);

    if (!Number.isFinite(lat) || !Number.isFinite(lng)) {
      throw new Error('Invalid map coordinates.');
    }

    const { Geocoder } =
      await google.maps.importLibrary('geocoding');

    const geocoder = new Geocoder();

    const response = await geocoder.geocode({
      location: {
        lat,
        lng,
      },
      language: normalizeLanguage(languageCode),
    });

    const result = response.results?.[0];

    if (!result) {
      throw new Error('No destination at selected point.');
    }

    const destination = destinationFromComponents({
      placeId: result.place_id || `geo:${lat},${lng}`,
      displayName: '',
      formattedAddress: result.formatted_address || '',
      latitude: lat,
      longitude: lng,
      components: result.address_components || [],
    });

    return JSON.stringify(destination);
  };

  globalThis.amaterasuGetCurrencies = async (
    languageCode,
  ) => {
    const language = normalizeLanguage(languageCode);

    const fallbackCodes = [
      'AUD',
      'BRL',
      'CAD',
      'CHF',
      'CNY',
      'CZK',
      'DKK',
      'EUR',
      'GBP',
      'HKD',
      'HUF',
      'IDR',
      'INR',
      'JPY',
      'KRW',
      'MXN',
      'MYR',
      'NOK',
      'NZD',
      'PHP',
      'PLN',
      'RON',
      'SEK',
      'SGD',
      'THB',
      'TRY',
      'TWD',
      'USD',
      'VND',
      'ZAR',
    ];

    const codes =
      typeof Intl.supportedValuesOf === 'function'
        ? Intl.supportedValuesOf('currency')
        : fallbackCodes;

    const displayNames =
      typeof Intl.DisplayNames === 'function'
        ? new Intl.DisplayNames(
            [language],
            {
              type: 'currency',
              fallback: 'code',
            },
          )
        : null;

    const currencies = codes.map((code) => {
      let symbol = code;

      try {
        const parts = new Intl.NumberFormat(
          language,
          {
            style: 'currency',
            currency: code,
            currencyDisplay: 'narrowSymbol',
          },
        ).formatToParts(0);

        const currencyPart = parts.find(
          (part) => part.type === 'currency',
        );

        if (currencyPart?.value) {
          symbol = currencyPart.value;
        }
      } catch (_) {
        symbol = code;
      }

      return {
        code,
        name: displayNames?.of(code) || code,
        symbol,
      };
    });

    currencies.sort((a, b) =>
      a.code.localeCompare(b.code),
    );

    return JSON.stringify(currencies);
  };
})();


