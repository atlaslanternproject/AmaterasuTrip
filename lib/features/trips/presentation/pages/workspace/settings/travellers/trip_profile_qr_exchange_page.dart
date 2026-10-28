import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:amaterasutrip/core/security/personal_profile_key_vault.dart';
import 'package:amaterasutrip/core/security/traveller_health_transport_codec.dart';
import 'package:amaterasutrip/features/settings/presentation/pages/account/e2ee_qr_scanner_page.dart';

/// A temporary, recipient-bound exchange. The profile key is never sent
/// to Firebase. No stored questionnaire is modified by this screen.
class TripProfileQrExchangePage extends StatefulWidget {
  const TripProfileQrExchangePage({
    super.key,
    required this.tripId,
    required this.profileUid,
    required this.ownerMode,
  });

  final String tripId;
  final String profileUid;
  final bool ownerMode;

  @override
  State<TripProfileQrExchangePage> createState() =>
      _TripProfileQrExchangePageState();
}

class _TripProfileQrExchangePageState extends State<TripProfileQrExchangePage> {
  static const _requestPrefix = 'amaterasu-profile-request-v1:';
  static const _grantPrefix = 'amaterasu-profile-grant-v1:';

  final _exchange = X25519();
  final _aes = AesGcm.with256bits();

  SimpleKeyPair? _requestKeyPair;
  String? _challenge;
  String? _requestQr;
  String? _grantQr;
  String? _status;
  bool _busy = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isIt => Localizations.localeOf(context).languageCode == 'it';

  String _t(String it, String en) => _isIt ? it : en;

  String _b64(List<int> value) => base64UrlEncode(value).replaceAll('=', '');

  List<int> _decode(String value) =>
      base64Url.decode(base64Url.normalize(value));

  String _pack(String prefix, Map<String, dynamic> value) =>
      '$prefix${_b64(utf8.encode(jsonEncode(value)))}';

