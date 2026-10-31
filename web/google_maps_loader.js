(() => {
  let loadPromise = null;

  globalThis.amaterasuLoadGoogleMaps = (apiKey) => {
    const key = String(apiKey || '').trim();

    if (!key) {
      return Promise.reject(
        new Error('GOOGLE_MAPS_WEB_API_KEY is missing.')
      );
    }

    if (globalThis.google?.maps?.importLibrary) {
      return Promise.resolve(true);
    }

    if (loadPromise) {
      return loadPromise;
    }

    loadPromise = new Promise((resolve, reject) => {
      const callbackName = '__amaterasuGoogleMapsReady';
      const script = document.createElement('script');
      let completed = false;

      const finish = (error) => {
        if (completed) return;
        completed = true;

        clearTimeout(timeout);

        if (globalThis[callbackName] === onReady) {
          delete globalThis[callbackName];
        }

        if (error) {
          script.remove();
          loadPromise = null;
          reject(error);
        } else {
          resolve(true);
        }
      };

      const onReady = () => {
        if (!globalThis.google?.maps) {
          finish(new Error('Google Maps API unavailable after loading.'));
          return;
        }
        finish(null);
      };

      const timeout = setTimeout(() => {
        finish(new Error('Google Maps loading timed out.'));
      }, 20000);

      globalThis[callbackName] = onReady;

      script.src =
        'https://maps.googleapis.com/maps/api/js' +
        '?key=' + encodeURIComponent(key) +
        '&loading=async' +
        '&callback=' + callbackName;

      script.async = true;

      script.onerror = () => {
        finish(new Error('Google Maps JavaScript API load failed.'));
      };

      document.head.appendChild(script);
    });

    return loadPromise;
  };
})();
