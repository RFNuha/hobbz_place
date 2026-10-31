import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// OpenLibraryResult 
class OpenLibraryResult {
  final String key;
  final String title;
  final String? authorName;
  final int? coverId;
  final int? firstPublishYear;
  final int? pageCount;
  final List<String> subjects;
  final String? isbn;
  final int? editionCount;
  final String? description;

  OpenLibraryResult({
    required this.key,
    required this.title,
    this.authorName,
    this.coverId,
    this.firstPublishYear,
    this.pageCount,
    this.subjects = const [],
    this.isbn,
    this.editionCount,
    this.description,
  });


  String? get fullCoverUrl {
    if (coverId == null) return null;
    return 'https://covers.openlibrary.org/b/id/$coverId-L.jpg';
  }


  factory OpenLibraryResult.fromJson(Map<String, dynamic> json) {
    final authors = json['author_name'] as List<dynamic>?;
    final authorName = authors != null && authors.isNotEmpty
        ? authors.first.toString()
        : null;

    final coverId = json['cover_i'] as int?;

    final subjectList = (json['subject'] as List<dynamic>?)
            ?.take(10)
            .map((s) => s.toString())
            .toList() ??
        [];

    // ISBN list
    final isbns = json['isbn'] as List<dynamic>?;
    final isbn = isbns != null && isbns.isNotEmpty
        ? isbns.first.toString()
        : null;

    return OpenLibraryResult(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      authorName: authorName,
      coverId: coverId,
      firstPublishYear: json['first_publish_year'] as int?,
      pageCount: json['number_of_pages_median'] as int?,
      subjects: subjectList,
      isbn: isbn,
      editionCount: json['edition_count'] as int?,
    );
  }
}

// OpenLibraryService

class OpenLibraryService {
  static const String _baseUrl = 'https://openlibrary.org';
  static const String _searchUrl = 'https://openlibrary.org/search.json';

  // Search

  static Future<List<OpenLibraryResult>> search(
    String query, {
    int page = 1,
    int limit = 15,
  }) async {
    try {
      // Build the search URL.
      // Open Library's search API is straightforward: https://openlibrary.org/search.json?q=<query>&page=1&limit=15
      final uri = Uri.parse(
        '$_searchUrl?q=${Uri.encodeComponent(query)}&page=$page&limit=$limit'
        '&fields=key,title,author_name,cover_i,first_publish_year,'
        'number_of_pages_median,subject,isbn,edition_count',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Open Library search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];
      return docs
          .map((json) => OpenLibraryResult.fromJson(json as Map<String, dynamic>))
          .toList();

    } catch (e) {
      debugPrint('Open Library search error: $e');
      return [];
    }
  }

  // Get Work Details

  static Future<OpenLibraryResult?> getWorkDetails(String workKey) async {
    try {
      // The work details URL looks like: https://openlibrary.org/works/OL45883W.json
      final uri = Uri.parse('$_baseUrl$workKey.json');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Open Library work details error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      String? description;
      final descField = data['description'];
      if (descField is String) {
        description = descField;
      } else if (descField is Map) {
        description = descField['value'] as String?;
      }

      final subjects = <String>[];
      final subjectField = data['subjects'] as List<dynamic>?;
      if (subjectField != null) {
        for (final s in subjectField.take(10)) {
          if (s is String) {
            subjects.add(s);
          } else if (s is Map) {
            subjects.add(s['name']?.toString() ?? '');
          }
        }
      }

      return OpenLibraryResult(
        key: data['key'] as String? ?? workKey,
        title: data['title'] as String? ?? 'Unknown',
        description: description,
        subjects: subjects,
      );

    } catch (e) {
      debugPrint('Open Library work details error: $e');
      return null;
    }
  }

  // Search by Author
  static Future<List<OpenLibraryResult>> searchByAuthor(
    String authorName, {
    int page = 1,
    int limit = 15,
  }) async {
    try {
      final uri = Uri.parse(
        '$_searchUrl?author=${Uri.encodeComponent(authorName)}'
        '&page=$page&limit=$limit'
        '&fields=key,title,author_name,cover_i,first_publish_year,'
        'number_of_pages_median,subject,isbn,edition_count',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Open Library author search error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];

      return docs
          .map((json) => OpenLibraryResult.fromJson(json as Map<String, dynamic>))
          .toList();

    } catch (e) {
      debugPrint('Open Library author search error: $e');
      return [];
    }
  }
}