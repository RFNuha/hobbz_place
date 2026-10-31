import 'package:flutter/material.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/services/database_service.dart';
import 'package:hobbz_place/services/search_service.dart';
import 'package:hobbz_place/services/sync_service.dart';
import 'dart:async';
import 'package:hobbz_place/services/cloud_sync_service.dart';

class MediaProvider extends ChangeNotifier {

  //Core data
  List<MediaItem> _items = [];
  ThemeMode _themeMode =
      DatabaseService.instance.getSetting('themeMode', defaultValue: 'dark') == 'light'
          ? ThemeMode.light
          : ThemeMode.dark;
  // Current theme. Checks what you did last time and if its your first time then default dark mode.

  //Search & Filter state
  String _searchQuery = '';  
  List<MediaCategory> _selectedCategories = [];   
  List<MediaStatus> _selectedStatuses = [];  
  List<Genre> _selectedGenres = [];   
  SortOption _sortOption = SortOption.dateAddedNewest;  
  bool _isGridView = false;  

  List<MediaItem> get items => _items;
  ThemeMode get themeMode => _themeMode;
  String get searchQuery => _searchQuery;
  List<MediaCategory> get selectedCategories => _selectedCategories;
  List<MediaStatus> get selectedStatuses => _selectedStatuses;
  List<Genre> get selectedGenres => _selectedGenres;
  SortOption get sortOption => _sortOption;
  bool get isGridView => _isGridView;
  int get totalCount => _items.length;
  List<MediaItem> get filteredItems {
    // Step 1: Search
    var result = SearchService.search(_items, _searchQuery);

    // Step 2: Filter
    result = SearchService.filter(
      result,
      categories: _selectedCategories,
      statuses: _selectedStatuses,
      genres: _selectedGenres,
    );

    // Step 3: Sort
    result = SearchService.sort(result, _sortOption);

    return result;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategories(List<MediaCategory> categories) {
    _selectedCategories = categories;
    notifyListeners();
  }

  void setSelectedStatuses(List<MediaStatus> statuses) {
    _selectedStatuses = statuses;
    notifyListeners();
  }

  void setSelectedGenres(List<Genre> genres) {
    _selectedGenres = genres;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedCategories = [];
    _selectedStatuses = [];
    _selectedGenres = [];
    _sortOption = SortOption.dateAddedNewest;
    notifyListeners();
  }

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedCategories.isNotEmpty ||
        _selectedStatuses.isNotEmpty ||
        _selectedGenres.isNotEmpty ||
        _sortOption != SortOption.dateAddedNewest;
  }

  List<MediaItem> getFilteredItemsByCollectionGroup(String group) {
    final groupItems = _items.where(
      (item) => item.category.collectionGroup == group,
    ).toList();

    var result = SearchService.search(groupItems, _searchQuery);
    result = SearchService.filter(
      result,
      categories: _selectedCategories,
      statuses: _selectedStatuses,
      genres: _selectedGenres,
    );
    result = SearchService.sort(result, _sortOption);
    return result;
  }

  Future<void> loadItems() async {
    _items = DatabaseService.instance.getAllItems();
    notifyListeners();
  }

  Future<bool> addItem(MediaItem item) async {
    if (_items.any((i) => i.id == item.id)) return false;
    final src = item.apiSource;
    final extId = item.externalApiId;
    if (src != null && src.isNotEmpty && extId != null && extId.isNotEmpty) {
      if (findByApiId(src, extId) != null) return false;
    }
    _items.add(item);
    notifyListeners();
    await DatabaseService.instance.addItem(item);
    unawaited(CloudSyncService.instance.pushItem(item));
    return true;
  }

  MediaItem? findByApiId(String apiSource, String externalApiId) {
    for (final item in _items) {
      if (item.apiSource == apiSource && item.externalApiId == externalApiId) {
        return item;
      }
    }
    return null;
  }

  /// True if this online entry is already in the library.
  bool isInLibrary(String apiSource, String externalApiId) {
    return findByApiId(apiSource, externalApiId) != null;
  }

  /// Updates an existing item in the database and in memory list.
  Future<void> updateItem(MediaItem item) async {
  await DatabaseService.instance.updateItem(item);
  final index = _items.indexWhere((i) => i.id == item.id);
  if (index != -1) {
    _items[index] = item;
  }
  notifyListeners();
  unawaited(CloudSyncService.instance.pushItem(item));
}

  /// Deletes an item from the database and in-memory list.
  Future<void> deleteItem(String id) async {
    final ms = await DatabaseService.instance.deleteItem(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    unawaited(CloudSyncService.instance.pushDelete(id, ms));
  }

  /// Gets all items in a collection group (WITHOUT filters — for stats).
  List<MediaItem> getItemsByCollectionGroup(String group) {
    return _items.where((item) => item.category.collectionGroup == group).toList();
  }

  /// Gets all items with a specific status (WITHOUT filters — for stats).
  List<MediaItem> getItemsByStatus(MediaStatus status) {
    return _items.where((item) => item.status == status).toList();
  }

  /// Gets all items in a specific category (WITHOUT filters — for stats).
  List<MediaItem> getItemsByCategory(MediaCategory category) {
    return _items.where((item) => item.category == category).toList();
  }

  /// Counts items in a collection group (for the library cards).
  int countByCollectionGroup(String group) {
    return _items.where((item) => item.category.collectionGroup == group).length;
  }

  // DUPLICATE DETECTION
  List<MediaItem> findDuplicates(String title, List<String> altTitles, {String? excludeId}) {
    return SearchService.findDuplicates(title, altTitles, _items, excludeId: excludeId);
  }

  // THEME — dark/light mode toggle
  /// Switches between dark and light mode.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    DatabaseService.instance.putSetting(
      'themeMode',
      _themeMode == ThemeMode.light ? 'light' : 'dark',
    );
    notifyListeners();
  }

  // SYNC
  Future<SyncResult> syncItem(MediaItem item) async {
    final result = await SyncService.syncItem(item);
    // If the sync found new data, apply the changes.
    if (result.success && result.updated) {
      final updatedItem = item.copyWith(
        totalProgress: result.newProgress ?? item.totalProgress,
      );
      await updateItem(updatedItem);
    }

    return result;
  }

  /// Syncs ALL items that have an API source.
  Future<List<SyncResult>> syncAllItems() async {
    final results = await SyncService.syncAll(_items);
    // Apply all successful updates.
    for (final result in results) {
      if (result.success && result.updated) {
        // Find this item in our in memory list.
        final itemIndex = _items.indexWhere((i) => i.id == result.itemId);
        if (itemIndex >= 0) {
          final item = _items[itemIndex];
          final updatedItem = item.copyWith(
            totalProgress: result.newProgress ?? item.totalProgress,
          );
          await DatabaseService.instance.updateItem(updatedItem);
          _items[itemIndex] = updatedItem;
          unawaited(CloudSyncService.instance.pushItem(updatedItem));
          //Update both the database AND the in memory list.
        }
      }
    }

    notifyListeners();
    return results;
  }
}