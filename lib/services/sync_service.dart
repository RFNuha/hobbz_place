import 'package:hobbz_place/models/models.dart';
import 'package:hobbz_place/services/anilist_service.dart';
import 'package:hobbz_place/services/tmdb_service.dart';
import 'package:hobbz_place/services/openlibrary_service.dart';

// SyncResult

class SyncResult {
  final String itemId;
  final String title;
  final bool success;
  final bool updated;
  final String message;
  final int? oldProgress;
  final int? newProgress;

  SyncResult({
    required this.itemId,
    required this.title,
    required this.success,
    required this.updated,
    required this.message,
    this.oldProgress,
    this.newProgress,
  });
}

// SyncService

class SyncService {

  // Sync single item

  static Future<SyncResult> syncItem(MediaItem item) async {
    if (item.apiSource == null || item.apiSource!.isEmpty) {
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: false,
        updated: false,
        message: 'No API source — this item wasn\'t added from an API search.',
      );
    }

    if (item.externalApiId == null || item.externalApiId!.isEmpty) {
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: false,
        updated: false,
        message: 'No external API ID stored for this item.',
      );
    }

    switch (item.apiSource!) {
      case 'anilist':
        return _syncFromAniList(item);
      case 'tmdb':
        return _syncFromTMDB(item);
      case 'openlibrary':
        return _syncFromOpenLibrary(item);
      case 'googlebooks':
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: true,
          updated: false,
          message: 'Books don\'t change — nothing to sync.',
        );
      default:
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Unknown API source: ${item.apiSource}',
        );
    }
  }

  // Sync from Anilist

  static Future<SyncResult> _syncFromAniList(MediaItem item) async {
    try {
      final anilistId = int.tryParse(item.externalApiId!);

      if (anilistId == null) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Invalid AniList ID: ${item.externalApiId}',
        );
      }

      // Call AniList API to get the latest data.
      final result = await AniListService.getById(anilistId);

      if (result == null) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Could not fetch data from AniList.',
        );
      }

      final apiProgress = result.chapters ?? result.episodes;
      final label = result.chapters != null ? 'Chapters' : 'Episodes';

      if (apiProgress != null && apiProgress != item.totalProgress) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: true,
          updated: true,
          message: '$label: ${item.totalProgress ?? "?"} → $apiProgress',
          oldProgress: item.totalProgress,
          newProgress: apiProgress,
        );
      }

      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: true,
        updated: false,
        message: 'Already up to date!',
      );

    } catch (e) {
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: false,
        updated: false,
        message: 'Sync error: $e',
      );
    }
  }

  // Sync from tmdb

  static Future<SyncResult> _syncFromTMDB(MediaItem item) async {
    try {
      // Check that the user has set their TMDB API key.
      if (!TMDBService.hasApiKey) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'TMDB API key not set. Go to Settings to add it.',
        );
      }

      final parts = item.externalApiId!.split(':');

      if (parts.length < 2) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Invalid TMDB ID format: ${item.externalApiId}',
        );
      }

      final mediaType = parts[0]; // "tv" or "movie"
      final tmdbId = int.tryParse(parts[1]); // 12345

      if (tmdbId == null) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Invalid TMDB ID number: ${parts[1]}',
        );
      }

      // Call the appropriate TMDB endpoint.
      TMDBResult? result;
      if (mediaType == 'tv') {
        result = await TMDBService.getTVDetails(tmdbId);
      } else {
        result = await TMDBService.getMovieDetails(tmdbId);
      }

      if (result == null) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Could not fetch data from TMDB.',
        );
      }

      // Check for changes
      if (result.episodeCount != null &&
          result.episodeCount != item.totalProgress) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: true,
          updated: true,
          message:
              'Episodes: ${item.totalProgress ?? "?"} → ${result.episodeCount}',
          oldProgress: item.totalProgress,
          newProgress: result.episodeCount,
        );
      }

      // No changes found
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: true,
        updated: false,
        message: 'Already up to date!',
      );

    } catch (e) {
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: false,
        updated: false,
        message: 'Sync error: $e',
      );
    }
  }

  // Sync from open library

  static Future<SyncResult> _syncFromOpenLibrary(MediaItem item) async {
    try {
      final workKey = item.externalApiId!;

      if (workKey.isEmpty) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Invalid Open Library key.',
        );
      }

      // Fetch the latest work details from Open Library.
      final result = await OpenLibraryService.getWorkDetails(workKey);

      if (result == null) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: false,
          updated: false,
          message: 'Could not fetch data from Open Library.',
        );
      }

      // Check if we can update the description.
      // Only update if the API has a description AND our item doesn't.
      bool hasChanges = false;
      final changes = <String>[];

      if (result.description != null &&
          (item.description == null || item.description!.isEmpty)) {
        hasChanges = true;
        changes.add('Description updated');
      }

      if (!hasChanges) {
        return SyncResult(
          itemId: item.id,
          title: item.title,
          success: true,
          updated: false,
          message: 'Already up to date!',
        );
      }

      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: true,
        updated: true,
        message: changes.join(', '),
      );

    } catch (e) {
      return SyncResult(
        itemId: item.id,
        title: item.title,
        success: false,
        updated: false,
        message: 'Sync error: $e',
      );
    }
  }

  // Sync all

  static Future<List<SyncResult>> syncAll(List<MediaItem> items) async {
    final results = <SyncResult>[];

    final syncableItems = items.where(
      (item) => item.apiSource != null && item.apiSource!.isNotEmpty,
    ).toList();

    // Sync each item one at a time.
    for (final item in syncableItems) {
      final result = await syncItem(item);
      results.add(result);

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return results;
  }
}