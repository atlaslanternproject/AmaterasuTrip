import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:amaterasutrip/core/security/first_root_bootstrap_service.dart';
import 'package:amaterasutrip/core/security/first_root_local_identity.dart';
import 'package:amaterasutrip/core/security/pinned_trip_epoch_store.dart';
import 'package:amaterasutrip/core/security/signed_trip_device_roster.dart';
import 'package:amaterasutrip/core/security/traveller_profile_key_rotation.dart';
import 'package:amaterasutrip/core/security/trip_profile_access_relay.dart';
import 'package:amaterasutrip/core/security/trip_profile_bundle_relay.dart';
import 'package:amaterasutrip/core/security/trip_signed_bundle_wire.dart';
import 'package:amaterasutrip/core/security/trusted_device_public_key.dart';
import 'package:amaterasutrip/core/security/verified_trip_profile_sessions.dart';
import 'package:amaterasutrip/features/trips/data/security/trip_traveller_e2ee_bridge.dart';
import 'package:amaterasutrip/features/trips/models/trip_member.dart';

final class _LocalEpochStorage implements TrustedEpochRecordStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: 'amaterasu:$key');

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: 'amaterasu:$key', value: value);

  Future<String?> authorityPin(String uid, String tripId) async {
    final key =
        'trusted_epoch_v1:'
        '${base64UrlEncode(utf8.encode(uid))}:'
        '${base64UrlEncode(utf8.encode(tripId))}';
    final raw = await read(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map ||
        decoded['uid'] != uid ||
        decoded['tripId'] != tripId ||
        decoded['authorityPin'] is! String) {
      throw StateError('Corrupted local E2EE trust record.');
    }
    return decoded['authorityPin'] as String;
  }
}

class TripProtectedAccessPage extends StatefulWidget {
  const TripProtectedAccessPage({
    super.key,
    required this.tripId,
    required this.members,
  });

  final String tripId;
  final List<TripMember> members;

  @override
  State<TripProtectedAccessPage> createState() =>
      _TripProtectedAccessPageState();
}

class _TripProtectedAccessPageState extends State<TripProtectedAccessPage> {
  final _access = TripProfileAccessRelay();
  final _bundles = TripProfileBundleRelay();
  final _local = FirstRootLocalIdentityStorage();
  final _epochs = _LocalEpochStorage();

