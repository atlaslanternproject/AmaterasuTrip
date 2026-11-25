import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions";

initializeApp();

setGlobalOptions({
  maxInstances: 10,
  region: "europe-west1",
});

// Le funzioni sono definite nei moduli qui sotto e riesportate con lo
// stesso nome: l'ordine conta, i moduli si caricano dopo l'inizializzazione.

export {createTripInvite} from "./trip-invites/create-trip-invite";
export {revokeTripInvite} from "./trip-invites/revoke-trip-invite";
export {getTripInviteStatus} from "./trip-invites/get-trip-invite-status";
export {validateTripInvite} from "./trip-invites/validate-trip-invite";
export {
  migrateOwnedTripsMembership,
} from "./trip-members/migrate-owned-trips-membership";
export {acceptTripInvite} from "./trip-invites/accept-trip-invite";
export {listTripMembers} from "./trip-members/list-trip-members";
export {
  saveMyTripOrganizationalProfile,
} from "./trip-members/save-my-trip-organizational-profile";
export {removeTripMember} from "./trip-members/remove-trip-member";

export {
  setTripStatus,
} from "./trip-management/set-trip-status";

export {
  updateTripCloudArchive,
} from "./trip-management/update-trip-cloud-archive";

export {
  duplicateTrip,
} from "./trip-management/duplicate-trip";

export {
  deleteTrip,
} from "./trip-management/delete-trip";

// TODO(audit): C4 funzione esportata ma mai chiamata dall'app.
// La pulizia lato server della cancellazione account
// (src/account-deletion) non è collegata: completarla o toglierla.
export {inspectAccountDeletionTrips} from
  "./account-deletion/inspect-account-deletion-trips";

export {
  approveBucketActivityDeletion,
} from "./bucket-list/approve-bucket-activity-deletion";

export {
  createBudgetExpense,
  proposeBudgetRevision,
  approveBudgetRevision,
  requestBudgetReimbursement,
  confirmBudgetReimbursement,
} from "./budget/budget-functions";

export {
  requestBudgetCancellation,
  decideBudgetCancellation,
  cancelPrivateBudgetExpense,
} from "./budget/budget-functions";

export {
  createBudgetCategory,
  updateBudgetExpenseCategory,
  ensureBudgetExpenseFx,
  overrideBudgetExpenseFx,
  syncBudgetParticipantNames,
  closeBudgetDebt,
  listBudgetHistory,
  declareBudgetPayment,
  voidBudgetPayment,
} from "./budget/budget-functions";

// Weather of the trip destination (v1.50.0), shared cache per trip.
export {getTripWeather} from "./weather/get-trip-weather";

// Audit Trail (v1.58.0): register written only by the server.
export {recordTripAudit} from "./audit/record-trip-audit";
