import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hobbz_place/services/database_service.dart';

// TMDB Result

class TMDBResult {
  final int id;
  final String title;
  final String? originalTitle;
  final String mediaType;
  final String? overview;
  final String? posterPath;
  final String? releaseDate;
  final double? voteAverage;
  final int? episodeCount;
  final int? seasonCount;
  final List<int> genreIds;
  final String? originCountry;
  final String? originalLanguage;

  TMDBResult({
    required this.id,
    required this.title,
    this.originalTitle,
    required this.mediaType,
    this.overview,
    this.posterPath,
    this.releaseDate,
    this.voteAverage,
    this.episodeCount,
    this.seasonCount,
    this.genreIds = const [],
    this.originCountry,
    this.originalLanguage,
  });

  // Full poster URL

  String? get fullPosterUrl {
    if (posterPath == null) return null;
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }

  factory TMDBResult.fromJson(Map<String, dynamic> json, String mediaType) {
    // TV shows use 'name' instead of 'title' for the display name.
    final title = json['title'] as String? ?? json['name'] as String? ?? 'Unknown';
    final originalTitle = json['original_title'] as String? ?? json['original_name'] as String?;

    // TV shows use 'first_air_date' instead of 'release_date'.
    final date = json['release_date'] as String? ?? json['first_air_date'] as String?;

    // Origin country comes as a List like ("KR", "US").
    final countries = json['origin_country'] as List<dynamic>?;
    final originCountry = countries != null && countries.isNotEmpty
        ? countries.first.toString()
        : null;

    // Genre IDs come as a List of ints.
    final genres = (json['genre_ids'] as List<dynamic>?)
            ?.map((id) => id as int)
            .toList() ??
        [];

    return TMDBResult(
      id: json['id'] as int,
      title: title,
      originalTitle: originalTitle,
      mediaType: mediaType,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      releaseDate: date,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      episodeCount: json['number_of_episodes'] as int?,
      seasonCount: json['number_of_seasons'] as int?,
      genreIds: genres,
      originCountry: originCountry,
      originalLanguage: json['original_language'] as String?,
    );
  }

  // isAnimation — TMDB genre ID 16 means "Animation"
  bool get isAnimation => genreIds.contains(16);
}

// Makes API calls to TMDB

class TMDBService {
  // API Key

  static String _apiKey = '';

  static const String _baseUrl = 'https://api.themoviedb.org/3';

  // Set API Key
static Future<void> setApiKey(String key) async {
  _apiKey = key.trim();
  await DatabaseService.instance.putSetting('tmdbApiKey', _apiKey);
  }

  // Load saved key
  static void loadSavedApiKey() {
    _apiKey = DatabaseService.instance.getSetting('tmdbApiKey', defaultValue: '') as String;
  }

  static bool get hasApiKey => _apiKey.isNotEmpty;

  // Search movies
  static Future<List<TMDBResult>> searchMovies(String query, {int page = 1}) async {
    if (_apiKey.isEmpty) {
      debugPrint('TMDB API key not set');
      return [];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/search/movie?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&page=$page',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('TMDB search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((json) => TMDBResult.fromJson(json as Map<String, dynamic>, 'movie'))
          .toList();

    } catch (e) {
      debugPrint('TMDB movie search error: $e');
      return [];
    }
  }

  // Search tv shows
  static Future<List<TMDBResult>> searchTV(String query, {int page = 1}) async {
    if (_apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/search/tv?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&page=$page',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('TMDB search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      return results
          .map((json) => TMDBResult.fromJson(json as Map<String, dynamic>, 'tv'))
          .toList();

    } catch (e) {
      debugPrint('TMDB TV search error: $e');
      return [];
    }
  }

  // Search both

  static Future<List<TMDBResult>> searchMulti(String query, {int page = 1}) async {
    if (_apiKey.isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/search/multi?api_key=$_apiKey&query=${Uri.encodeComponent(query)}&page=$page',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('TMDB search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];

      // Filter to only movies and TV shows
      return results
          .where((json) {
            final type = json['media_type'] as String?;
            return type == 'movie' || type == 'tv';
          })
          .map((json) => TMDBResult.fromJson(
              json as Map<String, dynamic>,
              json['media_type'] as String? ?? 'movie',
          ))
          .toList();

    } catch (e) {
      debugPrint('TMDB multi search error: $e');
      return [];
    }
  }

  // TV Details

  static Future<TMDBResult?> getTVDetails(int tvId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/tv/$tvId?api_key=$_apiKey');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('TMDB details error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return TMDBResult(
        id: data['id'] as int,
        title: data['name'] as String? ?? 'Unknown',
        originalTitle: data['original_name'] as String?,
        mediaType: 'tv',
        overview: data['overview'] as String?,
        posterPath: data['poster_path'] as String?,
        releaseDate: data['first_air_date'] as String?,
        voteAverage: (data['vote_average'] as num?)?.toDouble(),
        episodeCount: data['number_of_episodes'] as int?,
        seasonCount: data['number_of_seasons'] as int?,
        genreIds: (data['genre_ids'] as List<dynamic>?)
                ?.map((id) => id as int)
                .toList() ??
            (data['genres'] as List<dynamic>?)
                ?.map((g) => (g as Map<String, dynamic>)['id'] as int)
                .toList() ??
            [],
        originCountry: (data['origin_country'] as List<dynamic>?)?.isNotEmpty == true
            ? (data['origin_country'] as List<dynamic>).first.toString()
            : null,
      );

    } catch (e) {
      debugPrint('TMDB TV details error: $e');
      return null;
    }
  }


  // Movie Details
  static Future<TMDBResult?> getMovieDetails(int movieId) async {
    if (_apiKey.isEmpty) return null;

    try {
      final uri = Uri.parse('$_baseUrl/movie/$movieId?api_key=$_apiKey');
      final response = await http.get(uri);

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return TMDBResult(
        id: data['id'] as int,
        title: data['title'] as String? ?? 'Unknown',
        originalTitle: data['original_title'] as String?,
        mediaType: 'movie',
        overview: data['overview'] as String?,
        posterPath: data['poster_path'] as String?,
        releaseDate: data['release_date'] as String?,
        voteAverage: (data['vote_average'] as num?)?.toDouble(),
        genreIds: (data['genres'] as List<dynamic>?)
                ?.map((g) => (g as Map<String, dynamic>)['id'] as int)
                .toList() ??
            [],
      );

    } catch (e) {
      debugPrint('TMDB movie details error: $e');
      return null;
    }
  }
}