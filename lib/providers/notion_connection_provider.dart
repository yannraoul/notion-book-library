import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/books_repository.dart';
import '../services/notion_api.dart';
import '../services/notion_token_storage.dart';

sealed class NotionConnectionState {
  const NotionConnectionState();
}

class NotionDisconnected extends NotionConnectionState {
  const NotionDisconnected();
}

class NotionConnecting extends NotionConnectionState {
  const NotionConnecting();
}

class NotionConnected extends NotionConnectionState {
  final String token;
  final String workspaceName;
  final List<NotionDatabaseSummary> databases;
  final String? booksDatabaseId;
  final String? authorsDatabaseId;
  final String? genresDatabaseId;

  const NotionConnected({
    required this.token,
    required this.workspaceName,
    required this.databases,
    this.booksDatabaseId,
    this.authorsDatabaseId,
    this.genresDatabaseId,
  });
}

class NotionConnectionError extends NotionConnectionState {
  final String message;

  const NotionConnectionError(this.message);
}

/// Drives Settings' Notion connection card. Unlike `theme_provider.dart`'s
/// hardcoded default, this one *is* persisted — the stored token (see
/// [NotionTokenStorage]) is checked on every app start so the connection
/// survives a restart, and a silent reconnect attempt runs as soon as the
/// provider is first read.
class NotionConnectionNotifier extends Notifier<NotionConnectionState> {
  final NotionApi _api = NotionApi();
  final NotionTokenStorage _tokenStorage = NotionTokenStorage();
  final BooksRepository _booksRepository = BooksRepository(NotionApi());

  @override
  NotionConnectionState build() {
    _tryReconnect();
    return const NotionDisconnected();
  }

  Future<void> _tryReconnect() async {
    String? token;
    try {
      token = await _tokenStorage.read();
    } catch (_) {
      // No secure-storage platform channel available (e.g. widget tests) —
      // stay disconnected rather than crash.
      return;
    }
    if (token == null) return;
    await _connect(token, persistOnSuccess: false, clearOnFailure: true);
  }

  Future<void> connect(String token) => _connect(token, persistOnSuccess: true, clearOnFailure: false);

  Future<void> _connect(String token, {required bool persistOnSuccess, required bool clearOnFailure}) async {
    state = const NotionConnecting();
    try {
      final user = await _api.getMe(token);
      final databases = await _api.searchDatabases(token);
      final ids = _booksRepository.resolveDatabaseIds(databases);
      if (persistOnSuccess) await _tokenStorage.write(token);
      state = NotionConnected(
        token: token,
        workspaceName: user.workspaceName,
        databases: databases,
        booksDatabaseId: ids.booksDatabaseId,
        authorsDatabaseId: ids.authorsDatabaseId,
        genresDatabaseId: ids.genresDatabaseId,
      );
    } on NotionApiException catch (e) {
      if (e.statusCode == 401 && clearOnFailure) {
        await _tokenStorage.clear();
      }
      state = NotionConnectionError(e.message);
    } catch (e) {
      state = NotionConnectionError('$e');
    }
  }

  Future<void> disconnect() async {
    await _tokenStorage.clear();
    state = const NotionDisconnected();
  }
}

final notionConnectionProvider =
    NotifierProvider<NotionConnectionNotifier, NotionConnectionState>(NotionConnectionNotifier.new);
