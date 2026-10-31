import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/services/search_service.dart';

class SearchFilterBar extends StatefulWidget {
  final String? collectionGroup;

  const SearchFilterBar({super.key, this.collectionGroup});

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    final provider = context.read<MediaProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // main UI
  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,

                    onChanged: (value) {
                      provider.setSearchQuery(value);
                    },

                    decoration: InputDecoration(
                      hintText: 'Search by title, alt title, or author...',

                      prefixIcon: const Icon(Icons.search, size: 20),

                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(width: 8),

                // Filter button
                _buildFilterButton(context, provider),

                const SizedBox(width: 4),

                // Sort button
                _buildSortButton(context, provider),
              ],
            ),

            if (provider.hasActiveFilters)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildActiveFilterChips(context, provider),
              ),
          ],
        );
      },
    );
  }

  // Filter button
  Widget _buildFilterButton(BuildContext context, MediaProvider provider) {
    final hasFilters = provider.selectedCategories.isNotEmpty ||
        provider.selectedStatuses.isNotEmpty ||
        provider.selectedGenres.isNotEmpty;

    return IconButton(
      onPressed: () => _showFilterSheet(context, provider),

      icon: Badge(
        isLabelVisible: hasFilters,
        smallSize: 8,
        child: const Icon(Icons.tune, size: 22),
      ),

      tooltip: 'Filter',
    );
  }

  // Sort button
  Widget _buildSortButton(BuildContext context, MediaProvider provider) {
    return PopupMenuButton<SortOption>(

      onSelected: (option) {
        provider.setSortOption(option);
      },

      icon: const Icon(Icons.sort, size: 22),
      tooltip: 'Sort',

      itemBuilder: (context) {
        return SortOption.values.map((option) {
          return PopupMenuItem<SortOption>(
            value: option,
            child: Row(
              children: [
                if (provider.sortOption == option)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                if (provider.sortOption == option)
                  const SizedBox(width: 8),
                if (provider.sortOption != option)
                  const SizedBox(width: 24),

                Text(
                  option.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    // Bold the selected option.
                    fontWeight: provider.sortOption == option
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, MediaProvider provider) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (provider.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: const Text('Clear All', style: TextStyle(fontSize: 11)),
                avatar: const Icon(Icons.clear_all, size: 14),
                onPressed: () {
                  provider.clearAllFilters();
                  _searchController.clear();
                },
                visualDensity: VisualDensity.compact,
              ),
            ),

          // Category filter 
          ...provider.selectedCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(cat.displayName, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                final updated = List<MediaCategory>.from(provider.selectedCategories)
                  ..remove(cat);
                provider.setSelectedCategories(updated);
              },
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
          )),

          // Status filter
          ...provider.selectedStatuses.map((status) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(status.displayName, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                final updated = List<MediaStatus>.from(provider.selectedStatuses)
                  ..remove(status);
                provider.setSelectedStatuses(updated);
              },
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            ),
          )),

          // Genre filter
          ...provider.selectedGenres.map((genre) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(genre.displayName, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                final updated = List<Genre>.from(provider.selectedGenres)
                  ..remove(genre);
                provider.setSelectedGenres(updated);
              },
              visualDensity: VisualDensity.compact,
              backgroundColor: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
            ),
          )),

          // Sort indicator
          if (provider.sortOption != SortOption.dateAddedNewest)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                label: Text(provider.sortOption.displayName, style: const TextStyle(fontSize: 11)),
                avatar: const Icon(Icons.sort, size: 14),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  provider.setSortOption(SortOption.dateAddedNewest);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  // Filter bottom sheet

  void _showFilterSheet(BuildContext context, MediaProvider provider) {
    List<MediaCategory> availableCategories;
    if (widget.collectionGroup != null) {
      availableCategories = MediaCategory.values
          .where((c) => c.collectionGroup == widget.collectionGroup)
          .toList();
    } else {
      availableCategories = MediaCategory.values.toList();
    }

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.85,
              expand: false,

              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (provider.hasActiveFilters)
                            TextButton(
                              onPressed: () {
                                provider.clearAllFilters();
                                _searchController.clear();
                                setSheetState(() {});
                              },
                              child: const Text('Reset All'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category filter
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: availableCategories.map((cat) {
                          final isSelected = provider.selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(
                              cat.displayName,
                              style: TextStyle(fontSize: 12,
                                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              final updated = List<MediaCategory>.from(
                                provider.selectedCategories,
                              );
                              if (selected) {
                                updated.add(cat);
                              } else {
                                updated.remove(cat);
                              }
                              provider.setSelectedCategories(updated);
                              setSheetState(() {});
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Status filter
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: MediaStatus.values.map((status) {
                          final isSelected = provider.selectedStatuses.contains(status);
                          return FilterChip(
                            label: Text(
                              status.displayName,
                              style: TextStyle(fontSize: 12,
                                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              final updated = List<MediaStatus>.from(
                                provider.selectedStatuses,
                              );
                              if (selected) {
                                updated.add(status);
                              } else {
                                updated.remove(status);
                              }
                              provider.setSelectedStatuses(updated);
                              setSheetState(() {});
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Genre filter
                      Text(
                        'Genre',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: Genre.values.map((genre) {
                          final isSelected = provider.selectedGenres.contains(genre);
                          return FilterChip(
                            label: Text(
                              genre.displayName,
                              style: TextStyle(fontSize: 12,
                                color: isSelected ? Theme.of(context).colorScheme.onPrimary : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              final updated = List<Genre>.from(
                                provider.selectedGenres,
                              );
                              if (selected) {
                                updated.add(genre);
                              } else {
                                updated.remove(genre);
                              }
                              provider.setSelectedGenres(updated);
                              setSheetState(() {});
                            },
                            selectedColor: Theme.of(context).colorScheme.primary,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}