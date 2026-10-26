/* eslint-disable require-jsdoc, valid-jsdoc */
/**
 * Untrusted public device key announcement.
 *
 * Parsing does NOT register or authorise a device.
 * Never use these public keys for key wrapping until they have
 * been authenticated against an independently trusted identity.
 */
export interface DeviceKeyAnnouncement {
  version: 1;
  userUid: string;
  deviceId: string;
  x25519PublicKey: string;
  ed25519PublicKey: string;
  createdAtMs: number;
}

function invalid(): never {
  throw new Error("Invalid untrusted device key announcement.");
}

function record(value: unknown): value is Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

function identifier(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9_-]{1,128}$/.test(value)
  ) {
    invalid();
  }
  return value as string;
}

function publicKey(value: unknown): string {
  if (
    typeof value !== "string" ||
    !/^[A-Za-z0-9+/]{42}[AEIMQUYcgkosw048]=$/.test(value)
  ) {
    invalid();
  }

  const bytes = Buffer.from(value as string, "base64");

  if (
    bytes.length !== 32 ||
    bytes.every((byte) => byte === 0) ||
    bytes.toString("base64") !== value
  ) {
    invalid();
  }

  return value as string;
}

export function parseDeviceKeyAnnouncement(
  raw: unknown,
): DeviceKeyAnnouncement {
  if (!record(raw)) {
    invalid();
  }

  const expected = [
    "version",
    "userUid",
    "deviceId",
    "x25519PublicKey",
    "ed25519PublicKey",
    "createdAtMs",
  ];

  const keys = Object.keys(raw);

  if (
    keys.length !== expected.length ||
    keys.some((key) => !expected.includes(key)) ||
    raw.version !== 1 ||
    typeof raw.createdAtMs !== "number" ||
    !Number.isSafeInteger(raw.createdAtMs) ||
    raw.createdAtMs <= 0
  ) {
    invalid();
  }

  return {
    version: 1,
    userUid: identifier(raw.userUid),
    deviceId: identifier(raw.deviceId),
    x25519PublicKey: publicKey(raw.x25519PublicKey),
    ed25519PublicKey: publicKey(raw.ed25519PublicKey),
    createdAtMs: raw.createdAtMs as number,
  };
}
