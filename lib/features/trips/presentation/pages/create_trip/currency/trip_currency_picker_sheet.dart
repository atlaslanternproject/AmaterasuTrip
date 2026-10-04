import 'package:flutter/material.dart';

import '../destination/services/destination_places_service.dart';

class TripCurrencyPickerSheet extends StatefulWidget {
  const TripCurrencyPickerSheet({
    super.key,
    required this.currencies,
    required this.selectedCurrency,
    required this.title,
    required this.searchHint,
    required this.noResultsText,
  });

  final List<TripCurrency> currencies;
  final String? selectedCurrency;
  final String title;
  final String searchHint;
  final String noResultsText;

  @override
  State<TripCurrencyPickerSheet> createState() =>
      _TripCurrencyPickerSheetState();
}

class _TripCurrencyPickerSheetState extends State<TripCurrencyPickerSheet> {
  static const Color _fieldColor = Color(0xFF241B17);
  static const Color _borderColor = Color(0xFF3A2A24);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFE86A3A);

  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TripCurrency> get _filteredCurrencies {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.currencies;
    }

    return widget.currencies.where((currency) {
      return currency.code.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query) ||
          currency.symbol.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencies = _filteredCurrencies;

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: _secondaryTextColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.title,
              style: const TextStyle(
                color: _titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              textInputAction: TextInputAction.search,
              style: const TextStyle(color: _titleColor, fontSize: 15),
              cursorColor: _accentColor,
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  color: _secondaryTextColor.withValues(alpha: 0.7),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _secondaryTextColor,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _query = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: _secondaryTextColor,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: _fieldColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _accentColor, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: currencies.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        widget.noResultsText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: currencies.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: _secondaryTextColor.withValues(alpha: 0.12),
                    ),
                    itemBuilder: (context, index) {
                      final currency = currencies[index];

                      final isSelected =
                          widget.selectedCurrency?.startsWith(currency.code) ??
                          false;

                      return ListTile(
                        onTap: () => Navigator.of(context).pop(currency),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFFD96C32,
                                  ).withValues(alpha: 0.12)
                                : _fieldColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(
                                      0xFFD96C32,
                                    ).withValues(alpha: 0.55)
                                  : _borderColor,
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                currency.symbol,
                                style: const TextStyle(
                                  color: _accentColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          currency.code,
                          style: const TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          currency.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _secondaryTextColor),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: _accentColor,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: _secondaryTextColor,
                                size: 20,
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
