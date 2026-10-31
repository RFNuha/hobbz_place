enum MediaCategory {
  //Reading
  manga,
  manhwa,
  manhua,
  comic,
  lightNovel,
  webNovel,
  book,

  //Watching
  movie,
  kdrama,
  cdrama,
  jdrama,      
  thaiDrama,
  turkishDrama,
  anime,
  tvShow,
  indianSeries,
  documentary;


  String get displayName {
    switch (this) {
      case MediaCategory.manga:        return 'Manga';
      case MediaCategory.manhwa:       return 'Manhwa';
      case MediaCategory.manhua:       return 'Manhua';
      case MediaCategory.comic:        return 'Comic';
      case MediaCategory.lightNovel:   return 'Light Novel';
      case MediaCategory.webNovel:     return 'Web Novel';
      case MediaCategory.book:         return 'Book';
      case MediaCategory.movie:        return 'Movie';
      case MediaCategory.kdrama:       return 'K-Drama';
      case MediaCategory.cdrama:       return 'C-Drama';
      case MediaCategory.jdrama:       return 'J-Drama';
      case MediaCategory.thaiDrama:    return 'Thai Drama';
      case MediaCategory.turkishDrama: return 'Turkish Drama';
      case MediaCategory.anime:        return 'Anime';
      case MediaCategory.tvShow:       return 'TV Show';
      case MediaCategory.indianSeries: return 'Indian Series';
      case MediaCategory.documentary:  return 'Documentary';
    }
  }

  /// Groups categories into Reading or Watching.
  String get group {
    switch (this) {
      case MediaCategory.manga:
      case MediaCategory.manhwa:
      case MediaCategory.manhua:
      case MediaCategory.comic:
      case MediaCategory.lightNovel:
      case MediaCategory.webNovel:
      case MediaCategory.book:
        return 'Reading';
      case MediaCategory.movie:
      case MediaCategory.kdrama:
      case MediaCategory.cdrama:
      case MediaCategory.jdrama:
      case MediaCategory.thaiDrama:
      case MediaCategory.turkishDrama:
      case MediaCategory.anime:
      case MediaCategory.tvShow:
      case MediaCategory.indianSeries:
      case MediaCategory.documentary:
        return 'Watching';
    }
  }

  /// The 4 Library collection names, in the order they appear on screen.
  static const List<String> collectionGroups = [
    'Graphical',
    'Anime',
    'Books',
    'Movies & Shows',
  ];

  /// Which Library collection card this category belongs to.
  String get collectionGroup {
    switch (this) {
      case MediaCategory.manga:
      case MediaCategory.manhwa:
      case MediaCategory.manhua:
      case MediaCategory.comic:
        return 'Graphical';
      case MediaCategory.lightNovel:
      case MediaCategory.webNovel:
      case MediaCategory.book:
        return 'Books';
      case MediaCategory.anime:
        return 'Anime';
      case MediaCategory.movie:
      case MediaCategory.tvShow:
      case MediaCategory.kdrama:
      case MediaCategory.cdrama:
      case MediaCategory.jdrama:
      case MediaCategory.thaiDrama:
      case MediaCategory.turkishDrama:
      case MediaCategory.indianSeries:
      case MediaCategory.documentary:
        return 'Movies & Shows';
    }
  }
}