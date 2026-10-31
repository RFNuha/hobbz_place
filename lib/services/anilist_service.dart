import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// AniListMediaResult — a simple data class for search results
// This holds the data we get back from AniList for each search result.

class AniListMediaResult {
  final int id; // AniList's unique ID for this media

  final String title; // The English or Romaji title.

  final String? titleNative; // The native (Japanese/Korean/Chinese) title.

  final String? titleEnglish; // The English title (if different from romaji).

  final String type; // "MANGA" or "ANIME".

  final String? format;
  // More specific: "MANGA", "MANHWA", "MANHUA", "NOVEL",
  //   "TV", "MOVIE", "OVA", "ONA", etc.

  final String? status; // "FINISHED", "RELEASING", "NOT_YET_RELEASED", "CANCELLED".

  final int? chapters; // Total chapters (for manga). Null if still publishing.

  final int? episodes; // Total episodes (for anime). Null if still airing.

  final int? volumes; // Total volumes (for manga/light novels).

  final String? coverImageUrl; // URL to the cover image.

  final String? description; // Synopsis/description text.

  final List<String> genres; // Genre names like ("Action", "Fantasy", "Adventure").

  final double? averageScore; // Average user score (0-100).

  final String? countryOfOrigin;
  // 2 letter country code: "JP" (Japan), "KR" (Korea), "CN" (China), "TW" (Taiwan). AniList has NO "manhwa" or "manhua" format, they are all just "MANGA". The country is the only way to tell them apart, KR → manhwa,  CN/TW → manhua,  JP → manga.

  // Constructor with named parameters.
  AniListMediaResult({
    required this.id,
    required this.title,
    this.titleNative,
    this.titleEnglish,
    required this.type,
    this.format,
    this.status,
    this.chapters,
    this.episodes,
    this.volumes,
    this.coverImageUrl,
    this.description,
    this.genres = const [],
    this.averageScore,
    this.countryOfOrigin,
  });


  factory AniListMediaResult.fromJson(Map<String, dynamic> json) {
    final titleData = json['title'] as Map<String, dynamic>? ?? {};

    // Pick the best title - prefer English, fall back to Romaji.
    final bestTitle = (titleData['english'] as String?) ??
        (titleData['romaji'] as String?) ??
        'Unknown Title';

    // Cover image is also nested.
    final coverData = json['coverImage'] as Map<String, dynamic>?;
    final genreList = (json['genres'] as List<dynamic>?)
            ?.map((g) => g.toString())
            .toList() ??
        [];

    return AniListMediaResult(
      id: json['id'] as int,
      title: bestTitle,
      titleNative: titleData['native'] as String?,
      titleEnglish: titleData['english'] as String?,
      type: json['type'] as String? ?? 'MANGA',
      format: json['format'] as String?,
      status: json['status'] as String?,
      chapters: json['chapters'] as int?,
      episodes: json['episodes'] as int?,
      volumes: json['volumes'] as int?,
      coverImageUrl: coverData?['large'] as String? ?? coverData?['medium'] as String?,
      description: _cleanDescription(json['description'] as String?),
      genres: genreList,
      averageScore: (json['averageScore'] as num?)?.toDouble(),
      countryOfOrigin: json['countryOfOrigin'] as String?,
    );
  }

  static String? _cleanDescription(String? html) {
    if (html == null) return null;
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }
}

// AniListService — makes API calls to AniList
class AniListService {
  static const String _endpoint = 'https://graphql.anilist.co';

  // Search AniList for manga/anime matching a query

  static Future<List<AniListMediaResult>> search(
    String query, {
    String type = 'MANGA',
    String? format,
    int page = 1,
    int perPage = 15,
  }) async {

    const graphqlQuery = r'''
      query ($search: String, $type: MediaType, $format: MediaFormat, $page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          pageInfo {
            total
            currentPage
            lastPage
            hasNextPage
          }
          media(search: $search, type: $type, format: $format, sort: SEARCH_MATCH) {
            id
            title {
              romaji
              english
              native
            }
            type
            format
            status
            chapters
            episodes
            volumes
            coverImage {
              large
              medium
            }
            description(asHtml: false)
            genres
            averageScore
            countryOfOrigin
          }
        }
      }
    ''';

    // Variables
    final variables = <String, dynamic>{
      'search': query,
      'type': type,
      'page': page,
      'perPage': perPage,
      'format': ?format,
    };

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': graphqlQuery,
          'variables': variables,
        }),
      );

      // Check response
      if (response.statusCode != 200) {
        throw Exception('AniList API error: ${response.statusCode} - ${response.body}');
      }

      // Parse the response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pageData = data['data']?['Page'] as Map<String, dynamic>?;
      final mediaList = pageData?['media'] as List<dynamic>? ?? [];

      // Convert
      return mediaList
          .map((json) => AniListMediaResult.fromJson(json as Map<String, dynamic>))
          .toList();

    } catch (e) {
      debugPrint('AniList search error: $e');
      return [];
    }
  }

  //  Get by ID — fetches a single media item by its AniList ID

  static Future<AniListMediaResult?> getById(int id) async {
    const graphqlQuery = r'''
      query ($id: Int) {
        Media(id: $id) {
          id
          title {
            romaji
            english
            native
          }
          type
          format
          status
          chapters
          episodes
          volumes
          coverImage {
            large
            medium
          }
          description(asHtml: false)
          genres
          averageScore
          countryOfOrigin
        }
      }
    ''';

    final variables = {'id': id};

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': graphqlQuery,
          'variables': variables,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('AniList API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final mediaData = data['data']?['Media'] as Map<String, dynamic>?;

      if (mediaData == null) return null;

      return AniListMediaResult.fromJson(mediaData);
    } catch (e) {
      debugPrint('AniList getById error: $e');
      return null;
    }
  }
}