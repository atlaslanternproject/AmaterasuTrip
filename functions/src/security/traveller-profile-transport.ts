/**
 * Experimental encrypted traveller profile transport contract.
 *
 * This module validates SHAPE only.
 * It cannot authenticate ciphertext, approve devices or enforce
 * key revocation. Those checks belong to separate security layers.
 *
 * Never log a received profile or an encryption key.
 */

export interface ProtectedDetails {
  version: 1;
  algorithm: "AES-256-GCM";
  nonce: string;
  ciphertext: string;
  mac: string;
}

export interface ProtectedTravellerProfileTransport {
  hasEsimOrInternet: boolean | null;
  hasCheckedBaggage: boolean | null;
  hasCabinBaggage10Kg: boolean | null;
  protectedDetails: ProtectedDetails;
}

const PROFILE_KEYS = [
  "hasEsimOrInternet",
  "hasCheckedBaggage",
  "hasCabinBaggage10Kg",
  "protectedDetails",
];

const ENVELOPE_KEYS = [
  "version",
  "algorithm",
  "nonce",
  "ciphertext",
  "mac",
];

function invalid(): never {
  throw new Error("Invalid encrypted traveller profile transport.");
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

function requireExactKeys(
  value: Record<string, unknown>,
  expected: string[],
): void {
  const actual = Object.keys(value);

  if (
    actual.length !== expected.length ||
    actual.some((key) => !expected.includes(key))
  ) {
    invalid();
  }
}

function requireOptionalBoolean(value: unknown): boolean | null {
  if (value !== null && typeof value !== "boolean") {
    invalid();
  }

  return value as boolean | null;
}

function requireCanonicalBase64(
  value: unknown,
  minBytes: number,
  maxBytes: number,
): string {
  if (
    typeof value !== "string" ||
    value.length === 0 ||
    value.length > Math.ceil(maxBytes / 3) * 4
  ) {
    invalid();
  }

  const decoded = Buffer.from(value as string, "base64");

  if (
    decoded.length < minBytes ||
    decoded.length > maxBytes ||
    decoded.toString("base64") !== value
  ) {
    invalid();
  }

  return value as string;
}

/**
 * Strict parser: legacy plaintext fields and unexpected keys
 * are rejected, never silently copied or normalised.
 *
 * This is not a cryptographic authenticity check.
 */
export function parseProtectedTravellerProfile(
  raw: unknown,
): ProtectedTravellerProfileTransport {
  if (!isRecord(raw)) {
    invalid();
  }

  requireExactKeys(raw, PROFILE_KEYS);

  const protectedDetails = raw.protectedDetails;

  if (!isRecord(protectedDetails)) {
    invalid();
  }

  requireExactKeys(protectedDetails, ENVELOPE_KEYS);

  if (
    protectedDetails.version !== 1 ||
    protectedDetails.algorithm !== "AES-256-GCM"
  ) {
    invalid();
  }

  return {
    hasEsimOrInternet: requireOptionalBoolean(raw.hasEsimOrInternet),
    hasCheckedBaggage: requireOptionalBoolean(raw.hasCheckedBaggage),
    hasCabinBaggage10Kg: requireOptionalBoolean(raw.hasCabinBaggage10Kg),
    protectedDetails: {
      version: 1,
      algorithm: "AES-256-GCM",
      nonce: requireCanonicalBase64(protectedDetails.nonce, 12, 12),
      ciphertext: requireCanonicalBase64(
        protectedDetails.ciphertext,
        1,
        16384,
      ),
      mac: requireCanonicalBase64(protectedDetails.mac, 16, 16),
    },
  };
}