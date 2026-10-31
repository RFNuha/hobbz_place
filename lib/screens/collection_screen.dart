// collection_screen.dart
// --------------------------------------------------------------------------
// Shows all items in ONE collection group (like "Graphical" or "Movies").
//
// Day 6: SearchFilterBar, filtered results, result count.
// Day 7 (NEW): Grid/List toggle view, improved UI.
// --------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/screens/item_detail_screen.dart';
import 'package:hobbz_place/theme/app_colors.dart';
import 'package:hobbz_place/widgets/search_filter_bar.dart';
import 'package:hobbz_place/widgets/media_grid_card.dart';

class CollectionScreen extends StatelessWidget {
  final String collectionGroup;

  const CollectionScreen({super.key, required this.collectionGroup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(collectionGroup),
        actions: [
          // Grid/list toggle
          Consumer<MediaProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isGridView ? Icons.view_list : Icons.grid_view,
                ),
                tooltip: provider.isGridView ? 'Switch to List' : 'Switch to Grid',
                onPressed: () => provider.toggleViewMode(),
              );
            },
          ),
        ],
      ),

      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          final items = provider.getFilteredItemsByCollectionGroup(collectionGroup);
          final totalCount = provider.countByCollectionGroup(collectionGroup);

          return Column(
            children: [
              // Search/filter bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                child: SearchFilterBar(collectionGroup: collectionGroup),
              ),

              // Result Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      provider.hasActiveFilters
                          ? '${items.length} of $totalCount items'
                          : '${items.length} items',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Items (Grid or List)
              Expanded(
                child: items.isEmpty
                    ? _buildEmptyState(context, provider, totalCount)
                    : provider.isGridView
                        ? _buildGridView(context, items, theme)
                        : _buildListView(context, items, theme),
              ),
            ],
          );
        },
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState(BuildContext context, MediaProvider provider, int totalCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            totalCount == 0 ? Icons.library_add : Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            totalCount == 0
                ? 'No items in $collectionGroup yet'
                : 'No results match your filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          if (provider.hasActiveFilters)
            TextButton.icon(
              onPressed: () => provider.clearAllFilters(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }

  // Grid View — Netflix style image grid
  Widget _buildGridView(BuildContext context, List<MediaItem> items, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 2 / 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),

      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MediaGridCard(
          item: item,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(itemId: item.id),
              ),
            );
          },
        );
      },
    );
  }

  // List View — detailed list with text info
  Widget _buildListView(BuildContext context, List<MediaItem> items, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(itemId: item.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Cover Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 50,
                      height: 70,
                      child: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                          ? Image.network(
                              item.coverImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.broken_image,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                              child: Center(
                                child: Text(
                                  item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Category + Status badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.category.displayName,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.status.shortLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Progress + Rating
                        Row(
                          children: [
                            Icon(
                              item.isReading ? Icons.menu_book : Icons.play_circle_outline,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.progressText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            if (item.rating != null) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.star, size: 14, color: DarkColors.starFilled),
                              const SizedBox(width: 2),
                              Text(
                                item.rating!.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: DarkColors.starFilled,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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