import 'package:flutter/material.dart';

enum TripCardStatus { inProgress, upcoming, completed }

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.status,
    required this.flag,
    required this.title,
    required this.date,
    required this.places,
    required this.footer,
    required this.progress,
    required this.onTap,
  });

  final TripCardStatus status;
  final String flag;
  final String title;
  final String date;
  final String places;
  final String footer;
  final double progress;
  final VoidCallback onTap;

  static const Color _surfaceColor = Color(0xFF1A1310);
  static const Color _surfaceHighlightColor = Color(0xFF211713);
  static const Color _borderColor = Color(0xFF5A3023);
  static const Color _accentColor = Color(0xFFD96C32);
  static const Color _titleColor = Color(0xFFF2E7D5);
  static const Color _secondaryTextColor = Color(0xFFB7A99B);

  Color get _statusColor {
    switch (status) {
      case TripCardStatus.inProgress:
        return _accentColor;
      case TripCardStatus.upcoming:
        return const Color(0xFFC8894C);
      case TripCardStatus.completed:
        return _secondaryTextColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrent = status == TripCardStatus.inProgress;
    final isCompleted = status == TripCardStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: isCurrent ? _surfaceHighlightColor : _surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isCurrent
                  ? _accentColor.withValues(alpha: 0.72)
                  : _borderColor.withValues(alpha: isCompleted ? 0.42 : 0.68),
              width: isCurrent ? 1.3 : 1,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF120D0B),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _borderColor.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(flag, style: const TextStyle(fontSize: 25)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _titleColor.withValues(
                                alpha: isCompleted ? 0.78 : 1,
                              ),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            date,
                            style: const TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _secondaryTextColor.withValues(alpha: 0.75),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: _statusColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        places,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _titleColor.withValues(
                            alpha: isCompleted ? 0.65 : 0.88,
                          ),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFF30231E),
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                  ),
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        footer,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
