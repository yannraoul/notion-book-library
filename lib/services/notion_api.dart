import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper over the Notion REST API. Covers the connection check
/// only for now (NBLM-3) — reading/writing the `Books`/`Authors`/`Genres`
/// databases lands with the milestone that adds real book data.
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

class NotionApiException implements Exception {
  final String message;
  final int statusCode;

  const NotionApiException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}
