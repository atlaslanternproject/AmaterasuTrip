const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');

const source = fs.readFileSync(
  path.resolve(__dirname, '../../src/security/device-key-announcement.ts'),
  'utf8'
);

const compiled = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2020,
  },
});

const context = { exports: {}, Buffer };

vm.runInNewContext(compiled.outputText, context);

const parse = context.exports.parseDeviceKeyAnnouncement;

function fixture() {
  return {
    version: 1,
    userUid: 'test-user',
    deviceId: 'test-device',
    x25519PublicKey: Buffer.alloc(32, 1).toString('base64'),
    ed25519PublicKey: Buffer.alloc(32, 2).toString('base64'),
    createdAtMs: 1781370000000,
  };
}

test('accepts public identity structure', () => {
  const result = parse(fixture());
  assert.equal(result.userUid, 'test-user');
  assert.equal(result.version, 1);
});

test('contains only public metadata', () => {
  const result = parse(fixture());
  assert.deepEqual(Object.keys(result).sort(), [
    'createdAtMs',
    'deviceId',
    'ed25519PublicKey',
    'userUid',
    'version',
    'x25519PublicKey',
  ]);
});

const rejected = [
  ['private key field', d => { d.privateKey = 'SECRET'; }],
  ['unknown field', d => { d.trusted = true; }],
  ['missing key', d => { delete d.ed25519PublicKey; }],
  ['unknown version', d => { d.version = 2; }],
  ['empty user UID', d => { d.userUid = ''; }],
  ['invalid device ID', d => { d.deviceId = 'abc/def'; }],
  ['short X25519 key', d => {
    d.x25519PublicKey = Buffer.alloc(16, 1).toString('base64');
  }],
  ['all-zero X25519 key', d => {
    d.x25519PublicKey = Buffer.alloc(32).toString('base64');
  }],
  ['short Ed25519 key', d => {
    d.ed25519PublicKey = Buffer.alloc(16, 2).toString('base64');
  }],
  ['all-zero Ed25519 key', d => {
    d.ed25519PublicKey = Buffer.alloc(32).toString('base64');
  }],
  ['noncanonical Base64', d => {
    d.x25519PublicKey = 'NOT_BASE64';
  }],
  ['invalid timestamp', d => { d.createdAtMs = -1; }],
  ['fractional timestamp', d => { d.createdAtMs = 1.5; }],
];

for (const [name, mutate] of rejected) {
  test('rejects ' + name, () => {
    const data = fixture();
    mutate(data);

    assert.throws(
      () => parse(data),
      /Invalid untrusted device key announcement/
    );
  });
}

test('rejects array instead of object', () => {
  assert.throws(
    () => parse([]),
    /Invalid untrusted device key announcement/
  );
});