  bool _busy = false;
  bool _trusted = false;
  String _myExchangePin = '';
  String _mySigningPin = '';
  List<Map<String, dynamic>> _pending = [];
  final Map<String, TripTravellerProfileData> _opened = {};

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String _t(String it, String en) =>
      Localizations.localeOf(context).languageCode == 'it' ? it : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _refresh() async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      final active =
          await FirstRootBootstrapService().inspect() ==
          FirstRootState.activeOnThisDevice;
      final identity = active ? await _local.read(_uid) : null;
      final requests = active
          ? await _access.pending(widget.tripId)
          : <Map<String, dynamic>>[];
      final xp = identity == null
          ? ''
          : await TrustedDevicePublicKeyVerifier().fingerprint(
              identity.exchangePublic,
            );
      final ed = identity == null
          ? ''
          : await _fingerprint(identity.signingPublic);
      if (mounted) {
        setState(() {
          _trusted = active && identity != null;
          _pending = requests;
          _myExchangePin = xp;
          _mySigningPin = ed;
        });
      }
    } catch (e) {
      _msg('${_t('Aggiornamento fallito', 'Refresh failed')}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _fingerprint(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  Future<String?> _confirmFingerprint({
    required String title,
    required String presented,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confronta questa impronta direttamente con '
                'l\'altro viaggiatore (non tramite questa schermata). '
                'Non approvare se non coincide.',
              ),
              const SizedBox(height: 8),
              SelectableText(presented),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Impronta ricevuta dall\'altro dispositivo',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Verifica'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<TripTravellerProfileData?> _editProtectedDetails() async {
    final labels = [
      'Allergie',
      'Intolleranze',
      'Accessibilita / salute',
      'Contatto emergenza',
      'Telefono emergenza',
    ];
    final inputs = List.generate(5, (_) => TextEditingController());
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dati personali da cifrare'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Compila qui le informazioni da condividere. '
                    'Saranno cifrate sul tuo dispositivo prima dell\'invio.',
                  ),
                  for (var i = 0; i < inputs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: inputs[i],
                        decoration: InputDecoration(labelText: labels[i]),
                        maxLines: i < 3 ? 2 : 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cifra e condividi'),
            ),
          ],
        ),
      );
      if (accepted != true) return null;
      final v = inputs.map((e) => e.text.trim()).toList();
      return TripTravellerProfileData(
        hasAllergies: v[0].isNotEmpty,
        hasIntolerances: v[1].isNotEmpty,
        hasMedicalAccessibilityInfo: v[2].isNotEmpty,
        allergies: v[0],
        intolerances: v[1],
        medicalAccessibilityInfo: v[2],
        emergencyContactName: v[3],
        emergencyContactPhone: v[4],
      );
    } finally {
      for (final input in inputs) {
        input.dispose();
      }
    }
  }

  Future<void> _request(String profileUid) async {
    if (_busy || !_trusted) return;
    setState(() => _busy = true);
    try {
      final me = await _local.read(_uid);
      if (me == null) throw StateError('Missing local identity.');
      await _access.request(
        tripId: widget.tripId,
        profileUid: profileUid,
        deviceId: me.deviceId,
      );
      _msg(_t('Richiesta firmata inviata.', 'Signed request submitted.'));
    } catch (e) {
      _msg('Richiesta non inviata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> request) async {
    if (_busy || !_trusted) return;
    setState(() => _busy = true);
    try {
      final requestId = request['requestId'] as String;
      final remote = await _bundles.requesterRoot(
        tripId: widget.tripId,
        requestId: requestId,
      );
      if (!mounted) return;
      final remotePin = remote['fingerprint'] as String;
      final manuallyVerified = await _confirmFingerprint(
        title: 'Verifica il dispositivo richiedente',
        presented: remotePin,
      );
      if (manuallyVerified != remotePin) {
        throw StateError('Impronta del destinatario non verificata.');
      }
      if (!mounted) return;
      final profile = await _editProtectedDetails();
      if (profile == null) return;
      final mine = await _local.read(_uid);
      if (mine == null) throw StateError('Identita E2EE mancante.');
      final recipientUid = remote['recipientUid'] as String;
      final recipientId = remote['deviceId'] as String;
      final recipientX = base64Decode(remote['x25519PublicKey'] as String);
      final recipientEd = base64Decode(remote['ed25519PublicKey'] as String);
      final myXPin = await TrustedDevicePublicKeyVerifier().fingerprint(
        mine.exchangePublic,
      );
      final theirPin = TrustedDevicePublicKey(
        userUid: recipientUid,
        deviceId: recipientId,
        fingerprint: remotePin,
      );
      await TrustedDevicePublicKeyVerifier().requireTrusted(
        trusted: theirPin,
        userUid: recipientUid,
        deviceId: recipientId,
        presentedPublicKey: recipientX,
      );
      final myPin = TrustedDevicePublicKey(
        userUid: _uid,
        deviceId: mine.deviceId,
        fingerprint: myXPin,
      );
      final roster = await SignedTripDeviceRosterVerifier().sign(
        tripId: widget.tripId,
        authorityUid: _uid,
        authorityDeviceId: mine.deviceId,
        epoch: 2,
        activeDevices: [
          RosterDevice(
            uid: _uid,
            deviceId: mine.deviceId,
            x25519Fingerprint: myXPin,
            ed25519PublicKeyBytes: mine.signingPublic,
          ),
          RosterDevice(
            uid: recipientUid,
            deviceId: recipientId,
            x25519Fingerprint: remotePin,
            ed25519PublicKeyBytes: recipientEd,
          ),
        ],
        revokedMemberUids: const <String>{},
        authorityEd25519KeyPair: mine.signingKey,
      );
      final xPair = SimpleKeyPairData(
        mine.exchangePrivate,
        publicKey: SimplePublicKey(
          mine.exchangePublic,
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );
      final rotation = await TravellerProfileKeyRotation().rotate(
        profile: profile,
        tripId: widget.tripId,
        profileUid: _uid,
        senderDeviceId: mine.deviceId,
        previousEpoch: 1,
        revokedMemberUids: const <String>{},
        activeRecipients: [
          ProfileRotationRecipient(
            uid: _uid,
            deviceId: mine.deviceId,
            x25519PublicKey: mine.exchangePublic,
            trustedPublicKey: myPin,
          ),
          ProfileRotationRecipient(
            uid: recipientUid,
            deviceId: recipientId,
            x25519PublicKey: recipientX,
            trustedPublicKey: theirPin,
          ),
        ],
        senderX25519KeyPair: xPair,
        senderEd25519KeyPair: mine.signingKey,
      );
      final bundle = TripSignedBundleWire.encode(
        roster: roster,
        rotation: rotation,
      );
      await _bundles.approve(
        tripId: widget.tripId,
        requestId: requestId,
        bundle: bundle,
      );
      _msg('Pacchetto cifrato e firmato pubblicato.');
    } catch (e) {
      _msg('Approvazione E2EE fallita: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _refresh();
  }

  Future<void> _open(String profileUid) async {
    if (_busy || !_trusted) return;
    setState(() => _busy = true);
    try {
      final bundle = await _bundles.read(
        tripId: widget.tripId,
        profileUid: profileUid,
      );
      final roster = bundle.roster;
      final rotation = bundle.rotation;
      final authority = roster.activeDevices.singleWhere(
        (d) =>
            d.uid == roster.authorityUid &&
            d.deviceId == roster.authorityDeviceId,
      );
      final pinnedSigner = SimplePublicKey(
        authority.ed25519PublicKeyBytes,
        type: KeyPairType.ed25519,
      );
      final actualPin = await _fingerprint(authority.ed25519PublicKeyBytes);
      // Per-profile trust: one trip can have several independent profile signers.
      final scopedUid = "${_uid}_profile_$profileUid";
      final storedPin = await _epochs.authorityPin(scopedUid, widget.tripId);
      final epochStore = PinnedTripEpochStore(uid: scopedUid, storage: _epochs);
      if (storedPin != null && storedPin != actualPin) {
        throw StateError('Previously trusted signing identity changed.');
      }
      if (storedPin == null) {
        if (!mounted) return;
        final typed = await _confirmFingerprint(
          title: 'Verifica la firma di ${roster.authorityUid}',
          presented: actualPin,
        );
        if (typed != actualPin) {
          throw StateError('Authority fingerprint not independently verified.');
        }
        await epochStore.bootstrapFromVerifiedRoster(
          tripId: widget.tripId,
          roster: roster,
          authorityUid: roster.authorityUid,
          authorityDeviceId: roster.authorityDeviceId,
          independentlyPinnedAuthority: pinnedSigner,
        );
      }
      final me = await _local.read(_uid);
      if (me == null) throw StateError('Recipient key unavailable.');
      final recipientPair = SimpleKeyPairData(
        me.exchangePrivate,
        publicKey: SimplePublicKey(me.exchangePublic, type: KeyPairType.x25519),
        type: KeyPairType.x25519,
      );
      await VerifiedTripProfileSessions.instance.unlockFromVerifiedRotation(
        roster: roster,
        rotation: rotation,
        tripId: widget.tripId,
        authorityUid: roster.authorityUid,
        authorityDeviceId: roster.authorityDeviceId,
        pinnedAuthorityEd25519: pinnedSigner,
        trustedSenderX25519: TrustedDevicePublicKey(
          userUid: authority.uid,
          deviceId: authority.deviceId,
          fingerprint: authority.x25519Fingerprint,
        ),
        pinnedSenderEd25519: pinnedSigner,
        recipientUid: _uid,
        recipientDeviceId: me.deviceId,
        recipientX25519KeyPair: recipientPair,
        trustedEpochStore: epochStore,
      );
      final lease = await VerifiedTripProfileSessions.instance.requireLease(
        tripId: widget.tripId,
        profileUid: profileUid,
        currentUserUid: _uid,
      );
      final key = await lease.requireKey(
        tripId: widget.tripId,
        profileUid: profileUid,
        currentUserUid: _uid,
      );
      final opened = await TripTravellerE2eeBridge().openMember(
        transport: rotation.encryptedProfile,
        profileKey: key,
        tripId: widget.tripId,
        memberUid: profileUid,
      );
      if (mounted) {
        setState(() => _opened[profileUid] = opened);
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Informazioni protette verificate'),
            content: SingleChildScrollView(
              child: SelectableText(
                'Allergie: ${opened.allergies}\n'
                'Intolleranze: ${opened.intolerances}\n'
                'Accessibilita / salute: ${opened.medicalAccessibilityInfo}\n'
                'Emergenza: ${opened.emergencyContactName}\n'
                'Telefono: ${opened.emergencyContactPhone}',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Chiudi'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _msg('Lettura cifrata rifiutata: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _decline(String requestId) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _access.decline(tripId: widget.tripId, requestId: requestId);
    } catch (e) {
      _msg('Rifiuto fallito: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final others = widget.members.where((m) => m.uid != _uid).toList();
    return Scaffold(
      backgroundColor: const Color(0xFF120E0B),
      appBar: AppBar(
        title: const Text('Accesso ai dati protetti'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busy) const LinearProgressIndicator(),
          Text(
            _trusted
                ? 'Primo dispositivo verificato'
                : 'Configura o recupera il primo dispositivo sicuro',
            style: const TextStyle(color: Colors.white),
          ),
          if (_trusted) ...[
            const SizedBox(height: 12),
            const Text(
              'Impronta X25519 da comunicare a chi approva:',
              style: TextStyle(color: Colors.white),
            ),
            SelectableText(
              _myExchangePin,
              style: const TextStyle(color: Colors.amber),
            ),
            const SizedBox(height: 12),
            const Text(
              'Impronta della tua firma Ed25519 da comunicare '
              'a chi legge i tuoi dati:',
              style: TextStyle(color: Colors.white),
            ),
            SelectableText(
              _mySigningPin,
              style: const TextStyle(color: Colors.amber),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Viaggiatori',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          for (final member in others)
            Card(
              child: ListTile(
                title: Text(member.displayName ?? member.uid),
                subtitle: Text(
                  _opened.containsKey(member.uid)
                      ? 'Dati verificati sul dispositivo'
                      : 'Dati protetti',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: !_trusted || _busy
                          ? null
                          : () => _request(member.uid),
                      child: const Text('Richiedi'),
                    ),
                    TextButton(
                      onPressed: !_trusted || _busy
                          ? null
                          : () => _open(member.uid),
                      child: const Text('Apri'),
                    ),
                  ],
                ),
              ),
            ),
          Card(
            child: ListTile(
              title: const Text('I miei dati protetti'),
              trailing: TextButton(
                onPressed: !_trusted || _busy ? null : () => _open(_uid),
                child: const Text('Apri'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Richieste ricevute',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          for (final pending in _pending)
            Card(
              child: ListTile(
                title: Text(pending['recipientUid'] as String? ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: !_trusted || _busy
                          ? null
                          : () => _approve(pending),
                      child: const Text('Approva'),
                    ),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => _decline(pending['requestId'] as String),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          if (_pending.isEmpty)
            const Text(
              'Nessuna richiesta in attesa.',
              style: TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 16),
          const Text(
            'La revoca e la rotazione multi-destinatario non sono '
            'ancora abilitate. Non usare questo flusso per dati sanitari '
            'reali prima delle verifiche su Android e Safari.',
            style: TextStyle(color: Colors.amber),
          ),
        ],
      ),
    );
  }
}
