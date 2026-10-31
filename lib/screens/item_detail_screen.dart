import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/screens/add_edit_screen.dart';
import 'package:hobbz_place/theme/app_colors.dart';

class ItemDetailScreen extends StatelessWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        final item = provider.items.where((i) => i.id == itemId).firstOrNull;

        if (item == null) {
          // Item was deleted or not found
          return Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: const Center(child: Text('This item no longer exists.')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                // Action Button
                actions: [
                  if (item.apiSource != null && item.apiSource!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sync from API',
                      onPressed: () => _syncItem(context, provider, item),
                    ),
                  // Edit button
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditScreen(existingItem: item),
                        ),
                      );
                    },
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteDialog(context, provider, item),
                  ),
                ],

                // Cover Image area
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    item.title,
                    style: const TextStyle(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  background: item.coverImageUrl != null && item.coverImageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ImageFiltered(
                              imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                              child: Image.network(
                                item.coverImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildCoverPlaceholder(theme, item);
                                },
                              ),
                            ),
                            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 8, 16, 48),
                              child: Image.network(
                                item.coverImageUrl!,
                                fit: BoxFit.contain,                               
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),

                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black54,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : _buildCoverPlaceholder(theme, item),
                ),
              ),

              // Detail Content (scrollable list of sections)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Status Row
                      Row(
                        children: [
                          // Category chip
                          Chip(
                            label: Text(
                              item.category.displayName,
                              style: const TextStyle(fontSize: 12),
                            ),
                            avatar: Icon(
                              item.isReading ? Icons.menu_book : Icons.tv,
                              size: 16,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          // Status chip (color-coded)
                          Chip(
                            label: Text(
                              item.status.displayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                            backgroundColor: _getStatusColor(item.status),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info Cards (Author, Progress, Rating)
                      _buildInfoSection(theme, item),

                      const SizedBox(height: 16),

                      // Alt Titles
                      if (item.altTitles.isNotEmpty)
                        _buildSection(
                          theme,
                          'Alternative Titles',
                          Icons.subtitles,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.altTitles.map((title) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $title',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )).toList(),
                          ),
                        ),

                      // Genres
                      if (item.genres.isNotEmpty) ...[
                        _buildSection(
                          theme,
                          'Genres',
                          Icons.label,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: item.genres.map((genre) => Chip(
                              label: Text(
                                genre.displayName,
                                style: const TextStyle(fontSize: 11),
                              ),
                              visualDensity: VisualDensity.compact,
                            )).toList(),
                          ),
                        ),
                      ],

                      // Description
                      if (item.description != null && item.description!.isNotEmpty)
                        _buildSection(
                          theme,
                          'Description',
                          Icons.description,
                          child: Text(
                            item.description!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),

                      // Personal Notes
                      if (item.notes != null && item.notes!.isNotEmpty)
                        _buildSection(
                          theme,
                          'Personal Notes',
                          Icons.note,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              item.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),

                      // Favorite Quotes
                      if (item.favQuotes.isNotEmpty)
                        _buildSection(
                          theme,
                          'Favorite Quotes',
                          Icons.format_quote,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.favQuotes.map((quote) => Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                '"$quote"',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )).toList(),
                          ),
                        ),

                      // Dates
                      _buildSection(
                        theme,
                        'Dates',
                        Icons.calendar_today,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateRow('Added', item.dateAdded, theme),
                            _buildDateRow('Last Updated', item.lastUpdated, theme),
                            if (item.dateCompleted != null)
                              _buildDateRow('Completed', item.dateCompleted!, theme),
                          ],
                        ),
                      ),

                      // API Info
                      if (item.externalApiId != null)
                        _buildSection(
                          theme,
                          'External Link',
                          Icons.link,
                          child: Text(
                            'Linked to ${item.apiSource ?? "API"}: ${item.externalApiId}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Info Section — Author, Progress, Rating in a row of cards
  Widget _buildInfoSection(ThemeData theme, MediaItem item) {
    return Row(
      children: [
        // Author card
        if (item.author != null && item.author!.isNotEmpty)
          Expanded(
            child: _buildInfoCard(
              theme,
              Icons.person,
              'Author',
              item.author!,
            ),
          ),
        if (item.author != null && item.author!.isNotEmpty)
          const SizedBox(width: 8),

        // Progress card
        Expanded(
          child: _buildInfoCard(
            theme,
            item.isReading ? Icons.menu_book : Icons.play_circle_outline,
            'Progress',
            item.progressText,
          ),
        ),

        const SizedBox(width: 8),

        // Rating card
        Expanded(
          child: _buildInfoCard(
            theme,
            Icons.star,
            'Rating',
            item.rating != null ? '${item.rating!.toStringAsFixed(1)} / 5.0' : 'Not rated',
          ),
        ),
      ],
    );
  }

  // Info card — a small card showing an icon, label, and value
  Widget _buildInfoCard(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Section Builder — reusable section with title, icon, and content
  Widget _buildSection(ThemeData theme, String title, IconData icon, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Section content
          child,
        ],
      ),
    );
  }

  // Date row — formats and displays a date
  Widget _buildDateRow(String label, DateTime date, ThemeData theme) {
    final formatted = DateFormat('MMM dd, yyyy • h:mm a').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            formatted,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  //  Cover Placeholder — shown when no cover image URL
  Widget _buildCoverPlaceholder(ThemeData theme, MediaItem item) {
    return Container(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.isReading ? Icons.menu_book : Icons.movie,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              item.category.displayName,
              style: TextStyle(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Delete dialog
  // Sync Item
  Future<void> _syncItem(
    BuildContext context,
    MediaProvider provider,
    MediaItem item,
  ) async {
    // Show loading spinner.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Perform the sync.
    final result = await provider.syncItem(item);

    // Close the spinner.
    if (context.mounted) Navigator.pop(context);

    // Show the result.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                result.success
                    ? (result.updated ? Icons.check_circle : Icons.info)
                    : Icons.error,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          backgroundColor: result.success
              ? (result.updated ? Colors.green : Colors.blue)
              : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, MediaProvider provider, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.title}"?\n\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteItem(item.id);
              Navigator.pop(context);   // Close the dialog
              Navigator.pop(context);   // Go back to the collection screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${item.title}" deleted'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
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