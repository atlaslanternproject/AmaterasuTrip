const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require('typescript');

const source = fs.readFileSync(
  path.resolve(__dirname, '../../src/security/traveller-profile-transport.ts'),
  'utf8'
);

const compiled = ts.transpileModule(source, {
  compilerOptions: {
    module: ts.ModuleKind.CommonJS,
    target: ts.ScriptTarget.ES2020,
  },
});

const context = { exports: {}, Buffer };

vm.runInNewContext(compiled.outputText, context, {
  filename: 'traveller-profile-transport.js',
});

const parse = context.exports.parseProtectedTravellerProfile;

assert.equal(typeof parse, 'function');

function fixture() {
  return {
    hasEsimOrInternet: true,
    hasCheckedBaggage: false,
    hasCabinBaggage10Kg: null,
    protectedDetails: {
      version: 1,
      algorithm: 'AES-256-GCM',
      nonce: Buffer.alloc(12, 1).toString('base64'),
      ciphertext: Buffer.from('synthetic-test-data').toString('base64'),
      mac: Buffer.alloc(16, 2).toString('base64'),
    },
  };
}

test('accepts structurally valid encrypted envelope', () => {
  const parsed = parse(fixture());
  assert.equal(parsed.hasEsimOrInternet, true);
  assert.equal(parsed.protectedDetails.version, 1);
});

test('accepts null public organisational answers', () => {
  const data = fixture();
  data.hasEsimOrInternet = null;
  data.hasCheckedBaggage = null;

  const parsed = parse(data);
  assert.equal(parsed.hasEsimOrInternet, null);
  assert.equal(parsed.hasCheckedBaggage, null);
});

const rejectedCases = [
  ['plaintext allergies', d => { d.allergies = 'TEST_ALLERGY'; }],
  ['plaintext health indicator', d => { d.hasAllergies = true; }],
  ['plaintext medical information', d => {
    d.medicalAccessibilityInfo = 'TEST_MEDICAL';
  }],
  ['plaintext emergency phone', d => {
    d.emergencyContactPhone = '+39 0000000000';
  }],
  ['unknown profile field', d => { d.unexpectedField = 'extra'; }],
  ['missing organisational field', d => {
    delete d.hasCheckedBaggage;
  }],
  ['missing encrypted envelope', d => {
    delete d.protectedDetails;
  }],
  ['unknown envelope version', d => {
    d.protectedDetails.version = 2;
  }],
  ['unknown algorithm', d => {
    d.protectedDetails.algorithm = 'UNKNOWN';
  }],
  ['incorrect nonce length', d => {
    d.protectedDetails.nonce = Buffer.alloc(8).toString('base64');
  }],
  ['incorrect MAC length', d => {
    d.protectedDetails.mac = Buffer.alloc(8).toString('base64');
  }],
  ['empty ciphertext', d => {
    d.protectedDetails.ciphertext = '';
  }],
  ['oversized ciphertext', d => {
    d.protectedDetails.ciphertext =
      Buffer.alloc(16385).toString('base64');
  }],
  ['noncanonical Base64', d => {
    d.protectedDetails.nonce = 'NOT_VALID_BASE64!';
  }],
  ['string instead of boolean', d => {
    d.hasEsimOrInternet = 'true';
  }],
  ['extra plaintext field inside envelope', d => {
    d.protectedDetails.healthData = 'PLAINTEXT';
  }],
];

for (const [name, mutate] of rejectedCases) {
  test('rejects ' + name, () => {
    const data = fixture();
    mutate(data);

    assert.throws(
      () => parse(data),
      /Invalid encrypted traveller profile transport/
    );
  });
}