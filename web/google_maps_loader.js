(() => {
  let loadPromise = null;

  globalThis.amaterasuLoadGoogleMaps = (apiKey) => {
    const key = String(apiKey || '').trim();

    if (!key) {
      return Promise.reject(
        new Error('Missing GOOGLE_MAPS_WEB_API_KEY.'),
      );
    }

    if (globalThis.google?.maps) {
      return Promise.resolve(true);
    }

    if (loadPromise) {
      return loadPromise;
    }

    loadPromise = new Promise((resolve, reject) => {
      const callbackName = '__amaterasuGoogleMapsReady';

      globalThis[callbackName] = () => {
        delete globalThis[callbackName];
        resolve(true);
      };

      const script = document.createElement('script');

      script.src =
        'https://maps.googleapis.com/maps/api/js' +
        `?key=${encodeURIComponent(key)}` +
        '&loading=async' +
        `&callback=${callbackName}`;

      script.async = true;
      script.defer = true;

      script.onerror = () => {
        delete globalThis[callbackName];
        loadPromise = null;

        reject(
          new Error('Unable to load Google Maps JavaScript API.'),
        );
      };

      document.head.appendChild(script);
    });

    return loadPromise;
  };
})();
