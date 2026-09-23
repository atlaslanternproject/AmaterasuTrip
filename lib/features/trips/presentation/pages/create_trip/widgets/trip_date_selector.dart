import 'package:flutter/material.dart';

class TripDateSelector extends StatelessWidget {
  const TripDateSelector({
    super.key,
    required this.departureLabel,
    required this.returnLabel,
    required this.departureDate,
    required this.returnDate,
    required this.onDepartureTap,
    required this.onReturnTap,
  });

  final String departureLabel;
  final String returnLabel;
  final DateTime? departureDate;
  final DateTime? returnDate;
  final VoidCallback onDepartureTap;
  final VoidCallback onReturnTap;

  static const Color _surfaceColor = Color(0xFF1A1715);
  static const Color _borderColor = Color(0xFF332824);
  static const Color _creamColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);
  static const Color _accentColor = Color(0xFFD96C32);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DateBox(
            label: departureLabel,
            date: departureDate,
            onTap: onDepartureTap,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: _accentColor,
            size: 20,
          ),
        ),
        Expanded(
          child: _DateBox(
            label: returnLabel,
            date: returnDate,
            onTap: onReturnTap,
          ),
        ),
      ],
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);

    final formattedDate = date == null
        ? '—'
        : materialLocalizations.formatMediumDate(date!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: TripDateSelector._surfaceColor,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: TripDateSelector._borderColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: TripDateSelector._creamColor,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TripDateSelector._secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TripDateSelector._creamColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
