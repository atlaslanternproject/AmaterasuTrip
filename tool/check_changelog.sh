#!/usr/bin/env bash
# Controllo di rilascio (Extra A): la versione che si sta pubblicando deve
# avere la sua voce, in italiano e in inglese, in assets/changelog/changelog.json.
# Uso: bash tool/check_changelog.sh 1.36.0
set -euo pipefail
VER=${1:?versione mancante}
node -e '
const fs = require("fs");
const v = process.argv[1];
const data = JSON.parse(fs.readFileSync("assets/changelog/changelog.json", "utf8"));
const entry = (data.versions || []).find((e) => e.version === v);
if (!entry || !(entry.it || []).length || !(entry.en || []).length) {
  console.error("Novità mancanti per la versione " + v + " in assets/changelog/changelog.json (it ed en).");
  process.exit(1);
}
if (data.versions[0].version !== v) {
  console.error("La versione " + v + " deve essere la prima (la più recente) nel file delle novità.");
  process.exit(1);
}
console.log("Novità " + v + " presenti.");
' "$VER"
