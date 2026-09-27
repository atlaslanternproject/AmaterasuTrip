package com.amaterasutrip

import com.amaterasutrip.currency.CurrencyResolver
import android.location.Address
import android.location.Geocoder
import android.os.Build
import android.os.Bundle
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompleteSessionToken
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FetchPlaceRequest
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Currency
import java.util.Locale

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.amaterasutrip/places"
    }

    private lateinit var placesClient: PlacesClient
    private var sessionToken: AutocompleteSessionToken? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

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

                            types.contains("administrative_area_level_1") -> {
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
                        "suggestedCurrencyName" to currency?.let { CurrencyResolver.displayName(it, languageCode) },
                        "suggestedCurrencySymbol" to currency?.let { CurrencyResolver.displaySymbol(it) }
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
                "suggestedCurrencyName" to currency?.let { CurrencyResolver.displayName(it, languageCode) },
                "suggestedCurrencySymbol" to currency?.let { CurrencyResolver.displaySymbol(it) }
            )
        )
    }

}


