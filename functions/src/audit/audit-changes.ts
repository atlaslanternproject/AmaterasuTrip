// Audit Trail (v1.58.0): cosa entra nel registro. Solo le sezioni nuove;
// mai documenti privati (note e checklist private, prima o dopo); campo
// per campo il valore prima e dopo, testi tagliati a 200 caratteri; i
// campi tecnici (date di sistema, firma) non sono cambiamenti.

import {DocumentData} from "firebase-admin/firestore";

/** Trip subcollections recorded in the Audit Trail. */
export const auditSections = new Set<string>([
  "transports", "reservations", "restaurants", "savedPlaces", "notes",
  "shoppingItems", "checklists", "memories",
]);

/** Fields that are not changes of the content. */
const technical = new Set<string>([
  "tripId", "createdByUid", "createdAt", "updatedAt", "updatedByUid",
]);

/** Shared but sensitive fields: only "changed" is recorded. */
const hidden = new Set<string>(["doorCode", "wifiPassword"]);

export const maxText = 200;

export type AuditChange = {before: unknown; after: unknown};
export type AuditAction = "create" | "update" | "delete";

/**
 * Whether a document is private (never recorded).
 * @param {DocumentData|undefined} data Document data.
 * @return {boolean} True for private notes and checklists.
 */
export function isPrivate(data: DocumentData | undefined): boolean {
  return data?.visibility === "private";
}

/**
 * A short, comparable value: text cut to [maxText], timestamps as ISO,
 * maps and lists as cut JSON, nothing as null.
 * @param {unknown} value Field value.
 * @return {unknown} Value to record.
 */
export function auditValue(value: unknown): unknown {
  if (value === undefined || value === null) return null;
  if (typeof value === "number" || typeof value === "boolean") return value;
  if (typeof value === "string") {
    return value.length > maxText ? value.slice(0, maxText) + "…" : value;
  }
  const date = value as {toDate?: () => Date};
  if (typeof date.toDate === "function") return date.toDate().toISOString();
  const json = JSON.stringify(value);
  return json.length > maxText ? json.slice(0, maxText) + "…" : json;
}

/**
 * Changed fields between [before] and [after] (either may be missing).
 * @param {DocumentData|undefined} before Old data.
 * @param {DocumentData|undefined} after New data.
 * @return {Object} Field -> {before, after}.
 */
export function auditChanges(
  before: DocumentData | undefined,
  after: DocumentData | undefined,
): Record<string, AuditChange> {
  const keys = new Set([
    ...Object.keys(before ?? {}), ...Object.keys(after ?? {}),
  ]);
  const out: Record<string, AuditChange> = {};
  for (const key of [...keys].sort()) {
    if (technical.has(key)) continue;
    const a = auditValue(before?.[key]);
    const b = auditValue(after?.[key]);
    if (JSON.stringify(a) === JSON.stringify(b)) continue;
    out[key] = hidden.has(key) ?
      {before: a === null ? null : "•", after: b === null ? null : "•"} :
      {before: a, after: b};
  }
  return out;
}

/**
 * Name of the item shown in the register.
 * @param {DocumentData|undefined} data Document data.
 * @return {string} Name or title, cut.
 */
export function auditItemName(data: DocumentData | undefined): string {
  const name = data?.name ?? data?.title ?? data?.text ?? "";
  const text = typeof name === "string" ? name : "";
  return text.length > 80 ? text.slice(0, 80) + "…" : text;
}

/**
 * Action of a write.
 * @param {boolean} existed Whether the document existed before.
 * @param {boolean} exists Whether it exists after.
 * @return {AuditAction} create, update or delete.
 */
export function auditAction(existed: boolean, exists: boolean): AuditAction {
  if (!existed) return "create";
  return exists ? "update" : "delete";
}
