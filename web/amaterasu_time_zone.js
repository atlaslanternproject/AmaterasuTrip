// Fusi orari per l'app (Extra C): scarto da UTC di un fuso IANA in una data
// e ora attuale nel fuso, con Intl del browser (ora legale compresa).
// Restituiscono null per un fuso sconosciuto.
(() => {
  globalThis.amaterasuZoneOffset = (zone, isoDay) => {
    try {
      const parts = new Intl.DateTimeFormat('en-US', {
        timeZone: String(zone), timeZoneName: 'longOffset',
      }).formatToParts(new Date(`${isoDay}T12:00:00Z`));
      const name = parts.find((p) => p.type === 'timeZoneName').value;
      return name === 'GMT' ? '+00:00' : name.replace('GMT', '');
    } catch (_) {
      return null;
    }
  };

  globalThis.amaterasuZoneTime = (zone, epochMs) => {
    try {
      return new Intl.DateTimeFormat('it-IT', {
        timeZone: String(zone), hour: '2-digit', minute: '2-digit',
        hourCycle: 'h23',
      }).format(new Date(Number(epochMs)));
    } catch (_) {
      return null;
    }
  };
})();
