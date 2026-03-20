import 'package:flutter/material.dart';

import '../../domain/models/entities.dart';

class FeedFakeImage extends StatelessWidget {
  final FeedItem item;
  final double borderRadius;
  final bool compact;
  final double? width;
  final double? height;

  const FeedFakeImage({
    super.key,
    required this.item,
    this.borderRadius = 18,
    this.compact = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = _schemeFor(item);
    final imageHeight = height ?? (compact ? 98 : 220);
    final icon = switch (item.type) {
      FeedType.news => Icons.newspaper_rounded,
      FeedType.announcement => Icons.campaign_rounded,
      FeedType.lifeEvent => Icons.celebration_rounded,
    };

    return Container(
      width: width,
      height: imageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: scheme.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -20,
            top: 18,
            child: Container(
              width: compact ? 58 : 92,
              height: compact ? 58 : 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: -18,
            top: -10,
            child: Container(
              width: compact ? 64 : 104,
              height: compact ? 64 : 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            right: compact ? 12 : 18,
            bottom: compact ? 12 : 18,
            child: Container(
              width: compact ? 54 : 108,
              height: compact ? 54 : 108,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(compact ? 14 : 24),
                color: Colors.black.withValues(alpha: 0.18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: compact ? 24 : 40,
              ),
            ),
          ),
          Positioned(
            left: compact ? 12 : 18,
            bottom: compact ? 12 : 18,
            child: Container(
              width: compact ? 60 : 116,
              height: compact ? 8 : 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: compact ? 12 : 18,
            right: compact ? 78 : 138,
            top: compact ? 12 : 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10,
                    vertical: compact ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    scheme.label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: compact ? 8.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 8 : 12),
                Text(
                  item.coverImage ?? scheme.headline,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 10 : 14,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedVisualScheme {
  final List<Color> colors;
  final String label;
  final String headline;

  const _FeedVisualScheme({
    required this.colors,
    required this.label,
    required this.headline,
  });
}

_FeedVisualScheme _schemeFor(FeedItem item) {
  if (item.type == FeedType.announcement) {
    return const _FeedVisualScheme(
      colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF99F6E4)],
      label: 'ANNOUNCEMENT',
      headline: 'Office update',
    );
  }
  if (item.type == FeedType.news) {
    return const _FeedVisualScheme(
      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
      label: 'NEWS',
      headline: 'Latest update',
    );
  }
  return const _FeedVisualScheme(
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFF472B6)],
    label: 'LIFE EVENT',
    headline: 'Team moment',
  );
}
