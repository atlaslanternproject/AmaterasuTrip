package com.amaterasutrip.currency

import java.util.Currency
import java.util.Locale
import java.util.concurrent.ConcurrentHashMap

object CurrencyResolver {

    private val territoryLocaleByCurrencyCode: Map<String, Locale> by lazy {
        buildTerritoryLocaleIndex()
    }

    private val currencyCatalogCache =
        ConcurrentHashMap<String, List<Map<String, String>>>()

    fun forCountry(
        countryCode: String?,
        languageCode: String
    ): Currency? {
        if (countryCode.isNullOrBlank()) {
            return null
        }

        return try {
            val locale = Locale.Builder()
                .setLanguage(normalizeLanguageCode(languageCode))
                .setRegion(countryCode.uppercase(Locale.ROOT))
                .build()

            Currency.getInstance(locale)
        } catch (_: Exception) {
            null
        }
    }

    fun displayName(
        currency: Currency,
        languageCode: String
    ): String {
        return currency.getDisplayName(
            Locale.forLanguageTag(normalizeLanguageCode(languageCode))
        )
    }

    fun displaySymbol(
        currency: Currency
    ): String {
        val code = currency.currencyCode

        val territoryLocale = territoryLocaleByCurrencyCode[code]

        if (territoryLocale != null) {
            val territorialSymbol = try {
                currency.getSymbol(territoryLocale)
            } catch (_: Exception) {
                null
            }

            if (isUsefulSymbol(territorialSymbol, code)) {
                return territorialSymbol!!
            }
        }

        val rootSymbol = try {
            currency.getSymbol(Locale.ROOT)
        } catch (_: Exception) {
            null
        }

        if (isUsefulSymbol(rootSymbol, code)) {
            return rootSymbol!!
        }

        return code
    }

    fun getCurrencies(
        languageCode: String
    ): List<Map<String, String>> {
        val normalizedLanguageCode =
            normalizeLanguageCode(languageCode)

        return currencyCatalogCache.getOrPut(normalizedLanguageCode) {
            Currency.getAvailableCurrencies()
                .map { currency ->
                    mapOf(
                        "code" to currency.currencyCode,
                        "name" to displayName(
                            currency,
                            normalizedLanguageCode
                        ),
                        "symbol" to displaySymbol(currency)
                    )
                }
                .sortedBy { currency ->
                    currency["code"]
                }
        }
    }

    private fun buildTerritoryLocaleIndex(): Map<String, Locale> {
        val result = mutableMapOf<String, Locale>()

        Locale.getAvailableLocales()
            .asSequence()
            .filter { locale ->
                locale.country.isNotBlank()
            }
            .forEach { locale ->
                try {
                    val currency = Currency.getInstance(locale)
                    val code = currency.currencyCode

                    if (!result.containsKey(code)) {
                        result[code] = locale
                    }
                } catch (_: Exception) {
                    // Some locales do not map to a currency.
                }
            }

        return result
    }

    private fun isUsefulSymbol(
        symbol: String?,
        currencyCode: String
    ): Boolean {
        if (symbol.isNullOrBlank()) {
            return false
        }

        return !symbol.equals(
            currencyCode,
            ignoreCase = true
        )
    }

    private fun normalizeLanguageCode(
        languageCode: String
    ): String {
        return languageCode
            .trim()
            .ifBlank { "en" }
            .substringBefore("-")
            .substringBefore("_")
            .lowercase(Locale.ROOT)
    }
}
