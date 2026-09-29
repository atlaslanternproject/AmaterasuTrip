package com.amaterasutrip.drive

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.util.Log
import com.google.android.gms.auth.api.identity.AuthorizationRequest
import com.google.android.gms.auth.api.identity.AuthorizationResult
import com.google.android.gms.auth.api.identity.Identity
import com.google.android.gms.common.api.Scope
import com.google.android.gms.common.api.ApiException

class GoogleDrivePicker(
    private val activity: Activity
) {

    companion object {
        private const val TAG = "AmaterasuDrive"

        private const val DRIVE_FILE_SCOPE =
            "https://www.googleapis.com/auth/drive.file"

        private const val DRIVE_FOLDER_MIME_TYPE =
            "application/vnd.google-apps.folder"

        private const val PICKED_FILE_IDS =
            "picked_file_ids"
    }

    var listener: Listener? = null

    /*
     * true:
     * l'utente ha scelto "Il mio Drive".
     *
     * In questo caso NON dobbiamo aspettare picked_file_ids:
     * il parent della futura cartella del viaggio è semplicemente "root".
     */
    private var selectingRoot = false

    /*
     * Google Picker:
     * serve esclusivamente quando l'utente vuole scegliere
     * una cartella già esistente.
     */
    fun authorizeAndPickFolder() {
        Log.d(TAG, "authorizeAndPickFolder")

        selectingRoot = false

        authorize(
            usePicker = true
        )
    }

    /*
     * "Il mio Drive":
     * autorizziamo Drive ma NON apriamo il Picker.
     *
     * Dopo l'autorizzazione restituiamo:
     *
     * folderId = root
     *
     * La cartella reale del viaggio verrà creata soltanto
     * quando Flutter eseguirà CREA VIAGGIO.
     */
    fun authorizeRoot() {
        Log.d(TAG, "authorizeRoot")

        selectingRoot = true

        authorize(
            usePicker = false
        )
    }

    private fun authorize(
        usePicker: Boolean
    ) {
        val builder = AuthorizationRequest.builder()
            .setRequestedScopes(
                listOf(
                    Scope(DRIVE_FILE_SCOPE)
                )
            )
            .setOptOutIncludingGrantedScopes(true)

        /*
         * Per il Picker vogliamo esplicitamente il flusso interattivo.
         *
         * Per root invece NON forziamo SELECT_ACCOUNT ogni volta:
         * Google può utilizzare l'autorizzazione già concessa.
         *
         * Se serve una risoluzione/consenso, AuthorizationClient
         * restituisce comunque pendingIntent e MainActivity lo apre.
         */
        if (usePicker) {
            builder
                .setPrompt(
                    AuthorizationRequest.Prompt.CONSENT or
                        AuthorizationRequest.Prompt.SELECT_ACCOUNT
                )
                .addResourceParameter(
                    AuthorizationRequest.ResourceParameter.PICKER_OAUTH_TRIGGER,
                    "true"
                )
                .addResourceParameter(
                    AuthorizationRequest.ResourceParameter.PICKER_ALLOW_FOLDER_SELECTION,
                    "true"
                )
                .addResourceParameter(
                    AuthorizationRequest.ResourceParameter.PICKER_ALLOW_MULTIPLE,
                    "false"
                )
                .addResourceParameter(
                    AuthorizationRequest.ResourceParameter.PICKER_MIMETYPES,
                    DRIVE_FOLDER_MIME_TYPE
                )
        }

        Log.d(
            TAG,
            "authorize usePicker=$usePicker selectingRoot=$selectingRoot"
        )

        Identity
            .getAuthorizationClient(activity)
            .authorize(builder.build())
            .addOnSuccessListener { result ->

                Log.d(
                    TAG,
                    "authorization success " +
                        "hasResolution=${result.hasResolution()} " +
                        "selectingRoot=$selectingRoot"
                )

                handleAuthorizationResult(result)
            }
            .addOnFailureListener { exception ->

                Log.e(
                    TAG,
                    "authorization failed",
                    exception
                )

                selectingRoot = false

                listener?.onError(
                    "DRIVE_AUTHORIZATION_ERROR",
                    exception.message
                )
            }
    }

    /*
     * Chiamato da MainActivity quando Google restituisce
     * il risultato della resolution.
     */
    fun handleAuthorizationIntent(
        data: Intent?
    ) {
        Log.d(
            TAG,
            "handleAuthorizationIntent dataNull=${data == null} selectingRoot=$selectingRoot"
        )

        if (data == null) {
            selectingRoot = false
            listener?.onCancelled()
            return
        }

        try {
            val result =
                Identity
                    .getAuthorizationClient(activity)
                    .getAuthorizationResultFromIntent(data)

            handleAuthorizationResult(result)

        } catch (exception: Exception) {

            if (exception is ApiException) {
                Log.e(
                    TAG,
                    "getAuthorizationResultFromIntent failed " +
                        "statusCode=${exception.statusCode} " +
                        "statusMessage=${exception.statusMessage}",
                    exception
                )
            } else {
                Log.e(
                    TAG,
                    "getAuthorizationResultFromIntent failed " +
                        "type=${exception.javaClass.name} " +
                        "message=${exception.message}",
                    exception
                )
            }

            Log.d(
                TAG,
                "authorization result Intent " +
                    "action=${data.action} " +
                    "hasExtras=${data.extras != null} " +
                    "extraKeys=${data.extras?.keySet()?.sorted()}"
            )

            selectingRoot = false

            listener?.onError(
                "DRIVE_AUTHORIZATION_RESULT_ERROR",
                exception.message
            )
        }
    }

    private fun handleAuthorizationResult(
        result: AuthorizationResult
    ) {
        /*
         * Se Google richiede account/consenso,
         * MainActivity lancerà questo PendingIntent.
         *
         * IMPORTANTE:
         * selectingRoot NON viene azzerato qui.
         * Deve sopravvivere al round-trip verso Google.
         */
        if (result.hasResolution()) {

            Log.d(
                TAG,
                "authorization requires resolution selectingRoot=$selectingRoot"
            )

            val pendingIntent = result.pendingIntent

            if (pendingIntent == null) {
                selectingRoot = false

                listener?.onError(
                    "DRIVE_RESOLUTION_MISSING",
                    null
                )

                return
            }

            listener?.onResolutionRequired(
                pendingIntent
            )

            return
        }

        deliverAuthorization(result)
    }

    private fun deliverAuthorization(
        result: AuthorizationResult
    ) {
        val accessToken = result.accessToken

        Log.d(
            TAG,
            "deliverAuthorization " +
                "token=${!accessToken.isNullOrBlank()} " +
                "selectingRoot=$selectingRoot"
        )

        if (accessToken.isNullOrBlank()) {
            selectingRoot = false

            listener?.onError(
                "DRIVE_ACCESS_TOKEN_MISSING",
                null
            )

            return
        }

        /*
         * =====================================================
         * IL MIO DRIVE
         * =====================================================
         *
         * Non esiste una cartella da selezionare.
         * Google Drive usa l'alias speciale "root".
         *
         * Flutter riceverà:
         *
         * parentFolderId = root
         *
         * e createTripArchive() creerà fisicamente
         * la cartella del viaggio solo al CREA VIAGGIO.
         */
        if (selectingRoot) {

            Log.d(
                TAG,
                "Drive root authorized successfully"
            )

            selectingRoot = false

            listener?.onFolderSelected(
                accessToken = accessToken,
                grantedScopes = result.grantedScopes,
                folderId = "root"
            )

            return
        }

        /*
         * =====================================================
         * CARTELLA ESISTENTE
         * =====================================================
         *
         * Qui invece il Picker deve aver restituito
         * picked_file_ids.
         */
        val pickedFolderId =
            extractPickedFolderId(result)

        if (pickedFolderId.isNullOrBlank()) {

            Log.w(
                TAG,
                "Picker completed without picked_file_ids"
            )

            listener?.onError(
                "DRIVE_FOLDER_NOT_SELECTED",
                null
            )

            return
        }

        Log.d(
            TAG,
            "Drive folder selected id=$pickedFolderId"
        )

        listener?.onFolderSelected(
            accessToken = accessToken,
            grantedScopes = result.grantedScopes,
            folderId = pickedFolderId
        )
    }

    private fun extractPickedFolderId(
        result: AuthorizationResult
    ): String? {

        val params =
            result.tokenResponseParams
                ?: return null

        val rawIds =
            params[PICKED_FILE_IDS]
                ?.toString()
                ?.trim()
                ?.takeIf {
                    it.isNotEmpty()
                }
                ?: return null

        return rawIds
            .split(",")
            .map {
                it.trim()
            }
            .firstOrNull {
                it.isNotEmpty()
            }
    }

    interface Listener {

        fun onFolderSelected(
            accessToken: String,
            grantedScopes: List<String>,
            folderId: String
        )

        fun onResolutionRequired(
            pendingIntent: PendingIntent?
        )

        fun onCancelled()

        fun onError(
            code: String,
            message: String?
        )
    }
}


