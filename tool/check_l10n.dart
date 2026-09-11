// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
/// Amaterasu Trip - Localization consistency checker
///
/// Controlla automaticamente tutti i file:
///   lib/l10n/app_*.arb
///
/// Regole:
/// - app_it.arb è la lingua di riferimento.
/// - Tutte le altre lingue devono avere ESATTAMENTE le stesse chiavi.
/// - Le chiavi mancanti vengono segnalate.
/// - Le chiavi extra vengono segnalate.
/// - Gli ARB non validi vengono segnalati.
/// - Le chiavi metadata (@...) e @@locale vengono ignorate.
/// - Le nuove lingue vengono rilevate automaticamente.
///
/// Utilizzo:
///   dart run tool/check_l10n.dart
///
/// Exit code:
///   0 = controllo superato
///   1 = errore di localizzazione
const String l10nDirectory = 'lib/l10n';
const String referenceLocale = 'it';
void main() {
  print('');
  print('========================================');
  print(' AMATERASU TRIP - L10N CHECK');
  print('========================================');
  print('');
  final directory = Directory(l10nDirectory);
  if (!directory.existsSync()) {
    print('❌ ERRORE');
    print('');
    print('Directory "$l10nDirectory" non trovata.');
    print('');
    exitCode = 1;
    return;
  }
  final arbFiles = directory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.arb'))
      .where((file) {
        final filename = file.uri.pathSegments.last;
        return filename.startsWith('app_');
      })
      .toList();
  if (arbFiles.isEmpty) {
    print('❌ ERRORE');
    print('');
    print('Nessun file app_*.arb trovato in $l10nDirectory.');
    print('');
    exitCode = 1;
    return;
  }
  arbFiles.sort((a, b) => a.path.compareTo(b.path));
  final Map<String, Map<String, dynamic>> localizedFiles = {};
  var hasErrors = false;
  // ============================================================
  // 1. LETTURA E VALIDAZIONE DEI FILE ARB
  // ============================================================
  for (final file in arbFiles) {
    final filename = file.uri.pathSegments.last;
    final locale = _extractLocale(filename);
    if (locale == null) {
      print('⚠️  File ignorato: $filename');
      continue;
    }
    try {
      final content = file.readAsStringSync();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        print('❌ $filename');
        print('   Il contenuto ARB deve essere un oggetto JSON.');
        print('');
        hasErrors = true;
        continue;
      }
      localizedFiles[locale] = decoded;
      print('✓ $filename');
    } on FormatException catch (error) {
      print('❌ $filename');
      print('   JSON/ARB non valido.');
      print('   ${error.message}');
      print('');
      hasErrors = true;
    } catch (error) {
      print('❌ $filename');
      print('   Impossibile leggere il file.');
      print('   $error');
      print('');
      hasErrors = true;
    }
  }
  if (localizedFiles.isEmpty) {
    print('');
    print('❌ Nessun file ARB valido trovato.');
    print('');
    exitCode = 1;
    return;
  }
  // ============================================================
  // 2. VERIFICA LINGUA DI RIFERIMENTO
  // ============================================================
  if (!localizedFiles.containsKey(referenceLocale)) {
    print('');
    print('❌ ERRORE');
    print('');
    print(
      'Il file di riferimento app_$referenceLocale.arb non è presente.',
    );
    print('');
    hasErrors = true;
  }
  if (hasErrors) {
    _printResult(false);
    exitCode = 1;
    return;
  }
  // ============================================================
  // 3. ESTRAZIONE DELLE CHIAVI
  // ============================================================
  final referenceFile = localizedFiles[referenceLocale]!;
  final referenceKeys = _localizationKeys(referenceFile);
  print('');
  print('Lingua di riferimento: app_$referenceLocale.arb');
  print('Chiavi di riferimento: ${referenceKeys.length}');
  print('');
  // ============================================================
  // 4. CONFRONTO DI TUTTE LE LINGUE
  // ============================================================
  for (final entry in localizedFiles.entries) {
    final locale = entry.key;
    // La lingua italiana viene usata come riferimento.
    if (locale == referenceLocale) {
      continue;
    }
    final filename = 'app_$locale.arb';
    final currentKeys = _localizationKeys(entry.value);
    final missingKeys = referenceKeys.difference(currentKeys);
    final extraKeys = currentKeys.difference(referenceKeys);
    if (missingKeys.isEmpty && extraKeys.isEmpty) {
      print('✓ $filename');
      print('  Tutte le ${referenceKeys.length} chiavi sono presenti.');
      print('');
      continue;
    }
    hasErrors = true;
    print('❌ $filename');
    if (missingKeys.isNotEmpty) {
      print('');
      print('  CHIAVI MANCANTI:');
      final sortedMissing = missingKeys.toList()..sort();
      for (final key in sortedMissing) {
        print('    - $key');
      }
    }
    if (extraKeys.isNotEmpty) {
      print('');
      print('  CHIAVI EXTRA:');
      final sortedExtra = extraKeys.toList()..sort();
      for (final key in sortedExtra) {
        print('    - $key');
      }
    }
    print('');
  }
  // ============================================================
  // 5. RISULTATO FINALE
  // ============================================================
  _printResult(!hasErrors);
  if (hasErrors) {
    exitCode = 1;
  }
}
// ================================================================
// FUNZIONI
// ================================================================
/// Estrae la lingua dal nome del file.
///
/// Esempi:
///   app_it.arb -> it
///   app_en.arb -> en
///   app_fr.arb -> fr
String? _extractLocale(String filename) {
  final match = RegExp(r'^app_([a-zA-Z_-]+)\.arb$').firstMatch(filename);
  if (match == null) {
    return null;
  }
  return match.group(1)?.toLowerCase();
}
/// Restituisce esclusivamente le chiavi di localizzazione.
///
/// Vengono escluse:
/// - @@locale
/// - tutte le chiavi che iniziano con @
///
/// Esempio:
///
/// {
///   "@@locale": "it",
///   "authLogin": "Accedi",
///   "@authLogin": {...}
/// }
///
/// restituisce solamente:
///
/// {
///   "authLogin"
/// }
Set<String> _localizationKeys(Map<String, dynamic> arb) {
  return arb.keys.where((key) {
    if (key == '@@locale') {
      return false;
    }
    if (key.startsWith('@')) {
      return false;
    }
    return true;
  }).toSet();
}
/// Stampa il risultato finale del controllo.
void _printResult(bool success) {
  print('========================================');
  if (success) {
    print(' LOCALIZZAZIONE OK');
    print('========================================');
    print('');
    print('✓ Tutte le lingue contengono le stesse chiavi.');
    print('✓ Nessuna chiave mancante.');
    print('✓ Nessuna chiave extra.');
    print('');
  } else {
    print(' CHECK FALLITO');
    print('========================================');
    print('');
    print('❌ Correggere gli errori di localizzazione.');
    print('');
  }
}