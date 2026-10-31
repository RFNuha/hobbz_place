import 'package:flutter/material.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/theme/app_colors.dart';

class MediaGridCard extends StatelessWidget {
  final MediaItem item;
  final VoidCallback onTap;
  const MediaGridCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,

      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Bottom Layer
            Positioned.fill(
              child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      item.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder(theme);
                      },
                    )
                  : _buildPlaceholder(theme),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Status badge
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(item.status),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status.shortLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Title and category
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Category and rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category name
                      Flexible(
                        child: Text(
                          item.category.displayName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Rating
                      if (item.rating != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 12,
                              color: DarkColors.starFilled,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder shown when there's no cover image
  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.category.displayName,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(MediaStatus status) {
    switch (status) {
      case MediaStatus.planning:
        return DarkColors.statusPlanning;
      case MediaStatus.ongoing:
        return DarkColors.statusOngoing;
      case MediaStatus.completed:
        return DarkColors.statusCompleted;
      case MediaStatus.onHold:
        return DarkColors.statusOnHold;
      case MediaStatus.dropped:
        return DarkColors.statusDropped;
    }
  }
}