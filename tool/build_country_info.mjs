// Rigenera assets/country_info/country_info.json (Info paese, nuova tappa
// 1c) dai dati aperti di Wikidata (licenza CC0 1.0): nome, codici ISO,
// prefisso, numeri di emergenza con il loro uso (polizia, ambulanza,
// pompieri...: qualificatore "has use" P366), prese e tensione, lato di
// guida, fusi.
// Niente scritto a mano: acqua potabile e requisiti d'ingresso non hanno
// una fonte aperta affidabile e restano solo come link ufficiali nell'app.
// Uso: node tool/build_country_info.mjs   (serve la rete; poi controllare
// il diff e fare commit). Non usa chiavi e non manda dati personali.

import fs from 'node:fs';

const endpoint = 'https://query.wikidata.org/sparql?format=json&query=';
const headers = {
  'User-Agent': 'amaterasu-trip-country-info/1.0 (open data refresh)',
  Accept: 'application/sparql-results+json',
};
const out = 'assets/country_info/country_info.json';

async function sparql(query) {
  const response = await fetch(endpoint + encodeURIComponent(query), {headers});
  if (!response.ok) throw new Error(`Wikidata ${response.status}`);
  return (await response.json()).results.bindings;
}

// Current countries and territories with an ISO 3166-1 code.
const base = `?c wdt:P297 ?iso . FILTER NOT EXISTS { ?c wdt:P576 [] }`;

async function countries() {
  const rows = await sparql(`SELECT ?c ?iso ?iso3 ?it ?en WHERE { ${base}
    OPTIONAL { ?c wdt:P298 ?iso3 }
    OPTIONAL { ?c rdfs:label ?it . FILTER(LANG(?it) = "it") }
    OPTIONAL { ?c rdfs:label ?en . FILTER(LANG(?en) = "en") } }`);
  return rows.map((r) => ({
    qid: r.c.value.split('/').pop(),
    iso: r.iso.value,
    iso3: r.iso3?.value,
    name: {it: r.it?.value ?? r.en?.value, en: r.en?.value ?? r.it?.value},
  }));
}

/** Values of one property by Wikidata item, English labels. */
async function property(prop, extra = '') {
  const rows = await sparql(`SELECT ?c ?v ?vLabel ?alias WHERE { ${base}
    ?c wdt:${prop} ?v . ${extra}
    SERVICE wikibase:label { bd:serviceParam wikibase:language "en". } }`);
  const by = new Map();
  for (const r of rows) {
    const qid = r.c.value.split('/').pop();
    const label = r.alias?.value ?? r.vLabel?.value ?? r.v.value;
    if (!by.has(qid)) by.set(qid, []);
    by.get(qid).push({label, plain: r.vLabel?.value ?? r.v.value});
  }
  return by;
}

const unique = (list) => [...new Set(list.filter(Boolean))];

/** Use of each emergency number (P2852 with P366), as a few fixed codes. */
async function emergencyUses() {
  const rows = await sparql(`SELECT ?c ?vLabel ?useLabel WHERE { ${base}
    ?c p:P2852 ?st . ?st ps:P2852 ?v .
    OPTIONAL { ?st pq:P366 ?use } OPTIONAL { ?v wdt:P366 ?use }
    SERVICE wikibase:label { bd:serviceParam wikibase:language "en". } }`);
  const code = (use) => {
    const u = (use ?? '').toLowerCase();
    if (/coast guard/.test(u)) return 'coastGuard';
    if (/police|gendarm|carabinieri/.test(u)) return 'police';
    if (/fire|wildfire/.test(u)) return 'fire';
    if (/medical|ambulance|magen david/.test(u)) return 'ambulance';
    if (/deaf/.test(u)) return 'deaf';
    if (/distress|emergency/.test(u)) return 'general';
    return undefined;
  };
  // Numbers known everywhere as the single emergency number.
  const general = new Set(['112', '911', '999', '000', '111']);
  const by = new Map();
  for (const r of rows) {
    const qid = r.c.value.split('/').pop();
    for (const n of r.vLabel?.value.match(/\b\d{2,4}\b/g) ?? []) {
      const c = code(r.useLabel?.value) ?? (general.has(n) ? 'general' : undefined);
      if (!c) continue;
      if (!by.has(qid)) by.set(qid, {});
      const uses = (by.get(qid)[n] ??= []);
      if (!uses.includes(c)) uses.push(c);
    }
  }
  return by;
}

