import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/theme/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        final allItems = provider.items;
        final totalItems = allItems.length;
        final ongoingCount = provider.getItemsByStatus(MediaStatus.ongoing).length;
        final completedCount = provider.getItemsByStatus(MediaStatus.completed).length;
        final planningCount = provider.getItemsByStatus(MediaStatus.planning).length;
        final onHoldCount = provider.getItemsByStatus(MediaStatus.onHold).length;
        final droppedCount = provider.getItemsByStatus(MediaStatus.dropped).length;

        // Calculate average rating
        final ratedItems = allItems.where((item) => item.rating != null).toList();
        final avgRating = ratedItems.isNotEmpty
            ? ratedItems.map((item) => item.rating!).reduce((a, b) => a + b) / ratedItems.length
            : 0.0;

        // Top rated items
        final topRated = List.from(ratedItems)
          ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        final topRatedDisplay = topRated.take(5).toList();

        // Recently added
        final recentItems = List.from(allItems)
          ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        final recentDisplay = recentItems.take(5).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Library Stats',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        theme,
                        'Total',
                        totalItems.toString(),
                        Icons.library_books,
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        theme,
                        'Ongoing',
                        ongoingCount.toString(),
                        Icons.play_circle,
                        DarkColors.statusOngoing,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        theme,
                        'Completed',
                        completedCount.toString(),
                        Icons.check_circle,
                        DarkColors.statusCompleted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        theme,
                        'Avg Rating',
                        avgRating > 0 ? avgRating.toStringAsFixed(1) : '—',
                        Icons.star,
                        DarkColors.starFilled,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Collection Group
              _buildSectionTitle(theme, 'By Collection', Icons.folder),
              const SizedBox(height: 8),
              ..._buildCollectionGroupBars(theme, provider, totalItems),

              const SizedBox(height: 24),

              // By Status
              _buildSectionTitle(theme, 'By Status', Icons.flag),
              const SizedBox(height: 8),
              _buildProgressBar(theme, 'Planning', planningCount, totalItems, DarkColors.statusPlanning),
              _buildProgressBar(theme, 'Ongoing', ongoingCount, totalItems, DarkColors.statusOngoing),
              _buildProgressBar(theme, 'Completed', completedCount, totalItems, DarkColors.statusCompleted),
              _buildProgressBar(theme, 'On Hold', onHoldCount, totalItems, DarkColors.statusOnHold),
              _buildProgressBar(theme, 'Dropped', droppedCount, totalItems, DarkColors.statusDropped),

              const SizedBox(height: 24),

              // Category section
              _buildSectionTitle(theme, 'By Category', Icons.category),
              const SizedBox(height: 8),
              ..._buildCategoryBars(theme, provider, totalItems),

              const SizedBox(height: 24),

              // Top Rated
              if (topRatedDisplay.isNotEmpty) ...[
                _buildSectionTitle(theme, 'Top Rated', Icons.star),
                const SizedBox(height: 8),
                ...topRatedDisplay.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.category.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: DarkColors.starFilled),
                        const SizedBox(width: 4),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: DarkColors.starFilled,
                          ),
                        ),
                      ],
                    ),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Recently added
              if (recentDisplay.isNotEmpty) ...[
                _buildSectionTitle(theme, 'Recently Added', Icons.access_time),
                const SizedBox(height: 8),
                ...recentDisplay.map((item) => ListTile(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.category.displayName} • ${DateFormat('MMM dd, yyyy').format(item.dateAdded)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.status.shortLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  dense: true,
                  visualDensity: VisualDensity.compact,
                )),
              ],

              const SizedBox(height: 96),
            ],
          ),
        );
      },
    );
  }

  // Section Title
  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Summary Card
  Widget _buildSummaryCard(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),

      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Progress bar — shows a label, count, and animated bar
  Widget _buildProgressBar(ThemeData theme, String label, int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              Text(
                '$count (${(fraction * 100).toStringAsFixed(0)}%)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Collection Group bars
  List<Widget> _buildCollectionGroupBars(ThemeData theme, MediaProvider provider, int totalItems) {
    final groups = MediaCategory.collectionGroups;
    final colors = [
      theme.colorScheme.primary,
      Colors.pinkAccent,
      Colors.teal,
      Colors.orange,
    ];

    return groups.asMap().entries.map((entry) {
      final index = entry.key;
      final group = entry.value;
      final count = provider.countByCollectionGroup(group);
      return _buildProgressBar(theme, group, count, totalItems, colors[index]);
    }).toList();
  }

  // Category bars — individual category breakdown
  List<Widget> _buildCategoryBars(ThemeData theme, MediaProvider provider, int totalItems) {
    return MediaCategory.values
        .map((cat) {
          final count = provider.getItemsByCategory(cat).length;
          return MapEntry(cat, count);
        })
        .where((entry) => entry.value > 0)
        .map((entry) {
          return _buildProgressBar(
            theme,
            entry.key.displayName,
            entry.value,
            totalItems,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          );
        })
        .toList();
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