import 'package:flutter/material.dart';

enum TripCardStatus { inProgress, upcoming, completed }

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.status,
    required this.coverUrl,
    required this.statusLabel,
    required this.title,
    required this.date,
    required this.destination,
    required this.footer,
    required this.progress,
    required this.onTap,
  });

  final TripCardStatus status;
  final String? coverUrl;
  final String statusLabel;
  final String title;
  final String date;
  final String destination;
  final String footer;
  final double progress;
  final VoidCallback onTap;

  static const Color _surfaceColor = Color(0xFF17100D);
  static const Color _borderColor = Color(0xFF5B3023);
  static const Color _accentColor = Color(0xFFE9783D);
  static const Color _titleColor = Color(0xFFF5EBDD);
  static const Color _secondaryTextColor = Color(0xFFC2B2A4);

  Color get _statusColor {
    switch (status) {
      case TripCardStatus.inProgress:
        return _accentColor;
      case TripCardStatus.upcoming:
        return const Color(0xFFD7A05C);
      case TripCardStatus.completed:
        return const Color(0xFFB5A79B);
    }
  }

  bool get _isCompleted => status == TripCardStatus.completed;

  bool get _hasCover => coverUrl != null && coverUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 250,
          decoration: BoxDecoration(
            color: _surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: status == TripCardStatus.inProgress
                  ? _accentColor.withValues(alpha: 0.72)
                  : _borderColor.withValues(alpha: _isCompleted ? 0.48 : 0.72),
              width: status == TripCardStatus.inProgress ? 1.25 : 1,
            ),
            boxShadow: status == TripCardStatus.inProgress
                ? [
                    BoxShadow(
                      color: _accentColor.withValues(alpha: 0.09),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(),
                _buildImageTreatment(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (!_hasCover) {
      return const _TripCoverFallback();
    }

    return Image.network(
      coverUrl!,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        return const _TripCoverFallback();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return const _TripCoverFallback();
      },
    );
  }

  Widget _buildImageTreatment() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isCompleted)
          Container(color: const Color(0xFF100C0A).withValues(alpha: 0.26)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.32, 0.68, 1],
              colors: [
                Colors.black.withValues(alpha: 0.20),
                Colors.black.withValues(alpha: 0.08),
                const Color(0xFF100907).withValues(alpha: 0.58),
                const Color(0xFF090605).withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(
                label: statusLabel,
                color: _statusColor,
                muted: _isCompleted,
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.34),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 25,
                  color: _titleColor.withValues(
                    alpha: _isCompleted ? 0.72 : 0.96,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _titleColor.withValues(alpha: _isCompleted ? 0.84 : 1),
              fontSize: 25,
              height: 1.04,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.65,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 12)],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: _statusColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _titleColor.withValues(
                      alpha: _isCompleted ? 0.68 : 0.88,
                    ),
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            date,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _secondaryTextColor.withValues(
                alpha: _isCompleted ? 0.72 : 0.94,
              ),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withValues(alpha: 0.45),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  footer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 12,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.muted,
  });

  final String label;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0807).withValues(alpha: muted ? 0.68 : 0.78),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: muted ? 0.55 : 0.90)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.65,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripCoverFallback extends StatelessWidget {
  const _TripCoverFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A1A12), Color(0xFF1D100C), Color(0xFF090605)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -42,
            top: -58,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE9783D).withValues(alpha: 0.25),
                    const Color(0xFFE9783D).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.landscape_outlined,
              size: 58,
              color: const Color(0xFFE7B287).withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}
