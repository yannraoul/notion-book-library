import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper over the Open Library API — no key ever needed, used as
/// the fallback source in the identification pipeline for its coverage
/// of older/obscure titles Google Books misses. Response shapes
/// confirmed live against real ISBNs during development (see NBLM-7's
/// planning notes) rather than assumed from docs.
class OpenLibraryApi {
  static const _baseUrl = 'https://openlibrary.org';

  final http.Client _client;

  OpenLibraryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<OpenLibraryVolume?> lookupIsbn(String isbn) async {
    final uri = Uri.parse('$_baseUrl/api/books').replace(queryParameters: {
      'bibkeys': 'ISBN:$isbn',
      'format': 'json',
      'jscmd': 'data',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) return null;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final entry = body['ISBN:$isbn'] as Map<String, dynamic>?;
    if (entry == null) return null;
    return _parseVolume(entry);
  }

  Future<List<OpenLibraryVolume>> search(String query) async {
    final uri = Uri.parse('$_baseUrl/search.json').replace(queryParameters: {
      'q': query,
      'limit': '5',
      'fields': 'title,author_name,isbn,cover_i,first_publish_year,subject,number_of_pages_median',
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) return const [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = body['docs'] as List<dynamic>?;
    if (docs == null) return const [];
    return docs.cast<Map<String, dynamic>>().map(_parseSearchDoc).toList();
  }

  OpenLibraryVolume _parseVolume(Map<String, dynamic> entry) {
    final authors = (entry['authors'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map((a) => a['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        const [];
    final identifiers = entry['identifiers'] as Map<String, dynamic>?;
    final isbn13 = (identifiers?['isbn_13'] as List<dynamic>?)?.cast<String>().firstOrNull;
    final isbn10 = (identifiers?['isbn_10'] as List<dynamic>?)?.cast<String>().firstOrNull;
    final subjects = (entry['subjects'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>()
            .map((s) => s['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList() ??
        const [];
    final cover = entry['cover'] as Map<String, dynamic>?;
    return OpenLibraryVolume(
      title: entry['title'] as String? ?? '',
      subtitle: entry['subtitle'] as String?,
      authors: authors,
      isbn13: isbn13,
      isbn10: isbn10,
      pages: (entry['number_of_pages'] as num?)?.toInt(),
      publishedDate: _parseDate(entry['publish_date'] as String?),
      coverUrl: cover?['medium'] as String? ?? cover?['large'] as String?,
      subjects: subjects,
    );
  }

  OpenLibraryVolume _parseSearchDoc(Map<String, dynamic> doc) {
    final coverId = doc['cover_i'] as int?;
    final year = doc['first_publish_year'] as int?;
    return OpenLibraryVolume(
      title: doc['title'] as String? ?? '',
      subtitle: null,
      authors: (doc['author_name'] as List<dynamic>?)?.cast<String>() ?? const [],
      isbn13: (doc['isbn'] as List<dynamic>?)?.cast<String>().where((i) => i.length == 13).firstOrNull,
      isbn10: (doc['isbn'] as List<dynamic>?)?.cast<String>().where((i) => i.length == 10).firstOrNull,
      pages: (doc['number_of_pages_median'] as num?)?.toInt(),
      publishedDate: year != null ? DateTime(year) : null,
      coverUrl: coverId != null ? 'https://covers.openlibrary.org/b/id/$coverId-M.jpg' : null,
      subjects: (doc['subject'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final yearMatch = RegExp(r'\d{4}').firstMatch(raw);
    if (yearMatch == null) return null;
    try {
      return DateTime(int.parse(yearMatch.group(0)!));
    } catch (_) {
      return null;
    }
  }
}

class OpenLibraryVolume {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn13;
  final String? isbn10;
  final int? pages;
  final DateTime? publishedDate;
  final String? coverUrl;
  final List<String> subjects;

  const OpenLibraryVolume({
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn13,
    this.isbn10,
    this.pages,
    this.publishedDate,
    this.coverUrl,
    this.subjects = const [],
  });
}
