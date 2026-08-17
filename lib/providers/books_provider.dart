import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../services/notion_api.dart';
import 'notion_connection_provider.dart';

/// Loads real books once connected; `[]` while disconnected/not yet
/// resolved rather than an error — `HomeScreen` distinguishes "not
/// connected" from "connected, zero books" via `notionConnectionProvider`
/// directly, not via this provider's empty result.
final booksProvider = FutureProvider<List<Book>>((ref) async {
  final connection = ref.watch(notionConnectionProvider);
  if (connection is! NotionConnected || connection.booksDatabaseId == null) {
    return const [];
  }
  final repository = BooksRepository(NotionApi());
  return repository.loadBooks(
    connection.token,
    connection.booksDatabaseId!,
    connection.authorsDatabaseId,
    connection.genresDatabaseId,
  );
});
