import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/book.dart';

/// Thin wrapper over the Notion REST API. Covers the connection check
/// (NBLM-3), reading the `Books*`/`Authors*`/`Genres*` databases (NBLM-4),
/// and writing new `Books*`/`Authors*` pages (NBLM-6). Never writes
/// `Status`/`Current page`/`Date started`/`Date finished`/`Rating` on
/// `Books*` — that stays Habits' job forever — and never creates a new
/// `Genres*` row, since that list is fixed/closed.
class NotionApi {
  static const _baseUrl = 'https://api.notion.com/v1';
  // Pinned so response shapes don't shift under us without a deliberate bump.
  static const _notionVersion = '2022-06-28';

  final http.Client _client;

  NotionApi({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Notion-Version': _notionVersion,
        'Content-Type': 'application/json',
      };

  /// Validates a token and returns the connected workspace's bot identity —
  /// `GET /v1/users/me`. Throws [NotionApiException] on any non-2xx
  /// response (401 means the token itself is invalid/revoked).
  Future<NotionUser> getMe(String token) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: _headers(token),
    );
    _throwIfError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final bot = body['bot'] as Map<String, dynamic>?;
    return NotionUser(
      name: body['name'] as String? ?? '',
      workspaceName: bot?['workspace_name'] as String? ?? '',
    );
  }

  /// Lists every database shared with this integration —
  /// `POST /v1/search` filtered to `object: "database"`.
  Future<List<NotionDatabaseSummary>> searchDatabases(String token) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/search'),
      headers: _headers(token),
      body: jsonEncode({
        'filter': {'value': 'database', 'property': 'object'},
      }),
    );
    _throwIfError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>;
    return results
        .cast<Map<String, dynamic>>()
        .map((db) => NotionDatabaseSummary(id: db['id'] as String, title: _plainTitle(db)))
        .toList();
  }

  /// All rows of the `Books*` database.
  Future<List<NotionBookRecord>> queryBooks(String token, String booksDbId) async {
    final pages = await _queryAll(token, booksDbId, body: const {});
    return pages.map(_parseBook).toList();
  }

  /// `id -> Name` for every row of a small reference database — used for
  /// both `Authors*` and `Genres*` (identical shape: a `Name` title
  /// property plus a `Books` back-relation, nothing else Shelf reads).
  Future<Map<String, String>> queryRelationNames(String token, String databaseId) async {
    final pages = await _queryAll(token, databaseId, body: const {});
    return {for (final page in pages) page['id'] as String: _plainTitle(page['properties']['Name'])};
  }

  /// Notion's built-in vector icons (not emoji/file) — same ones already on
  /// every row Yann created from his own templates, confirmed live against
  /// his workspace (`book-closed`/gray on `Books*`, `user`/gray on
  /// `Authors*`). Setting `icon.type: "icon"` works even pinned to the
  /// 2022-06-28 API version — confirmed live via a direct PATCH.
  static const _bookIcon = {
    'type': 'icon',
    'icon': {'name': 'book-closed', 'color': 'gray'},
  };
  static const _authorIcon = {
    'type': 'icon',
    'icon': {'name': 'user', 'color': 'gray'},
  };

  /// Creates a new page in [databaseId] with the given Notion [properties]
  /// map (already shaped per-property, e.g. via the `_...Property` helpers
  /// below) — `POST /v1/pages`. Returns the new page's id.
  Future<String> createPage(
    String token,
    String databaseId,
    Map<String, dynamic> properties, {
    Map<String, dynamic>? icon,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/pages'),
      headers: _headers(token),
      body: jsonEncode({
        'parent': {'database_id': databaseId},
        'properties': properties,
        'icon': ?icon,
      }),
    );
    _throwIfError(response);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['id'] as String;
  }

  /// Creates a bare title-only page — used for a new `Authors*` row.
  /// `Genres*` is never created this way; that list is fixed/closed.
  Future<String> createRelationPage(String token, String databaseId, String name) {
    return createPage(token, databaseId, {'Name': _titleProperty(name)}, icon: _authorIcon);
  }

  /// Creates a new `Books*` row. Only ever writes the fields Shelf owns
  /// (see the class doc comment) — [authorPageIds]/[genrePageIds] must
  /// already be resolved relation ids, not names.
  Future<String> createBookPage(
    String token, {
    required String booksDbId,
    required String title,
    String? subtitle,
    String? isbn,
    int? pages,
    DateTime? publishedDate,
    String? coverUrl,
    String? apiCategories,
    List<String> authorPageIds = const [],
    List<String> genrePageIds = const [],
  }) {
    return createPage(token, booksDbId, {
      'Name': _titleProperty(title),
      'Subtitle': _richTextProperty(subtitle),
      'ISBN': _richTextProperty(isbn),
      'Pages': _numberProperty(pages),
      'Date published': _dateProperty(publishedDate),
      'Cover': _externalFileProperty(coverUrl),
      'API categories/subjects': _richTextProperty(apiCategories),
      'Authors': _relationProperty(authorPageIds),
      'Genres': _relationProperty(genrePageIds),
    }, icon: _bookIcon);
  }

  Map<String, dynamic> _titleProperty(String text) => {
        'title': [
          {
            'text': {'content': text},
          },
        ],
      };

  Map<String, dynamic> _richTextProperty(String? text) => {
        'rich_text': text == null || text.isEmpty
            ? []
            : [
                {
                  'text': {'content': text},
                },
              ],
      };

  Map<String, dynamic> _numberProperty(num? value) => {'number': value};

  Map<String, dynamic> _dateProperty(DateTime? date) => {
        'date': date == null
            ? null
            : {'start': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'},
      };

  Map<String, dynamic> _relationProperty(List<String> pageIds) => {
        'relation': pageIds.map((id) => {'id': id}).toList(),
      };

  /// Cover can only be written as an `external` file — Shelf has no backend
  /// to host an uploaded image against, so callers only ever pass a URL.
  Map<String, dynamic> _externalFileProperty(String? url) => {
        'files': url == null || url.isEmpty
            ? []
            : [
                {
                  'name': 'cover',
                  'type': 'external',
                  'external': {'url': url},
                },
              ],
      };

  /// Pages through `POST /v1/databases/{id}/query` until `has_more` is
  /// false, returning raw page objects.
  Future<List<Map<String, dynamic>>> _queryAll(
    String token,
    String databaseId, {
    required Map<String, dynamic> body,
  }) async {
    final results = <Map<String, dynamic>>[];
    String? cursor;
    do {
      final requestBody = {...body};
      if (cursor != null) requestBody['start_cursor'] = cursor;
      final response = await _client.post(
        Uri.parse('$_baseUrl/databases/$databaseId/query'),
        headers: _headers(token),
        body: jsonEncode(requestBody),
      );
      _throwIfError(response);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      results.addAll((decoded['results'] as List<dynamic>).cast<Map<String, dynamic>>());
      cursor = decoded['has_more'] == true ? decoded['next_cursor'] as String? : null;
    } while (cursor != null);
    return results;
  }

  NotionBookRecord _parseBook(Map<String, dynamic> page) {
    final props = page['properties'] as Map<String, dynamic>;
    final dateStarted = props['Date started']?['date']?['start'] as String?;
    final dateFinished = props['Date finished']?['date']?['start'] as String?;
    final datePublished = props['Date published']?['date']?['start'] as String?;
    return NotionBookRecord(
      id: page['id'] as String,
      name: _plainTitle({'title': props['Name']?['title']}),
      subtitle: _plainRichText(props['Subtitle']),
      authorIds: _relationIds(props['Authors']),
      isbn: _plainRichText(props['ISBN']),
      genreIds: _relationIds(props['Genres']),
      coverUrl: _firstFileUrl(props['Cover']),
      apiCategories: _plainRichText(props['API categories/subjects']),
      totalPages: (props['Pages']?['number'] as num?)?.toDouble(),
      datePublished: datePublished != null ? DateTime.parse(datePublished) : null,
      status: BookStatus.fromNotionName(props['Status']?['status']?['name'] as String?),
      currentPage: (props['Current page']?['number'] as num?)?.toDouble(),
      dateStarted: dateStarted != null ? DateTime.parse(dateStarted) : null,
      dateFinished: dateFinished != null ? DateTime.parse(dateFinished) : null,
      rating: _selectName(props['Rating'])?.length,
    );
  }

  String? _plainRichText(Map<String, dynamic>? richTextProperty) {
    final richText = richTextProperty?['rich_text'] as List<dynamic>?;
    if (richText == null || richText.isEmpty) return null;
    return richText.cast<Map<String, dynamic>>().map((segment) => segment['plain_text'] as String? ?? '').join();
  }

  List<String> _relationIds(Map<String, dynamic>? relationProperty) {
    final relations = relationProperty?['relation'] as List<dynamic>?;
    if (relations == null) return const [];
    return relations.cast<Map<String, dynamic>>().map((relation) => relation['id'] as String).toList();
  }

  /// First file's URL, whether Notion-hosted (`type: "file"`, a temporary
  /// signed S3 URL — expiry is embedded in the URL's own query string) or
  /// `external` (permanent).
  String? _firstFileUrl(Map<String, dynamic>? filesProperty) {
    final files = filesProperty?['files'] as List<dynamic>?;
    if (files == null || files.isEmpty) return null;
    final file = files.first as Map<String, dynamic>;
    return switch (file['type']) {
      'file' => (file['file'] as Map<String, dynamic>?)?['url'] as String?,
      'external' => (file['external'] as Map<String, dynamic>?)?['url'] as String?,
      _ => null,
    };
  }

  String? _selectName(Map<String, dynamic>? selectProperty) {
    final select = selectProperty?['select'] as Map<String, dynamic>?;
    return select?['name'] as String?;
  }

  String _plainTitle(Map<String, dynamic> withTitle) {
    final title = withTitle['title'] as List<dynamic>?;
    if (title == null || title.isEmpty) return '';
    return title
        .cast<Map<String, dynamic>>()
        .map((segment) => segment['plain_text'] as String? ?? '')
        .join();
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401) {
      throw const NotionApiException('Invalid or revoked Notion token.', statusCode: 401);
    }
    String message = 'Notion API error (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['message'] is String) message = body['message'] as String;
    } catch (_) {
      // Response body wasn't JSON — keep the generic status-code message.
    }
    throw NotionApiException(message, statusCode: response.statusCode);
  }
}

