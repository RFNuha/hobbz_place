import 'package:string_similarity/string_similarity.dart';
import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/enums/enums.dart';

enum SortOption {
  dateAddedNewest,    // Most recently added first (default)
  dateAddedOldest,    // Oldest added first
  titleAZ,            // Alphabetical A --> Z
  titleZA,            // Alphabetical Z --> A
  ratingHighest,      // Highest rated first 
  ratingLowest,       // Lowest rated first
  lastUpdated,        // Most recently updated first
}

extension SortOptionExtension on SortOption {
  String get displayName {
    switch (this) {
      case SortOption.dateAddedNewest:
        return 'Date Added (Newest)';
      case SortOption.dateAddedOldest:
        return 'Date Added (Oldest)';
      case SortOption.titleAZ:
        return 'Title (A → Z)';
      case SortOption.titleZA:
        return 'Title (Z → A)';
      case SortOption.ratingHighest:
        return 'Rating (Highest)';
      case SortOption.ratingLowest:
        return 'Rating (Lowest)';
      case SortOption.lastUpdated:
        return 'Last Updated';
    }
  }
}

class SearchService {

  // Search

  static List<MediaItem> search(List<MediaItem> items, String query) {
    if (query.trim().isEmpty) return items;

    final lowerQuery = query.trim().toLowerCase();
    return items.where((item) {

      final titleMatch = item.title.toLowerCase().contains(lowerQuery);
      final altTitleMatch = item.altTitles.any(
        (alt) => alt.toLowerCase().contains(lowerQuery),
      );

      final fuzzyMatch = StringSimilarity.compareTwoStrings(
        item.title.toLowerCase(),
        lowerQuery,
      ) > 0.4;

      final authorMatch = item.author?.toLowerCase().contains(lowerQuery) ?? false;

      return titleMatch || altTitleMatch || fuzzyMatch || authorMatch;
    }).toList();
  }

  // Filter

  static List<MediaItem> filter(
    List<MediaItem> items, {
    List<MediaCategory> categories = const [],
    List<MediaStatus> statuses = const [],
    List<Genre> genres = const [],
  }) {
    return items.where((item) {

      // Category filter
      final categoryMatch = categories.isEmpty || categories.contains(item.category);

      // Status filter
      final statusMatch = statuses.isEmpty || statuses.contains(item.status);

      // Genre filter
      final genreMatch = genres.isEmpty ||
          item.genres.any((g) => genres.contains(g));

      return categoryMatch && statusMatch && genreMatch;
    }).toList();
  }

  // Sort

  static List<MediaItem> sort(List<MediaItem> items, SortOption sortOption) {
    // Create a copy so we don't modify the original list.
    final sorted = List<MediaItem>.from(items);

    switch (sortOption) {

      case SortOption.dateAddedNewest:
        sorted.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;

      case SortOption.dateAddedOldest:
        sorted.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;

      case SortOption.titleAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;

      case SortOption.titleZA:
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;

      case SortOption.ratingHighest:
        sorted.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        break;

      case SortOption.ratingLowest:
        sorted.sort((a, b) => (a.rating ?? 0.0).compareTo(b.rating ?? 0.0));
        break;

      case SortOption.lastUpdated:
        sorted.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
    }

    return sorted;
  }

  // Duplicate detection

  static List<MediaItem> findDuplicates(
    String newTitle,
    List<String> newAltTitles,
    List<MediaItem> existingItems, {
    String? excludeId,
  }) {
    if (newTitle.trim().isEmpty) return [];

    final lowerNewTitle = newTitle.trim().toLowerCase();

    final allNewTitles = [
      lowerNewTitle,
      ...newAltTitles.map((t) => t.trim().toLowerCase()).where((t) => t.isNotEmpty),
    ];

    return existingItems.where((existing) {
      if (existing.id == excludeId) return false;

      final allExistingTitles = [
        existing.title.toLowerCase(),
        ...existing.altTitles.map((t) => t.toLowerCase()),
      ];

      for (final newT in allNewTitles) {
        for (final existT in allExistingTitles) {
          if (newT == existT) return true;
          if (StringSimilarity.compareTwoStrings(newT, existT) > 0.8) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }
}