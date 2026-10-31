import 'package:uuid/uuid.dart';
import 'package:hobbz_place/enums/enums.dart';

class MediaItem {
  final String id;                 // Unique ID (auto-generated)
  String title;                    // Main title
  List<String> altTitles;          // Alternate titles
  MediaCategory category;         // What type (manhwa, movie, etc)
  List<Genre> genres;              // Genre tags (multi select)
  String? author;                  // Author/creator (optional)
  MediaStatus status;              // Reading/watching status
  int currentProgress;             // Current chapter/episode
  int? totalProgress;              // Total chapters/episodes (if known)
  double? rating;                  // Rating 0-5 (optional)
  String? coverImageUrl;           // Cover image URL (optional)
  String? description;             // Synopsis (optional)
  String? notes;                   // Your notes (optional)
  List<String> favQuotes;          // Favorite quotes list
  DateTime dateAdded;              // When you added this
  DateTime lastUpdated;            // When you last changed it
  DateTime? dateCompleted;         // When you finished (optional)
  String? externalApiId;           // API ID for syncing (optional)
  String? apiSource;               // Which API: "anilist", "tmdb", etc.

  //CONSTRUCTOR

  MediaItem({
    String? id,
    required this.title,
    List<String>? altTitles,
    required this.category,
    List<Genre>? genres,
    this.author,
    MediaStatus? status,
    int? currentProgress,
    this.totalProgress,
    this.rating,
    this.coverImageUrl,
    this.description,
    this.notes,
    List<String>? favQuotes,
    DateTime? dateAdded,
    DateTime? lastUpdated,
    this.dateCompleted,
    this.externalApiId,
    this.apiSource,
  })  : id = id ?? const Uuid().v4(),
        altTitles = altTitles ?? [],
        genres = genres ?? [],
        status = status ?? MediaStatus.planning,
        currentProgress = currentProgress ?? 0,
        favQuotes = favQuotes ?? [],
        dateAdded = dateAdded ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  bool get isReading => category.group == 'Reading';
  bool get isWatching => category.group == 'Watching';

  String get progressText {
    final total = totalProgress?.toString() ?? '?';
    return '$currentProgress / $total';
  }

  void touch() {
    lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'altTitles': altTitles,
      'category': category.name,
      'genres': genres.map((g) => g.name).toList(),
      'author': author,
      'status': status.name,
      'currentProgress': currentProgress,
      'totalProgress': totalProgress,
      'rating': rating,
      'coverImageUrl': coverImageUrl,
      'description': description,
      'notes': notes,
      'favQuotes': favQuotes,
      'dateAdded': dateAdded.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
      'externalApiId': externalApiId,
      'apiSource': apiSource,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      altTitles: List<String>.from(map['altTitles'] ?? []),
      category: MediaCategory.values.byName(map['category'] as String),
      genres: (map['genres'] as List<dynamic>?)
          ?.map((g) => Genre.values.byName(g as String))
          .toList() ?? [],
      author: map['author'] as String?,
      status: MediaStatus.values.byName(map['status'] as String),
      currentProgress: map['currentProgress'] as int? ?? 0,
      totalProgress: map['totalProgress'] as int?,

      rating: (map['rating'] as num?)?.toDouble(),
      coverImageUrl: map['coverImageUrl'] as String?,
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      favQuotes: List<String>.from(map['favQuotes'] ?? []),

      dateAdded: DateTime.parse(map['dateAdded'] as String),

      lastUpdated: DateTime.parse(map['lastUpdated'] as String),

      dateCompleted: map['dateCompleted'] != null
          ? DateTime.parse(map['dateCompleted'] as String)
          : null,
      externalApiId: map['externalApiId'] as String?,
      apiSource: map['apiSource'] as String?,
    );
  }

  //copyWith

  MediaItem copyWith({
    String? title,
    List<String>? altTitles,
    MediaCategory? category,
    List<Genre>? genres,
    String? author,
    MediaStatus? status,
    int? currentProgress,
    int? totalProgress,
    double? rating,
    String? coverImageUrl,
    String? description,
    String? notes,
    List<String>? favQuotes,
    DateTime? dateCompleted,
    String? externalApiId,
    String? apiSource,
  }) {
    return MediaItem(
      id: id,
      title: title ?? this.title,
      altTitles: altTitles ?? this.altTitles,
      category: category ?? this.category,
      genres: genres ?? this.genres,
      author: author ?? this.author,
      status: status ?? this.status,
      currentProgress: currentProgress ?? this.currentProgress,
      totalProgress: totalProgress ?? this.totalProgress,
      rating: rating ?? this.rating,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      favQuotes: favQuotes ?? this.favQuotes,
      dateAdded: dateAdded,
      lastUpdated: DateTime.now(),
      dateCompleted: dateCompleted ?? this.dateCompleted,
      externalApiId: externalApiId ?? this.externalApiId,
      apiSource: apiSource ?? this.apiSource,
    );
  }

  @override
  String toString() {
    return 'MediaItem(title: $title, category: ${category.displayName}, '
           'status: ${status.displayName}, progress: $progressText)';
  }
}