class NotionUser {
  final String name;
  final String workspaceName;

  const NotionUser({required this.name, required this.workspaceName});
}

class NotionDatabaseSummary {
  final String id;
  final String title;

  const NotionDatabaseSummary({required this.id, required this.title});
}

/// A row from the `Books*` database — raw parse, not yet decoupled from
/// Notion's shape. `authorIds`/`genreIds` are raw relation ids (unresolved
/// `Authors*`/`Genres*` page ids); `BooksRepository` resolves them to
/// display names via [NotionApi.queryRelationNames] and produces the
/// app-level [Book].
class NotionBookRecord {
  final String id;
  final String name;
  final String? subtitle;
  final List<String> authorIds;
  final String? isbn;
  final List<String> genreIds;
  final String? coverUrl;
  final String? apiCategories;
  final double? totalPages;
  final DateTime? datePublished;
  final BookStatus? status;
  final double? currentPage;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final int? rating;

  const NotionBookRecord({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.authorIds,
    required this.isbn,
    required this.genreIds,
    required this.coverUrl,
    required this.apiCategories,
    required this.totalPages,
    required this.datePublished,
    required this.status,
    required this.currentPage,
    required this.dateStarted,
    required this.dateFinished,
    required this.rating,
  });
}

class NotionApiException implements Exception {
  final String message;
  final int statusCode;

  const NotionApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}