  Map<String, dynamic> _unpack(String input, String prefix) {
    if (!input.startsWith(prefix) || input.length > 1500) {
      throw const FormatException('Invalid QR protocol.');
    }
    final decoded = jsonDecode(
      utf8.decode(_decode(input.substring(prefix.length))),
    );
    if (decoded is! Map) {
      throw const FormatException('Invalid QR contents.');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _checkTime(Map<String, dynamic> data) {
    final expiry = data['expiresAt'];
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    if (expiry is! int || expiry <= now || expiry > now + 180000) {
      throw const FormatException('QR expired or invalid.');
    }
  }

  Future<List<Map<String, dynamic>>> _members() async {
    final result = await FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('listTripMembers')
        .call<Map<String, dynamic>>({'tripId': widget.tripId});

    final raw = result.data['members'];
    if (raw is! List) {
      throw StateError('Invalid trip members response.');
    }

    return [for (final value in raw) Map<String, dynamic>.from(value as Map)];
  }

  Map<String, dynamic> _member(List<Map<String, dynamic>> members, String uid) {
    for (final member in members) {
      if (member['uid'] == uid) return member;
    }
    throw StateError('The traveler is not a member of this trip.');
  }

  Future<String?> _scan() {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const E2eeQrScannerPage()),
    );
  }

  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } catch (error) {
      if (mounted) {
        setState(() {
          // Do not show raw errors, encrypted material or private keys.
          _status = error is FormatException
              ? _t('QR non valido o scaduto.', 'Invalid or expired QR.')
              : _t(
                  'Autorizzazione non riuscita. Verifica il viaggio, '
                      'il profilo e la connessione.',
                  'Authorization failed. Check the trip, profile and connection.',
                );
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createRequest() => _run(() async {
    if (_uid.isEmpty || widget.profileUid == _uid) {
      throw StateError('Invalid recipient.');
    }

    final members = await _members();
    _member(members, _uid);
    _member(members, widget.profileUid);

    final pair = await _exchange.newKeyPair();
    final publicKey = await pair.extractPublicKey();
    final random = Random.secure();
    final challenge = _b64(List<int>.generate(24, (_) => random.nextInt(256)));

    final request = <String, dynamic>{
      'version': 1,
      'tripId': widget.tripId,
      'profileUid': widget.profileUid,
      'recipientUid': _uid,
      'challenge': challenge,
      'publicKey': _b64(publicKey.bytes),
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 3))
          .millisecondsSinceEpoch,
    };

    if (!mounted) return;
    setState(() {
      _requestKeyPair = pair;
      _challenge = challenge;
      _requestQr = _pack(_requestPrefix, request);
      _status = null;
    });
  });

  Future<SecretKey> _wrappingKey({
    required SecretKey shared,
    required String challenge,
  }) {
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: shared,
      nonce: _decode(challenge),
      info: utf8.encode('amaterasu-trip-profile-qr-v1'),
    );
  }

  Future<void> _authorize() => _run(() async {
    if (_uid != widget.profileUid) {
      throw StateError('Only the profile owner can authorize access.');
    }

    final raw = await _scan();
    if (raw == null) return;

    final request = _unpack(raw, _requestPrefix);
    _checkTime(request);

    if (request['version'] != 1 ||
        request['tripId'] != widget.tripId ||
        request['profileUid'] != _uid) {
      throw const FormatException('QR belongs to another profile or trip.');
    }

    final recipientUid = request['recipientUid'];
    final publicBytes = _decode(request['publicKey'] as String);
    final challenge = request['challenge'];

    if (recipientUid is! String ||
        recipientUid == _uid ||
        challenge is! String ||
        publicBytes.length != 32 ||
        _decode(challenge).length != 24) {
      throw const FormatException('Invalid QR recipient.');
    }

    final members = await _members();
    final recipient = _member(members, recipientUid);
    final ownMember = _member(members, _uid);

    if (ownMember['travellerProfileFormat'] != 'encrypted' ||
        ownMember['travellerProfile'] is! Map) {
      throw StateError('Encrypted personal questionnaire unavailable.');
    }

    SecretKey? personalKey;
    final vault = PersonalProfileKeyVault();
    final candidates = await vault.candidates(_uid, widget.tripId);

    for (final candidate in candidates) {
      try {
        await TravellerHealthTransportCodec().open(
          transport: Map<String, dynamic>.from(
            ownMember['travellerProfile'] as Map,
          ),
          profileKey: candidate.key,
          tripId: widget.tripId,
          memberUid: _uid,
        );
        personalKey = candidate.key;
        break;
      } catch (_) {
        // A candidate must decrypt the CURRENT saved profile.
      }
    }

    if (personalKey == null) {
      throw StateError('Current personal profile key unavailable.');
    }

    if (!mounted) return;

    final name =
        recipient['displayName'] ??
        recipient['username'] ??
        _t('questo viaggiatore', 'this traveler');

    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Autorizza la lettura', 'Authorize reading')),
        content: Text(
          _t(
            'Vuoi consentire a $name di leggere le tue informazioni '
                'personali per questo viaggio? Il QR è temporaneo.',
            'Allow $name to read your personal information for '
                'this trip? The QR is temporary.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(_t('Annulla', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_t('Autorizza', 'Authorize')),
          ),
        ],
      ),
    );

    if (consent != true) return;

    final senderPair = await _exchange.newKeyPair();
    final senderPublic = await senderPair.extractPublicKey();

    final shared = await _exchange.sharedSecretKey(
      keyPair: senderPair,
      remotePublicKey: SimplePublicKey(publicBytes, type: KeyPairType.x25519),
    );

    final wrapping = await _wrappingKey(shared: shared, challenge: challenge);

    final personalBytes = await personalKey.extractBytes();

    // Authenticated encryption: no raw personal key in the QR.
    final box = await _aes.encrypt(
      personalBytes,
      secretKey: wrapping,
      aad: utf8.encode('${widget.tripId}|$_uid|$recipientUid|$challenge'),
    );

    final grant = <String, dynamic>{
      'version': 1,
      'tripId': widget.tripId,
      'profileUid': _uid,
      'recipientUid': recipientUid,
      'challenge': challenge,
      'senderPublic': _b64(senderPublic.bytes),
      'nonce': _b64(box.nonce),
      'ciphertext': _b64(box.cipherText),
      'mac': _b64(box.mac.bytes),
      'expiresAt': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 3))
          .millisecondsSinceEpoch,
    };

    if (!mounted) return;
    setState(() {
      _grantQr = _pack(_grantPrefix, grant);
      _status = null;
    });
  });

  Future<void> _readGrant() => _run(() async {
    final pair = _requestKeyPair;
    final challenge = _challenge;

    if (pair == null || challenge == null) {
      throw StateError('No active QR request.');
    }

    final raw = await _scan();
    if (raw == null) return;

    final grant = _unpack(raw, _grantPrefix);
    _checkTime(grant);

    if (grant['version'] != 1 ||
        grant['tripId'] != widget.tripId ||
        grant['profileUid'] != widget.profileUid ||
        grant['recipientUid'] != _uid ||
        grant['challenge'] != challenge) {
      throw const FormatException('QR does not match this request.');
    }

    final senderBytes = _decode(grant['senderPublic'] as String);
    if (senderBytes.length != 32) {
      throw const FormatException('Invalid sender key.');
    }

    final shared = await _exchange.sharedSecretKey(
      keyPair: pair,
      remotePublicKey: SimplePublicKey(senderBytes, type: KeyPairType.x25519),
    );

    final wrapping = await _wrappingKey(shared: shared, challenge: challenge);

    final box = SecretBox(
      _decode(grant['ciphertext'] as String),
      nonce: _decode(grant['nonce'] as String),
      mac: Mac(_decode(grant['mac'] as String)),
    );

    final rawKey = await _aes.decrypt(
      box,
      secretKey: wrapping,
      aad: utf8.encode(
        '${widget.tripId}|${widget.profileUid}|$_uid|$challenge',
      ),
    );

    if (rawKey.length != 32) {
      throw const FormatException('Invalid questionnaire key.');
    }

    final members = await _members();
    final owner = _member(members, widget.profileUid);

    if (owner['travellerProfileFormat'] != 'encrypted' ||
        owner['travellerProfile'] is! Map) {
      throw StateError('Encrypted questionnaire unavailable.');
    }

    final profile = await TravellerHealthTransportCodec().open(
      transport: Map<String, dynamic>.from(owner['travellerProfile'] as Map),
      profileKey: SecretKey(rawKey),
      tripId: widget.tripId,
      memberUid: widget.profileUid,
    );

    // Invalidate the temporary request: no persistent permission granted.
    if (!mounted) return;
    setState(() {
      _requestKeyPair = null;
      _challenge = null;
      _requestQr = null;
      _status = _t(
        'Lettura autorizzata completata.',
        'Authorized reading completed.',
      );
    });

    String display(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return _t('Non indicato', 'Not provided');
      }
      return value.toString();
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t('Profilo autorizzato', 'Authorized profile')),
        content: SingleChildScrollView(
          child: SelectableText(
            '${_t('Allergie', 'Allergies')}: ${display(profile['allergies'])}\n'
            '${_t('Intolleranze', 'Intolerances')}: ${display(profile['intolerances'])}\n'
            '${_t('Salute e accessibilità', 'Health and accessibility')}: '
            '${display(profile['medicalAccessibilityInfo'])}\n'
            '${_t('Contatto emergenza', 'Emergency contact')}: '
            '${display(profile['emergencyContactName'])}\n'
            '${_t('Telefono emergenza', 'Emergency phone')}: '
            '${display(profile['emergencyContactPhone'])}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t('Chiudi', 'Close')),
          ),
        ],
      ),
    );
  });

  Widget _qr(String value) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: QrImageView(
        data: value,
        version: QrVersions.auto,
        size: 260,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (!widget.ownerMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _createRequest();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF100C0A);
    const cream = Color(0xFFF2E7D5);
    const amber = Color(0xFFD6A34A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: cream,
        title: Text(
          widget.ownerMode
              ? _t('Autorizza un viaggiatore', 'Authorize a traveler')
              : _t('Accedi con QR', 'Access with QR'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_busy) const LinearProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  widget.ownerMode
                      ? _t(
                          'Scansiona il QR della richiesta mostrato '
                              'dall’altro viaggiatore. Poi conferma e mostragli '
                              'il tuo QR temporaneo.',
                          'Scan the other traveler’s request QR. '
                              'Confirm and show your temporary authorization QR.',
                        )
                      : _t(
                          'Mostra questo QR al proprietario del profilo. '
                              'Quando ti mostrerà il suo QR di autorizzazione, '
                              'premi Scansiona autorizzazione.',
                          'Show this QR to the profile owner. '
                              'Then scan the authorization QR they show you.',
                        ),
                  style: const TextStyle(
                    color: cream,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (_status != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_status!, style: const TextStyle(color: amber)),
                  ),
                if (_requestQr != null || _grantQr != null)
                  Center(child: _qr((_grantQr ?? _requestQr)!)),
                const SizedBox(height: 24),
                if (widget.ownerMode)
                  FilledButton.icon(
                    onPressed: _busy ? null : _authorize,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(_t('Scansiona richiesta', 'Scan request')),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: _busy || _requestQr == null ? null : _readGrant,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(
                      _t('Scansiona autorizzazione', 'Scan authorization'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _busy ? null : _createRequest,
                    child: Text(_t('Genera un nuovo QR', 'Generate a new QR')),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  _t(
                    'Il QR scade entro 3 minuti. Le chiavi personali '
                        'non vengono caricate sul server.',
                    'The QR expires within 3 minutes. '
                        'Personal keys are not uploaded to the server.',
                  ),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
