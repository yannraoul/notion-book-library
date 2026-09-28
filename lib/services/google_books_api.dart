import 'dart:convert';

import 'package:http/http.dart' as http;

import 'google_books_api_key_storage.dart';

/// Thin wrapper over the Google Books API. `docs/Backlog shelf.md`
/// originally chose no-key usage for basic volume search, but NBLB-15
/// found that anonymous/keyless quota shared globally across every app
/// that skips a key, and easily exhausted (confirmed: every ISBN tried
/// during that investigation came back 429). An API key is optional —
/// entered once in Settings, read fresh on every request from
/// [GoogleBooksApiKeyStorage] — but strongly improves reliability.
/// [BookLookupService] falls back to Open Library whenever this comes
/// back empty or thin, key or no key.
class GoogleBooksApi {
  static const _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  final http.Client _client;
  final GoogleBooksApiKeyStorage _keyStorage;

  GoogleBooksApi({http.Client? client, GoogleBooksApiKeyStorage? keyStorage})
      : _client = client ?? http.Client(),
        _keyStorage = keyStorage ?? GoogleBooksApiKeyStorage();

  Future<GoogleBooksVolume?> lookupIsbn(String isbn) async {
    final results = await _query('isbn:$isbn');
    return results.isEmpty ? null : results.first;
  }

  Future<List<GoogleBooksVolume>> search(String query) => _query(query, maxResults: 5);

  Future<List<GoogleBooksVolume>> _query(String q, {int maxResults = 1}) async {
    final key = await _keyStorage.read();
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'q': q,
      'maxResults': '$maxResults',
      if (key != null && key.isNotEmpty) 'key': key,
    });
    final response = await _client.get(uri);
    if (response.statusCode != 200) return const [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>?;
    if (items == null) return const [];
    return items.cast<Map<String, dynamic>>().map(_parseVolume).toList();
  }

  GoogleBooksVolume _parseVolume(Map<String, dynamic> item) {
    final info = item['volumeInfo'] as Map<String, dynamic>? ?? const {};
    final identifiers = (info['industryIdentifiers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];
    String? isbn13;
    String? isbn10;
    for (final id in identifiers) {
      if (id['type'] == 'ISBN_13') isbn13 = id['identifier'] as String?;
      if (id['type'] == 'ISBN_10') isbn10 = id['identifier'] as String?;
    }
    final imageLinks = info['imageLinks'] as Map<String, dynamic>?;
    final publishedDateRaw = info['publishedDate'] as String?;
    return GoogleBooksVolume(
      title: info['title'] as String? ?? '',
      subtitle: info['subtitle'] as String?,
      authors: (info['authors'] as List<dynamic>?)?.cast<String>() ?? const [],
      isbn13: isbn13,
      isbn10: isbn10,
      pageCount: (info['pageCount'] as num?)?.toInt(),
      publishedDate: _parseDate(publishedDateRaw),
      thumbnailUrl: (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail']) as String?,
      categories: (info['categories'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      if (RegExp(r'^\d{4}$').hasMatch(raw)) return DateTime(int.parse(raw));
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) {
        final parts = raw.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}

class GoogleBooksVolume {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn13;
  final String? isbn10;
  final int? pageCount;
  final DateTime? publishedDate;
  final String? thumbnailUrl;
  final List<String> categories;

  const GoogleBooksVolume({
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn13,
    this.isbn10,
    this.pageCount,
    this.publishedDate,
    this.thumbnailUrl,
    this.categories = const [],
  });

  bool get isThin => pageCount == null && categories.isEmpty && thumbnailUrl == null;
}
