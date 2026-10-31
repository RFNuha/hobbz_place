import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hobbz_place/models/models.dart';

class CollectionCard extends StatelessWidget {

  final String title;
  final String subtitle;
  final IconData icon;
  final List<MediaItem> items;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
    required this.onTap,
  });

  static const int _maxCovers = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final shelfItems = [...items]
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));

    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outline, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    // ↑ Amber (dark) / dark brown (light) square.
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: colors.onPrimary),
                ),
                const Spacer(),
                Text(
                  '${items.length}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Title + Subtitle
            Text(
              title,
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 10),

            // Cover shelf
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyShelf(theme)
                  : _buildCoverShelf(context, theme, shelfItems),
            ),

            const SizedBox(height: 8),

            Text(
              'Browse collection →',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.tertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cover Shelf
  Widget _buildCoverShelf(
    BuildContext context,
    ThemeData theme,
    List<MediaItem> shelfItems,
  ) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shelfItems.length.clamp(0, _maxCovers),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCover(theme, shelfItems[index]),
            ),
          );
        },
      ),
    );
  }

  // One cover thumbnail
  Widget _buildCover(ThemeData theme, MediaItem item) {
    final colors = theme.colorScheme;
    final placeholder = Container(
      color: colors.primaryContainer,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Text(
        item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
        style: theme.textTheme.titleLarge?.copyWith(color: colors.primary),
      ),
    );

    final url = item.coverImageUrl;
    if (url == null || url.isEmpty) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }

  // Empty Shelf
  Widget _buildEmptyShelf(ThemeData theme) {
    final colors = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: colors.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Text('Nothing here yet', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
