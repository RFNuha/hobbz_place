import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hobbz_place/services/openlibrary_service.dart';

// Book Result
class BookResult {
  final String source;

  final String id;
  final String title;
  final String? authorName;
  final String? coverUrl;
  final int? year;
  final int? pageCount;
  final List<String> subjects; // categories / genres
  final String? description;

  BookResult({
    required this.source,
    required this.id,
    required this.title,
    this.authorName,
    this.coverUrl,
    this.year,
    this.pageCount,
    this.subjects = const [],
    this.description,
  });

  // fromOpenLibrary
  factory BookResult.fromOpenLibrary(OpenLibraryResult r) {
    return BookResult(
      source: 'openlibrary',
      id: r.key,
      title: r.title,
      authorName: r.authorName,
      coverUrl: r.fullCoverUrl,
      year: r.firstPublishYear,
      pageCount: r.pageCount,
      subjects: r.subjects,
      description: r.description,
    );
  }

  // fromGoogleJson
  factory BookResult.fromGoogleJson(Map<String, dynamic> json) {
    final info = (json['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final authors = (info['authors'] as List<dynamic>?)
        ?.map((a) => a.toString())
        .toList();
    final authorName =
        (authors != null && authors.isNotEmpty) ? authors.join(', ') : null;
    final dateText = info['publishedDate'] as String?;
    final year = (dateText != null && dateText.length >= 4)
        ? int.tryParse(dateText.substring(0, 4))
        : null;

    final subjects = <String>[];
    final cats = info['categories'] as List<dynamic>?;
    if (cats != null) {
      for (final c in cats) {
        for (final part in c.toString().split('/')) {
          final cleaned = part.trim();
          if (cleaned.isNotEmpty && !subjects.contains(cleaned)) {
            subjects.add(cleaned);
          }
        }
      }
    }

    return BookResult(
      source: 'googlebooks',
      id: json['id'] as String? ?? '',
      title: info['title'] as String? ?? 'Unknown',
      authorName: authorName,
      coverUrl: _cleanCoverUrl(info['imageLinks'] as Map<String, dynamic>?),
      year: year,
      pageCount: info['pageCount'] as int?,
      subjects: subjects,
      description: _stripHtml(info['description'] as String?),
    );
  }

  static String? _stripHtml(String? html) {
    if (html == null) return null;
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }


  static String? _cleanCoverUrl(Map<String, dynamic>? links) {
    if (links == null) return null;

    // Prefer the biggest picture Google gave us.
    String? url = (links['extraLarge'] ??
        links['large'] ??
        links['medium'] ??
        links['small'] ??
        links['thumbnail'] ??
        links['smallThumbnail']) as String?;
    if (url == null) return null;

    url = url.replaceFirst('http://', 'https://');
    url = url.replaceAll('&edge=curl', '');
    return url;
  }
}

// GoogleBooksService
class GoogleBooksService {
  static const String _searchUrl = 'https://www.googleapis.com/books/v1/volumes';

  // Search
  static Future<List<BookResult>> search(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse(
        '$_searchUrl?q=${Uri.encodeComponent(query)}'
        '&maxResults=$limit'
        '&printType=books'
        '&fields=items(id,volumeInfo(title,authors,imageLinks,publishedDate,'
        'pageCount,categories,description))',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Google Books error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      final results = <BookResult>[];
      final seen = <String>{};

      for (final raw in items) {
        final book = BookResult.fromGoogleJson(raw as Map<String, dynamic>);
        if (book.id.isEmpty) continue;

        final dedupeKey =
            '${book.title.toLowerCase().trim()}|${(book.authorName ?? '').toLowerCase().trim()}';
        if (seen.contains(dedupeKey)) continue; // already have this book
        seen.add(dedupeKey);

        results.add(book);
      }

      return results;
    } catch (e) {
      debugPrint('Google Books search error: $e');
      return [];
    }
  }
}