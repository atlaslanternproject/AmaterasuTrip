package com.amaterasutrip

import com.amaterasutrip.currency.CurrencyResolver
import com.amaterasutrip.drive.GoogleDrivePicker
import android.app.Activity
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Bundle
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val CHANNEL = "com.amaterasutrip/places"
        private const val DRIVE_CHANNEL = "com.amaterasutrip/drive"
    }

    private lateinit var placesClient: PlacesClient
    private var sessionToken: AutocompleteSessionToken? = null

    private lateinit var googleDrivePicker: GoogleDrivePicker
    private var pendingDriveResult: MethodChannel.Result? = null
    private var pendingDriveRootAuthorization = false

    private val driveAuthorizationLauncher =
    registerForActivityResult(
        ActivityResultContracts.StartIntentSenderForResult()
    ) { activityResult ->

        android.util.Log.d(
            "AmaterasuDrive",
            "resolution callback resultCode=${activityResult.resultCode} " +
                "root=$pendingDriveRootAuthorization " +
                "hasData=${activityResult.data != null}"
        )

        if (pendingDriveResult == null) {
            android.util.Log.w(
                "AmaterasuDrive",
                "resolution callback received with no pending Flutter result"
            )
            return@registerForActivityResult
        }

        /*
         * Google Identity may return authorization information in the
         * result Intent. Let GoogleDrivePicker parse it whenever data
         * is available.
         *
         * If there is no Intent and the Activity result is not OK,
         * the authorization was genuinely cancelled.
         */
        if (activityResult.data != null) {
            android.util.Log.d(
                "AmaterasuDrive",
                "processing Drive authorization result Intent"
            )

            googleDrivePicker.handleAuthorizationIntent(activityResult.data)
            return@registerForActivityResult
        }

        if (activityResult.resultCode != Activity.RESULT_OK) {
            android.util.Log.w(
                "AmaterasuDrive",
                "Drive authorization resolution cancelled with no result data"
            )

            completeDriveCancellation()
            return@registerForActivityResult
        }

        /*
         * RESULT_OK without an Intent:
         * retry authorization once so Google Identity can return the
         * final AuthorizationResult now that consent has been granted.
         */
        android.util.Log.d(
            "AmaterasuDrive",
            "Drive resolution completed; requesting final authorization result"
        )

        if (pendingDriveRootAuthorization) {
            googleDrivePicker.authorizeRoot()
        } else {
            googleDrivePicker.authorizeAndPickFolder()
        }
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        googleDrivePicker = GoogleDrivePicker(this)
        googleDrivePicker.listener = createGoogleDrivePickerListener()

        val apiKey = BuildConfig.MAPS_API_KEY

        if (apiKey.isNotBlank()) {
            if (!Places.isInitialized()) {
                Places.initializeWithNewPlacesApiEnabled(
                    applicationContext,
                    apiKey
                )
            }

            placesClient = Places.createClient(this)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DRIVE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "authorizeDrive" -> {
                    if (pendingDriveResult != null) {
                        result.error(
                            "DRIVE_OPERATION_IN_PROGRESS",
                            "A Google Drive authorization is already in progress.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingDriveResult = result
                    pendingDriveRootAuthorization = false

                    android.util.Log.d(
                        "AmaterasuDrive",
                        "MethodChannel authorizeDrive"
                    )

                    googleDrivePicker.authorizeAndPickFolder()
                }

                "authorizeDriveRoot" -> {
                    if (pendingDriveResult != null) {
                        result.error(
                            "DRIVE_OPERATION_IN_PROGRESS",
                            "A Google Drive authorization is already in progress.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingDriveResult = result
                    pendingDriveRootAuthorization = true

                    android.util.Log.d(
                        "AmaterasuDrive",
                        "MethodChannel authorizeDriveRoot"
                    )

                    googleDrivePicker.authorizeRoot()
                }

                "reauthorizeDrive" -> {
                    if (pendingDriveResult != null) {
                        result.error(
                            "DRIVE_OPERATION_IN_PROGRESS",
                            "A Google Drive authorization is already in progress.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    pendingDriveResult = result

                    android.util.Log.d(
                        "AmaterasuDrive",
                        "MethodChannel reauthorizeDrive"
                    )

                    googleDrivePicker.reauthorizeDrive()
                }
                "openDriveFolder" -> {
                                    val folderId =
                                        call.argument<String>("folderId")
                                            .orEmpty()
                                            .trim()

                                    if (folderId.isBlank()) {
                                        result.error(
                                            "INVALID_DRIVE_FOLDER",
                                            "Missing Google Drive folder ID.",
                                            null
                                        )
                                        return@setMethodCallHandler
                                    }

                                    val folderUri = android.net.Uri.parse(
                                        "https://drive.google.com/drive/folders/$folderId"
                                    )

                                    val driveIntent = android.content.Intent(
                                        android.content.Intent.ACTION_VIEW,
                                        folderUri
                                    ).apply {
                                        setPackage("com.google.android.apps.docs")
                                        addFlags(
                                            android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                                        )
                                    }

                                    try {
                                        startActivity(driveIntent)
                                        result.success(null)
                                    } catch (_: android.content.ActivityNotFoundException) {
                                        val playStoreIntent = android.content.Intent(
                                            android.content.Intent.ACTION_VIEW,
                                            android.net.Uri.parse(
                                                "market://details?id=com.google.android.apps.docs"
                                            )
                                        ).apply {
                                            addFlags(
                                                android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                                            )
                                        }

                                        try {
                                            startActivity(playStoreIntent)
                                            result.success(null)
                                        } catch (_: android.content.ActivityNotFoundException) {
                                            val playStoreWebIntent =
                                                android.content.Intent(
                                                    android.content.Intent.ACTION_VIEW,
                                                    android.net.Uri.parse(
                                                        "https://play.google.com/store/apps/details?id=com.google.android.apps.docs"
                                                    )
                                                ).apply {
                                                    addFlags(
                                                        android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                                                    )
                                                }

                                            startActivity(playStoreWebIntent)
                                            result.success(null)
                                        }
                                    }
                                }

                                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {
                "searchDestinations" -> {
                    if (!ensurePlacesInitialized(result)) {
                        return@setMethodCallHandler
                    }

                    val query = call.argument<String>("query").orEmpty().trim()

                    if (query.length < 2) {
                        result.success(emptyList<Map<String, Any?>>())
                        return@setMethodCallHandler
                    }

                    searchDestinations(query, result)
                }

                "getDestinationDetails" -> {
                    if (!ensurePlacesInitialized(result)) {
                        return@setMethodCallHandler
                    }

                    val placeId = call.argument<String>("placeId").orEmpty()

                    if (placeId.isBlank()) {
                        result.error(
                            "INVALID_PLACE_ID",
                            "Missing place ID.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val languageCode =
                        call.argument<String>("languageCode") ?: "en"

                    getDestinationDetails(
                        placeId,
                        languageCode,
                        result
                    )
                }

                "reverseGeocodeDestination" -> {
                    val latitude = call.argument<Double>("latitude")
                    val longitude = call.argument<Double>("longitude")
                    val languageCode =
                        call.argument<String>("languageCode") ?: "en"

                    if (latitude == null || longitude == null) {
                        result.error(
                            "INVALID_COORDINATES",
                            "Missing map coordinates.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    reverseGeocodeDestination(
                        latitude,
                        longitude,
                        languageCode,
                        result
                    )
                }

                "getCurrencies" -> {
                    val languageCode =
                        call.argument<String>("languageCode") ?: "en"

                    result.success(
                        CurrencyResolver.getCurrencies(languageCode)
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun createGoogleDrivePickerListener(): GoogleDrivePicker.Listener {
        return object : GoogleDrivePicker.Listener {

            override fun onFolderSelected(
                accessToken: String,
                grantedScopes: List<String>,
                folderId: String
            ) {
                android.util.Log.d(
                    "AmaterasuDrive",
                    "folder selected folderId=$folderId"
                )

                val result = pendingDriveResult
                pendingDriveResult = null
                pendingDriveRootAuthorization = false

                result?.success(
                    mapOf(
                        "accessToken" to accessToken,
                        "grantedScopes" to grantedScopes,
                        "folderId" to folderId
                    )
                )
            }

            override fun onResolutionRequired(
                pendingIntent: android.app.PendingIntent?
            ) {
                if (pendingIntent == null) {
                    completeDriveError(
                        "DRIVE_AUTHORIZATION_RESOLUTION_MISSING",
                        "Google Drive authorization resolution is unavailable."
                    )
                    return
                }

                try {
                    val request =
                        IntentSenderRequest.Builder(
                            pendingIntent.intentSender
                        ).build()

                    android.util.Log.d(
                        "AmaterasuDrive",
                        "launching authorization resolution"
                    )

                    driveAuthorizationLauncher.launch(request)
                } catch (exception: Exception) {
                    completeDriveError(
                        "DRIVE_AUTHORIZATION_LAUNCH_ERROR",
                        exception.message
                    )
                }
            }

            override fun onCancelled() {
                completeDriveCancellation()
            }

            override fun onError(
                code: String,
                message: String?
            ) {
                completeDriveError(code, message)
            }
        }
    }

    private fun completeDriveCancellation() {
        android.util.Log.d(
            "AmaterasuDrive",
            "Drive authorization cancelled"
        )

        val result = pendingDriveResult
        pendingDriveResult = null
        pendingDriveRootAuthorization = false

        result?.success(null)
    }

    private fun completeDriveError(
        code: String,
        message: String?
    ) {
        android.util.Log.e(
            "AmaterasuDrive",
            "Drive error $code: $message"
        )

        val result = pendingDriveResult
        pendingDriveResult = null
        pendingDriveRootAuthorization = false

        result?.error(
            code,
            message ?: code,
            null
        )
    }

    private fun ensurePlacesInitialized(
        result: MethodChannel.Result
    ): Boolean {
        if (::placesClient.isInitialized) {
            return true
        }

        result.error(
            "PLACES_NOT_INITIALIZED",
            "Google Places SDK is not initialized.",
            null
        )

        return false
    }

    private fun searchDestinations(
        query: String,
        result: MethodChannel.Result
    ) {
        if (sessionToken == null) {
            sessionToken = AutocompleteSessionToken.newInstance()
        }

        val request = FindAutocompletePredictionsRequest.builder()
            .setQuery(query)
            .setTypesFilter(listOf("geocode"))
            .setSessionToken(sessionToken)
            .build()

        placesClient.findAutocompletePredictions(request)
            .addOnSuccessListener { response ->
                val predictions =
                    response.autocompletePredictions.map { prediction ->
                        mapOf<String, Any?>(
                            "placeId" to prediction.placeId,
                            "primaryText" to prediction
                                .getPrimaryText(null)
                                .toString(),
                            "secondaryText" to prediction
                                .getSecondaryText(null)
                                .toString(),
                            "fullText" to prediction
                                .getFullText(null)
                                .toString()
                        )
                    }

                result.success(predictions)
            }
            .addOnFailureListener {
                result.error(
                    "PLACES_SEARCH_ERROR",
                    "PLACES_SEARCH_ERROR",
                    null
                )
            }
    }

    private fun getDestinationDetails(
        placeId: String,
        languageCode: String,
        result: MethodChannel.Result
    ) {
        val fields = listOf(
            Place.Field.ID,
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
            Place.Field.TYPES,
            Place.Field.ADDRESS_COMPONENTS
        )

        val builder = FetchPlaceRequest.builder(placeId, fields)

        sessionToken?.let {
            builder.setSessionToken(it)
        }

        placesClient.fetchPlace(builder.build())
            .addOnSuccessListener { response ->
                val place = response.place
                val location = place.location

                if (location == null) {
                    result.error(
                        "PLACE_WITHOUT_LOCATION",
                        "PLACE_WITHOUT_LOCATION",
                        null
                    )
                    return@addOnSuccessListener
                }

                var country: String? = null
                var countryCode: String? = null
                var administrativeArea: String? = null
                var locality: String? = null

                place.addressComponents
                    ?.asList()
                    ?.forEach { component ->
                        val types = component.types

                        when {
                            types.contains("country") -> {
                                country = component.name
                                countryCode = component.shortName
                            }

                            types.contains("locality") -> {
                                locality = component.name
                            }

                            types.contains("postal_town") &&
                                locality == null -> {
                                locality = component.name
                            }

                            types.contains(
                                "administrative_area_level_1"
                            ) -> {
                                administrativeArea = component.name
                            }
                        }
                    }

                val currency = CurrencyResolver.forCountry(
                    countryCode,
                    languageCode
                )

                result.success(
                    mapOf<String, Any?>(
                        "placeId" to place.id,
                        "displayName" to place.displayName,
                        "formattedAddress" to place.formattedAddress,
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                        "country" to country,
                        "countryCode" to countryCode,
                        "administrativeArea" to administrativeArea,
                        "locality" to locality,
                        "suggestedCurrencyCode" to currency?.currencyCode,
                        "suggestedCurrencyName" to currency?.let {
                            CurrencyResolver.displayName(
                                it,
                                languageCode
                            )
                        },
                        "suggestedCurrencySymbol" to currency?.let {
                            CurrencyResolver.displaySymbol(it)
                        }
                    )
                )

                sessionToken = null
            }
            .addOnFailureListener {
                result.error(
                    "PLACE_DETAILS_ERROR",
                    "PLACE_DETAILS_ERROR",
                    null
                )
            }
    }

    private fun reverseGeocodeDestination(
        latitude: Double,
        longitude: Double,
        languageCode: String,
        result: MethodChannel.Result
    ) {
        if (!Geocoder.isPresent()) {
            result.error(
                "GEOCODER_UNAVAILABLE",
                "GEOCODER_UNAVAILABLE",
                null
            )
            return
        }

        val locale = Locale.forLanguageTag(languageCode)

        val geocoder = Geocoder(
            applicationContext,
            locale
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            geocoder.getFromLocation(
                latitude,
                longitude,
                1
            ) { addresses ->
                runOnUiThread {
                    deliverGeocodedAddress(
                        addresses.firstOrNull(),
                        latitude,
                        longitude,
                        languageCode,
                        result
                    )
                }
            }
        } else {
            Thread {
                try {
                    @Suppress("DEPRECATION")
                    val addresses = geocoder.getFromLocation(
                        latitude,
                        longitude,
                        1
                    )

                    runOnUiThread {
                        deliverGeocodedAddress(
                            addresses?.firstOrNull(),
                            latitude,
                            longitude,
                            languageCode,
                            result
                        )
                    }
                } catch (_: Exception) {
                    runOnUiThread {
                        result.error(
                            "REVERSE_GEOCODING_ERROR",
                            "REVERSE_GEOCODING_ERROR",
                            null
                        )
                    }
                }
            }.start()
        }
    }

    private fun deliverGeocodedAddress(
        address: Address?,
        latitude: Double,
        longitude: Double,
        languageCode: String,
        result: MethodChannel.Result
    ) {
        if (address == null) {
            result.error(
                "NO_DESTINATION_AT_POINT",
                "NO_DESTINATION_AT_POINT",
                null
            )
            return
        }

        val country = address.countryName
        val countryCode = address.countryCode?.uppercase()
        val administrativeArea = address.adminArea

        val locality =
            address.locality
                ?: address.subAdminArea
                ?: address.subLocality

        val displayName =
            locality
                ?: administrativeArea
                ?: country
                ?: address.featureName
                ?: "${"%.5f".format(latitude)}, ${"%.5f".format(longitude)}"

        val formattedAddress =
            if (address.maxAddressLineIndex >= 0) {
                address.getAddressLine(0).orEmpty()
            } else {
                listOfNotNull(
                    locality,
                    administrativeArea,
                    country
                ).distinct().joinToString(", ")
            }

        val currency = CurrencyResolver.forCountry(
            countryCode,
            languageCode
        )

        result.success(
            mapOf<String, Any?>(
                "placeId" to "geo:$latitude,$longitude",
                "displayName" to displayName,
                "formattedAddress" to formattedAddress,
                "latitude" to latitude,
                "longitude" to longitude,
                "country" to country,
                "countryCode" to countryCode,
                "administrativeArea" to administrativeArea,
                "locality" to locality,
                "suggestedCurrencyCode" to currency?.currencyCode,
                "suggestedCurrencyName" to currency?.let {
                    CurrencyResolver.displayName(it, languageCode)
                },
                "suggestedCurrencySymbol" to currency?.let {
                    CurrencyResolver.displaySymbol(it)
                }
            )
        )
    }
}


