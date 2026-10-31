import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hobbz_place/services/anilist_service.dart';
import 'package:hobbz_place/services/tmdb_service.dart';
import 'package:hobbz_place/services/openlibrary_service.dart';
import 'package:hobbz_place/services/google_books_service.dart';
import 'package:hobbz_place/providers/media_provider.dart';
import 'package:hobbz_place/enums/enums.dart';
import 'package:hobbz_place/models/models.dart';

// ENUM — which API source to search

enum ApiSource {
  anilist,
  tmdb,
  openLibrary,
}

enum AniListMode { manga, novel, anime }

class ApiSearchScreen extends StatefulWidget {
  const ApiSearchScreen({super.key});

  @override
  State<ApiSearchScreen> createState() => _ApiSearchScreenState();
}

class _ApiSearchScreenState extends State<ApiSearchScreen> {

  ApiSource _selectedSource = ApiSource.anilist;

  final _searchController = TextEditingController();

  Timer? _debounceTimer;

  bool _isSearching = false;

  List<AniListMediaResult> _anilistResults = [];
  List<TMDBResult> _tmdbResults = [];
  List<BookResult> _bookResults = [];

  AniListMode _anilistMode = AniListMode.manga;

  final Set<String> _adding = {};

  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Search — called when the user types

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _anilistResults = [];
        _tmdbResults = [];
        _bookResults = [];
        _errorMessage = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query.trim());
    });
  }

  // Perform Search

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case ApiSource.anilist:
          final results = await AniListService.search(
            query,
            type: _anilistMode == AniListMode.anime ? 'ANIME' : 'MANGA',
            format: _anilistMode == AniListMode.novel ? 'NOVEL' : null,
          );
          if (mounted) {
            setState(() {
              _anilistResults = results;
              _isSearching = false;
            });
          }
          break;

        case ApiSource.tmdb:
          if (!TMDBService.hasApiKey) {
            setState(() {
              _errorMessage = 'TMDB API key not set! Go to Settings to add it.';
              _isSearching = false;
            });
            return;
          }
          final results = await TMDBService.searchMulti(query);
          if (mounted) {
            setState(() {
              _tmdbResults = results;
              _isSearching = false;
            });
          }
          break;

        case ApiSource.openLibrary:
          var books = await GoogleBooksService.search(query);
          if (books.isEmpty) {
            final olResults = await OpenLibraryService.search(query);
            books = olResults.map(BookResult.fromOpenLibrary).toList();
          }
          if (mounted) {
            setState(() {
              _bookResults = books;
              _isSearching = false;
            });
          }
          break;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Search failed: $e';
          _isSearching = false;
        });
      }
    }
  }

  // Add to library
  String? _sourceOf(dynamic result) {
    if (result is AniListMediaResult) return 'anilist';
    if (result is TMDBResult) return 'tmdb';
    if (result is BookResult) return result.source;
    return null;
  }

  String? _idOf(dynamic result) {
    if (result is AniListMediaResult) return '${result.id}';
    if (result is TMDBResult) return '${result.mediaType}:${result.id}';
    if (result is BookResult) return result.id;
    return null;
  }

  Future<void> _addToLibrary(dynamic result) async {
    final provider = Provider.of<MediaProvider>(context, listen: false);
    final src = _sourceOf(result);
    final extId = _idOf(result);
    if (src == null || extId == null) return;
    final key = '$src|$extId';

    // Check 1 - is it already in the lib
    if (provider.isInLibrary(src, extId)) {
      _showMessage('Already in your library', Colors.orange);
      return;
    }

    // Check 2 - is it being saved right now
    if (_adding.contains(key)) return;
    _adding.add(key);

    try {
      MediaItem? converted;

      if (result is AniListMediaResult) {
        converted = _convertAniListResult(result);
      } else if (result is TMDBResult) {
        converted = _convertTMDBResult(result);
      } else if (result is BookResult) {
        converted = await _convertBookResult(result);
      }
      if (converted == null) return;
      final MediaItem newItem = converted;

      // Check 3 - a very similar title in the same collection? 
      final similar = provider
          .findDuplicates(newItem.title, newItem.altTitles)
          .where((d) =>
              d.category.collectionGroup == newItem.category.collectionGroup)
          .toList();
      if (similar.isNotEmpty) {
        if (!mounted) return;
        final proceed = await _confirmDuplicate(newItem, similar);
        if (!proceed) return;
      }

      final added = await provider.addItem(newItem);

      if (mounted) {
        setState(() {});
        _showMessage(
          added
              ? 'Added "${newItem.title}" to your library!'
              : 'Already in your library',
          added ? Colors.green : Colors.orange,
        );
      }
    } finally {
      _adding.remove(key);
    }
  }

  // Small helper - shows a floating message at the bottom of the screen.
  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Asks "this looks like something you already have — add it anyway?"
  Future<bool> _confirmDuplicate(MediaItem item, List<MediaItem> similar) async {
    final names = similar
        .take(3)
        .map((d) => '• ${d.title} (${d.category.displayName})')
        .join('\n');
    final answer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Already in your library?'),
        content: Text(
          '"${item.title}" looks very similar to:\n\n$names\n\nAdd it anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
    return answer ?? false;
  }


  MediaItem _convertAniListResult(AniListMediaResult result) {
    final country = result.countryOfOrigin;
    final isKoreanOrChinese = country == 'KR' || country == 'CN' || country == 'TW';

    MediaCategory category;
    if (result.type == 'ANIME') {
      category = MediaCategory.anime;
    } else if (result.format == 'NOVEL') {
      category = isKoreanOrChinese
          ? MediaCategory.webNovel
          : MediaCategory.lightNovel;
    } else if (country == 'KR') {
      category = MediaCategory.manhwa;
    } else if (country == 'CN' || country == 'TW') {
      category = MediaCategory.manhua;
    } else {
      category = MediaCategory.manga;
    }

    // Build alternative titles list.
    final altTitles = <String>[];
    if (result.titleNative != null) altTitles.add(result.titleNative!);
    if (result.titleEnglish != null && result.titleEnglish != result.title) {
      altTitles.add(result.titleEnglish!);
    }

    final genres = _mapGenres(result.genres);

    return MediaItem(
      title: result.title,
      category: category,
      status: MediaStatus.planning,
      altTitles: altTitles,
      coverImageUrl: result.coverImageUrl,
      totalProgress: result.chapters ?? result.episodes,
      description: result.description,
      genres: genres,
      apiSource: 'anilist',
      externalApiId: '${result.id}',
    );
  }

  // Convert TMDB result
  MediaItem _convertTMDBResult(TMDBResult result) {
    final isJapanese =
        result.originCountry == 'JP' || result.originalLanguage == 'ja';

    MediaCategory category;
    if (result.isAnimation && isJapanese) {
      category = MediaCategory.anime;
    } else if (result.genreIds.contains(99)) {
      category = MediaCategory.documentary; 
    } else if (result.mediaType == 'movie') {
      category = MediaCategory.movie;
    } else {
      // A TV show - decide by country.
      switch (result.originCountry) {
        case 'KR':
          category = MediaCategory.kdrama;
          break;
        case 'CN':
        case 'TW':
        case 'HK':
          category = MediaCategory.cdrama;
          break;
        case 'JP':
          category = MediaCategory.jdrama;
          break;
        case 'TH':
          category = MediaCategory.thaiDrama;
          break;
        case 'TR':
          category = MediaCategory.turkishDrama;
          break;
        case 'IN':
          category = MediaCategory.indianSeries;
          break;
        default:
          category = MediaCategory.tvShow;
      }
    }

    // Build alt titles.
    final altTitles = <String>[];
    if (result.originalTitle != null && result.originalTitle != result.title) {
      altTitles.add(result.originalTitle!);
    }

    return MediaItem(
      title: result.title,
      category: category,
      status: MediaStatus.planning,
      altTitles: altTitles,
      coverImageUrl: result.fullPosterUrl,
      totalProgress: result.episodeCount,
      description: result.overview,
      apiSource: 'tmdb',
      externalApiId: '${result.mediaType}:${result.id}', 
    );
  }

  // Convert OpenLibrary result

  Future<MediaItem> _convertBookResult(BookResult result) async {
    String? description = result.description;
    if (description == null &&
        result.source == 'openlibrary' &&
        result.id.isNotEmpty) {
      final details = await OpenLibraryService.getWorkDetails(result.id);
      description = details?.description;
    }

    final genres = _mapGenres(result.subjects);

    return MediaItem(
      title: result.title,
      category: MediaCategory.book,
      status: MediaStatus.planning,
      author: result.authorName,
      coverImageUrl: result.coverUrl,
      totalProgress: result.pageCount,
      description: description,
      genres: genres,
      apiSource: result.source, 
      externalApiId: result.id,
    );
  }


  List<Genre> _mapGenres(List<String> genreNames) {
    final mapped = <Genre>[];

    for (final name in genreNames) {
      final lowerName = name.toLowerCase();
      for (final genre in Genre.values) {
        if (lowerName.contains(genre.displayName.toLowerCase())) {
          if (!mapped.contains(genre)) {
            mapped.add(genre);
          }
          break;
        }
      }
    }

    return mapped;
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Add'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // API Source Selector
                SegmentedButton<ApiSource>(
                  segments: const [
                    ButtonSegment(
                      value: ApiSource.anilist,
                      label: Text('AniList'),
                      icon: Icon(Icons.menu_book, size: 16),
                    ),
                    ButtonSegment(
                      value: ApiSource.tmdb,
                      label: Text('TMDB'),
                      icon: Icon(Icons.movie, size: 16),
                    ),
                    ButtonSegment(
                      value: ApiSource.openLibrary,
                      label: Text('Books'),
                      icon: Icon(Icons.book, size: 16),
                    ),
                  ],
                  selected: {_selectedSource},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedSource = newSelection.first;
                      _anilistResults = [];
                      _tmdbResults = [];
                      _bookResults = [];
                      _errorMessage = null;
                    });
                    if (_searchController.text.trim().length >= 2) {
                      _performSearch(_searchController.text.trim());
                    }
                  },
                ),

              // only for Ani list
                if (_selectedSource == ApiSource.anilist) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final mode in AniListMode.values)
                        ChoiceChip(
                          label: Text(_modeLabel(mode)),
                          selected: _anilistMode == mode,
                          onSelected: (_) {
                            setState(() {
                              _anilistMode = mode;
                              _anilistResults = [];
                              _errorMessage = null;
                            });
                            if (_searchController.text.trim().length >= 2) {
                              _performSearch(_searchController.text.trim());
                            }
                          },
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _getSearchHint(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),

          // Results Section
          Expanded(
            child: _buildResultsArea(theme),
          ),
        ],
      ),
    );
  }

  // Search hint
  String _modeLabel(AniListMode mode) {
    if (mode == AniListMode.novel) return 'Novels';
    if (mode == AniListMode.anime) return 'Anime';
    return 'Manga / Manhwa';
  }

  String _getSearchHint() {
    switch (_selectedSource) {
      case ApiSource.anilist:
        if (_anilistMode == AniListMode.novel) {
          return 'Search light novels & web novels...';
        }
        if (_anilistMode == AniListMode.anime) return 'Search anime...';
        return 'Search manga, manhwa, manhua...';
      case ApiSource.tmdb:
        return 'Search movies, TV shows, dramas...';
      case ApiSource.openLibrary:
        return 'Search books, novels...';
    }
  }

  // Results
  Widget _buildResultsArea(ThemeData theme) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red[300]),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading spinner while searching.
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Searching...'),
          ],
        ),
      );
    }

    // Show empty state if no search yet.
    if (_searchController.text.trim().length < 2) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Search for something to add!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Type at least 2 characters to start',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      );
    }

    // Build the results list based on the selected source.
    switch (_selectedSource) {
      case ApiSource.anilist:
        return _buildAniListResults(theme);
      case ApiSource.tmdb:
        return _buildTMDBResults(theme);
      case ApiSource.openLibrary:
        return _buildBookResults(theme);
    }
  }

  // Anilist results list
  Widget _buildAniListResults(ThemeData theme) {
    if (_anilistResults.isEmpty) {
      return _buildNoResults(theme);
    }

    final provider = context.watch<MediaProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _anilistResults.length,
      itemBuilder: (context, index) {
        final result = _anilistResults[index];

        return _buildResultCard(
          theme: theme,
          title: result.title,
          subtitle: [
            if (result.format != null) result.format!,
            if (result.countryOfOrigin != null) result.countryOfOrigin!,
            if (result.status != null) result.status!,
            if (result.chapters != null) '${result.chapters} ch',
            if (result.episodes != null) '${result.episodes} ep',
          ].join(' • '),
          imageUrl: result.coverImageUrl,
          description: result.description,
          genres: result.genres,
          score: result.averageScore != null
              ? '${(result.averageScore! / 20).toStringAsFixed(1)}/5'
              : null,
          alreadyAdded: provider.isInLibrary('anilist', '${result.id}'),
          onAdd: () => _addToLibrary(result),
        );
      },
    );
  }

  // TMDB results list
  Widget _buildTMDBResults(ThemeData theme) {
    if (_tmdbResults.isEmpty) {
      return _buildNoResults(theme);
    }

    final provider = context.watch<MediaProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tmdbResults.length,
      itemBuilder: (context, index) {
        final result = _tmdbResults[index];

        return _buildResultCard(
          theme: theme,
          title: result.title,
          subtitle: [
            result.mediaType == 'movie' ? '🎬 Movie' : '📺 TV Show',
            if (result.releaseDate != null && result.releaseDate!.length >= 4)
              result.releaseDate!.substring(0, 4),
            if (result.originCountry != null) result.originCountry!,
          ].join(' • '),
          imageUrl: result.fullPosterUrl,
          description: result.overview,
          score: result.voteAverage != null
              ? '${(result.voteAverage! / 2).toStringAsFixed(1)}/5'
              : null,
          alreadyAdded:
              provider.isInLibrary('tmdb', '${result.mediaType}:${result.id}'),
          onAdd: () => _addToLibrary(result),
        );
      },
    );
  }

  // Books result list (Google Books / Open Library)
  Widget _buildBookResults(ThemeData theme) {
    if (_bookResults.isEmpty) {
      return _buildNoResults(theme);
    }

    final provider = context.watch<MediaProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _bookResults.length,
      itemBuilder: (context, index) {
        final result = _bookResults[index];

        return _buildResultCard(
          theme: theme,
          title: result.title,
          subtitle: [
            if (result.authorName != null) result.authorName!,
            if (result.year != null) '${result.year}',
            if (result.pageCount != null) '${result.pageCount} pages',
          ].join(' • '),
          imageUrl: result.coverUrl,
          genres: result.subjects.take(5).toList(),
          alreadyAdded: provider.isInLibrary(result.source, result.id),
          onAdd: () => _addToLibrary(result),
        );
      },
    );
  }

  // No results — shown when search returns empty
  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No results found',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // Result card

  Widget _buildResultCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    String? imageUrl,
    String? description,
    List<String>? genres,
    String? score,
    bool alreadyAdded = false,
    required VoidCallback onAdd,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 120,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              title.isNotEmpty ? title[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Subtitle
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Score
                    if (score != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            score,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Description
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Genres/Subjects
                    if (genres != null && genres.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: genres.take(4).map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              g,
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Add Button
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      alreadyAdded
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      color: alreadyAdded
                          ? Colors.green
                          : theme.colorScheme.primary,
                    ),
                    tooltip:
                        alreadyAdded ? 'Already in your library' : 'Add to library',
                    onPressed: onAdd,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}