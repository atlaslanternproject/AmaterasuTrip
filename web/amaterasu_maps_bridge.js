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

  // Country/currency mapping generated from Unicode CLDR.
  // Source: https://github.com/unicode-org/cldr-json
  // License: https://www.unicode.org/license.txt
  const currencyByCountry = Object.freeze({"AC":"SHP","AD":"EUR","AE":"AED","AF":"AFN","AG":"XCD","AI":"XCD","AL":"ALL","AM":"AMD","AO":"AOA","AR":"ARS","AS":"USD","AT":"EUR","AU":"AUD","AW":"AWG","AX":"EUR","AZ":"AZN","BA":"BAM","BB":"BBD","BD":"BDT","BE":"EUR","BF":"XOF","BG":"EUR","BH":"BHD","BI":"BIF","BJ":"XOF","BL":"EUR","BM":"BMD","BN":"BND","BO":"BOB","BQ":"USD","BR":"BRL","BS":"BSD","BT":"BTN","BV":"NOK","BW":"BWP","BY":"BYN","BZ":"BZD","CA":"CAD","CC":"AUD","CD":"CDF","CF":"XAF","CG":"XAF","CH":"CHF","CI":"XOF","CK":"NZD","CL":"CLP","CM":"XAF","CN":"CNY","CO":"COP","CR":"CRC","CU":"CUP","CV":"CVE","CW":"XCG","CX":"AUD","CY":"EUR","CZ":"CZK","DE":"EUR","DG":"USD","DJ":"DJF","DK":"DKK","DM":"XCD","DO":"DOP","DZ":"DZD","EA":"EUR","EC":"USD","EE":"EUR","EG":"EGP","EH":"MAD","ER":"ERN","ES":"EUR","ET":"ETB","EU":"EUR","FI":"EUR","FJ":"FJD","FK":"FKP","FM":"USD","FO":"DKK","FR":"EUR","GA":"XAF","GB":"GBP","GD":"XCD","GE":"GEL","GF":"EUR","GG":"GBP","GH":"GHS","GI":"GIP","GL":"DKK","GM":"GMD","GN":"GNF","GP":"EUR","GQ":"XAF","GR":"EUR","GS":"GBP","GT":"GTQ","GU":"USD","GW":"XOF","GY":"GYD","HK":"HKD","HM":"AUD","HN":"HNL","HR":"EUR","HT":"USD","HU":"HUF","IC":"EUR","ID":"IDR","IE":"EUR","IL":"ILS","IM":"GBP","IN":"INR","IO":"USD","IQ":"IQD","IR":"IRR","IS":"ISK","IT":"EUR","JE":"GBP","JM":"JMD","JO":"JOD","JP":"JPY","KE":"KES","KG":"KGS","KH":"KHR","KI":"AUD","KM":"KMF","KN":"XCD","KP":"KPW","KR":"KRW","KW":"KWD","KY":"KYD","KZ":"KZT","LA":"LAK","LB":"LBP","LC":"XCD","LI":"CHF","LK":"LKR","LR":"LRD","LS":"LSL","LT":"EUR","LU":"EUR","LV":"EUR","LY":"LYD","MA":"MAD","MC":"EUR","MD":"MDL","ME":"EUR","MF":"EUR","MG":"MGA","MH":"USD","MK":"MKD","ML":"XOF","MM":"MMK","MN":"MNT","MO":"MOP","MP":"USD","MQ":"EUR","MR":"MRU","MS":"XCD","MT":"EUR","MU":"MUR","MV":"MVR","MW":"MWK","MX":"MXN","MY":"MYR","MZ":"MZN","NA":"NAD","NC":"XPF","NE":"XOF","NF":"AUD","NG":"NGN","NI":"NIO","NL":"EUR","NO":"NOK","NP":"NPR","NR":"AUD","NU":"NZD","NZ":"NZD","OM":"OMR","PA":"USD","PE":"PEN","PF":"XPF","PG":"PGK","PH":"PHP","PK":"PKR","PL":"PLN","PM":"EUR","PN":"NZD","PR":"USD","PS":"JOD","PT":"EUR","PW":"USD","PY":"PYG","QA":"QAR","RE":"EUR","RO":"RON","RS":"RSD","RU":"RUB","RW":"RWF","SA":"SAR","SB":"SBD","SC":"SCR","SD":"SDG","SE":"SEK","SG":"SGD","SH":"SHP","SI":"EUR","SJ":"NOK","SK":"EUR","SL":"SLE","SM":"EUR","SN":"XOF","SO":"SOS","SR":"SRD","SS":"SSP","ST":"STN","SV":"USD","SX":"XCG","SY":"SYP","SZ":"SZL","TA":"GBP","TC":"USD","TD":"XAF","TF":"EUR","TG":"XOF","TH":"THB","TJ":"TJS","TK":"NZD","TL":"USD","TM":"TMT","TN":"TND","TO":"TOP","TR":"TRY","TT":"TTD","TV":"AUD","TW":"TWD","TZ":"TZS","UA":"UAH","UG":"UGX","UM":"USD","US":"USD","UY":"UYU","UZ":"UZS","VA":"EUR","VC":"XCD","VE":"VES","VG":"USD","VI":"USD","VN":"VND","VU":"VUV","WF":"XPF","WS":"WST","XK":"EUR","YE":"YER","YT":"EUR","ZA":"ZAR","ZM":"ZMW","ZW":"ZWG"});

  const currencyForCountry = (countryCode, languageCode) => {
    const country = String(countryCode || '').toUpperCase();
    const code = currencyByCountry[country];

    if (!code) {
      return null;
    }

    const language = normalizeLanguage(languageCode);
    let name = code;
    let symbol = code;

    try {
      name = new Intl.DisplayNames([language], {
        type: 'currency',
        fallback: 'code',
      }).of(code) || code;
    } catch (_) {
      // Keep ISO code as fallback.
    }

    try {
      const parts = new Intl.NumberFormat(language, {
        style: 'currency',
        currency: code,
        currencyDisplay: 'narrowSymbol',
      }).formatToParts(0);

      symbol =
        parts.find((part) => part.type === 'currency')?.value ||
        code;
    } catch (_) {
      // Keep ISO code as fallback.
    }

    return { code, name, symbol };
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
    languageCode,
  }) => {
    const country = componentValue(components, 'country');

    const countryCode = componentValue(
      components,
      'country',
      true,
    );

    const suggestedCurrency = currencyForCountry(countryCode, languageCode);

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

      suggestedCurrencyCode: suggestedCurrency?.code ?? null,
      suggestedCurrencyName: suggestedCurrency?.name ?? null,
      suggestedCurrencySymbol: suggestedCurrency?.symbol ?? null,
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
      languageCode,
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
      languageCode,
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


