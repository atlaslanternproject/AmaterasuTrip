(() => {
  let loader = null;

  function ensureGoogleIdentityServices() {
    if (globalThis.google?.accounts?.oauth2) {
      return Promise.resolve();
    }

    if (loader) return loader;

    loader = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.onload = () => {
        if (globalThis.google?.accounts?.oauth2) {
          resolve();
        } else {
          reject(new Error('Google Identity Services unavailable.'));
        }
      };
      script.onerror = () => reject(
        new Error('Unable to load Google Identity Services.')
      );
      document.head.appendChild(script);
    }).catch(error => {
      loader = null;
      throw error;
    });

    return loader;
  }

  globalThis.amaterasuDriveAuthorize = async clientId => {
    const id = String(clientId || '').trim();

    if (!id) {
      throw new Error('Missing Google OAuth Web Client ID.');
    }

    await ensureGoogleIdentityServices();

    return new Promise((resolve, reject) => {
      const client = globalThis.google.accounts.oauth2.initTokenClient({
        client_id: id,
        scope: 'https://www.googleapis.com/auth/drive.file',
        callback: result => {
          if (result?.error || !result?.access_token) {
            reject(new Error(result?.error || 'Google Drive access denied.'));
            return;
          }
          resolve(result.access_token);
        },
        error_callback: error => {
          reject(new Error(error?.type || 'Google Drive authorization failed.'));
        }
      });

      client.requestAccessToken({ prompt: 'consent' });
    });
  };
})();