const clean = {
  callingCode: (v) => unique(v.map((x) => x.label.trim())
    .filter((x) => /^\+?[\d ]{1,8}$/.test(x))
    .map((x) => (x.startsWith('+') ? x : `+${x}`)).sort()),
  emergency: (v) => unique(v.flatMap((x) => x.label.match(/\b\d{2,4}\b/g) ?? []))
    .sort(),
  // "Type F" when Wikidata has it as a name or alias, else the standard.
  plugs: (v) => {
    const byPlug = new Map();
    for (const x of v) {
      const type = /^type ([a-o])$/i.exec(x.label.trim());
      const current = byPlug.get(x.plain);
      if (type) byPlug.set(x.plain, type[1].toUpperCase());
      else if (!current) byPlug.set(x.plain, x.plain);
    }
    return unique([...byPlug.values()]).sort();
  },
  voltage: (v) => unique(v.map((x) => Number(x.label))
    .filter((n) => n >= 90 && n <= 260).map(String)).sort(),
  driving: (v) => {
    const sides = unique(v.map((x) => x.label.toLowerCase())
      .filter((x) => x === 'left' || x === 'right'));
    return sides.length === 1 ? sides[0] : undefined;
  },
  // IANA names first, then UTC offsets; descriptive names left out.
  timeZones: (v) => {
    const labels = v.map((x) => x.label.replace('−', '-').trim());
    const iana = labels.filter((x) => /^[A-Z][A-Za-z]+\/[A-Za-z_\/-]+$/.test(x));
    const utc = labels.filter((x) => /^UTC[+-]\d{1,2}(:\d{2})?$/.test(x));
    const minutes = (x) => {
      const [, sign, h, m] = /^UTC([+-])(\d{1,2})(?::(\d{2}))?$/.exec(x);
      return (sign === '-' ? -1 : 1) * (Number(h) * 60 + Number(m ?? 0));
    };
    utc.sort((a, b) => minutes(a) - minutes(b));
    return unique([...iana.sort(), ...utc]).slice(0, 8);
  },
};

const plugAlias = `OPTIONAL { ?v skos:altLabel ?alias .
  FILTER(LANG(?alias) = "en" && REGEX(?alias, "^Type [A-O]$")) }`;

async function main() {
  const list = await countries();
  const props = {
    callingCode: await property('P474'),
    emergency: await property('P2852'),
    plugs: await property('P2853', plugAlias),
    voltage: await property('P2884'),
    driving: await property('P1622'),
    timeZones: await property('P421'),
  };
  const uses = await emergencyUses();
  const result = {};
  // Only two-letter ISO codes (Wikidata also has some like "GB-WLS").
  for (const c of list.filter((x) => /^[A-Z]{2}$/.test(x.iso))) {
    const entry = {iso3: c.iso3, wikidata: c.qid, name: c.name};
    for (const [key, values] of Object.entries(props)) {
      const value = clean[key](values.get(c.qid) ?? []);
      if (value !== undefined && value.length !== 0) entry[key] = value;
    }
    const known = Object.fromEntries(Object.entries(uses.get(c.qid) ?? {})
      .filter(([n]) => entry.emergency?.includes(n))
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([n, u]) => [n, u.sort()]));
    if (Object.keys(known).length) entry.emergencyUses = known;
    const filled = Object.keys(entry).length;
    // Two items with the same code: keep the one with more data.
    if (!result[c.iso] || Object.keys(result[c.iso]).length < filled) {
      result[c.iso] = entry;
    }
  }
  const it = result.IT;
  if (Object.keys(result).length < 150 || !it?.plugs?.includes('F') ||
      it.driving !== 'right' || !it.emergency?.includes('112') ||
      !it.emergencyUses?.['113']?.includes('police')) {
    throw new Error('Unexpected data: file not written.');
  }
  const sorted = Object.fromEntries(Object.keys(result).sort()
    .map((k) => [k, result[k]]));
  const file = {
    _comment: 'Generato da tool/build_country_info.mjs: non modificare a mano.',
    source: {name: 'Wikidata', licence: 'CC0 1.0',
      url: 'https://www.wikidata.org'},
    generated: new Date().toISOString().slice(0, 10),
    countries: sorted,
  };
  fs.mkdirSync('assets/country_info', {recursive: true});
  fs.writeFileSync(out, JSON.stringify(file, null, 1) + '\n');
  console.log(`${out}: ${Object.keys(sorted).length} paesi`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
