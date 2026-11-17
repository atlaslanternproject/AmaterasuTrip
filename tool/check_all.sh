#!/usr/bin/env bash
# Amaterasu Trip - esegue tutti i controlli automatici del progetto.
# Uso (dalla cartella principale, con Git Bash): bash tool/check_all.sh
# Ferma tutto al primo errore e stampa un riepilogo finale.
# Gli emulatori usano firebase.emulators.security-test.json e progetti
# "demo-*": non toccano mai il progetto Firebase reale.

set -u
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
EMU_CONFIG="firebase.emulators.security-test.json"
RESULTS=()

step() {
  local name="$1"; shift
  echo ""
  echo "=================================================="
  echo " $name"
  echo "=================================================="
  if "$@"; then
    RESULTS+=("OK    $name")
  else
    RESULTS+=("FAIL  $name")
    summary
    echo ""
    echo "CONTROLLI FALLITI: $name"
    exit 1
  fi
}

summary() {
  echo ""
  echo "================ RIEPILOGO ================"
  for r in "${RESULTS[@]}"; do echo "$r"; done
}

flutter_analyze() { flutter analyze; }
flutter_tests() { flutter test; }
l10n_check() { dart run tool/check_l10n.dart; }
functions_lint() { npm --prefix functions run lint; }
functions_build() { npm --prefix functions run build; }

node_tests() {
  local lib="$ROOT/functions/lib/account-deletion"
  node --test functions/test/budget-calc-parity.test.cjs \
    functions/test/budget-history.test.cjs || return 1
  # Questi test ricevono il percorso del file compilato come argomento.
  node functions/test/account-deletion-cleanup-orchestrator.test.cjs \
    "$lib/account-deletion-cleanup-orchestrator.js" || return 1
  node functions/test/account-deletion-trip-inventory.test.cjs \
    "$lib/account-deletion-trip-inventory.js" || return 1
  node functions/test/firestore-account-deletion-cleanup-port.test.cjs \
    "$lib/firestore-account-deletion-cleanup-port.js" || return 1
}

emu_budget_rules() {
  firebase emulators:exec --config "$EMU_CONFIG" \
    --project demo-amaterasu-budget --only firestore,auth \
    "node functions/test/budget-firestore-rules-emulator.cjs"
}

emu_budget_privacy() {
  firebase emulators:exec --config "$EMU_CONFIG" \
    --project demo-amaterasu-budget-privacy --only firestore,auth \
    "node functions/test/budget-privacy-gate.cjs"
}

emu_budget_rc() {
  FIREBASE_FUNCTIONS_EMULATOR_HOST=127.0.0.1:15001 \
    firebase emulators:exec --config "$EMU_CONFIG" \
    --project demo-amaterasu-budget-rc --only firestore,auth,functions \
    "node functions/test/budget-rc-integration.cjs"
}

step "flutter analyze" flutter_analyze
step "flutter test" flutter_tests
step "controllo traduzioni (l10n)" l10n_check
step "functions: lint" functions_lint
step "functions: build" functions_build
step "test node" node_tests
step "emulatore: regole budget" emu_budget_rules
step "emulatore: privacy budget" emu_budget_privacy
step "emulatore: integrazione budget" emu_budget_rc

summary
echo ""
echo "TUTTI I CONTROLLI SUPERATI"
