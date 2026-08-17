import '../database/books_cache.dart';
import '../models/book.dart';
import '../services/notion_api.dart';

/// Translates between Notion's `Books*`/`Authors*`/`Genres*` databases and
/// the app's own [Book] model. Read-only — Shelf never writes
/// `Status`/`Current page`/`Date started`/`Date finished`/`Rating`, that's
/// permanently Habits' job.
class BooksRepository {
  final NotionApi api;
  final BooksCache cache;

  BooksRepository(this.api, [BooksCache? cache]) : cache = cache ?? BooksCache();

  /// Matches accessible databases by exact title — no manual-mapping UI.
  /// Real Notion titles carry a trailing asterisk (`"Books*"`/`"Authors*"`/
  /// `"Genres*"`), confirmed live against Yann's workspace.
  ({String? booksDatabaseId, String? authorsDatabaseId, String? genresDatabaseId}) resolveDatabaseIds(
    List<NotionDatabaseSummary> databases,
  ) {
    String? findByTitle(String title) {
      for (final db in databases) {
        if (db.title == title) return db.id;
      }
      return null;
    }

    return (
      booksDatabaseId: findByTitle('Books*'),
      authorsDatabaseId: findByTitle('Authors*'),
      genresDatabaseId: findByTitle('Genres*'),
    );
  }

  /// Every row of `Books*`, with `Authors`/`Genres` relation ids resolved
  /// to display names via [NotionApi.queryRelationNames]. Live-Notion-first,
  /// cache-fallback on any failure. [authorsDbId]/[genresDbId] are optional
  /// only to tolerate a not-yet-resolved id without crashing — Authors/
  /// Genres just won't be resolved to names that load.
  Future<List<Book>> loadBooks(
    String token,
    String booksDbId,
    String? authorsDbId,
    String? genresDbId,
  ) async {
    try {
      final records = await api.queryBooks(token, booksDbId);
      final authorNames = authorsDbId != null
          ? await api.queryRelationNames(token, authorsDbId)
          : const <String, String>{};
      final genreNames = genresDbId != null
          ? await api.queryRelationNames(token, genresDbId)
          : const <String, String>{};
      final books = records.map((r) => _toBook(r, authorNames, genreNames)).toList();
      await cache.writeBooks(books);
      return books;
    } catch (_) {
      return cache.readBooks();
    }
  }

  Book _toBook(NotionBookRecord r, Map<String, String> authorNames, Map<String, String> genreNames) {
    final hasReading = r.status != null ||
        r.currentPage != null ||
        r.dateStarted != null ||
        r.dateFinished != null ||
        r.rating != null;
    return Book(
      id: r.id,
      title: r.name,
      subtitle: r.subtitle,
      authors: r.authorIds.map((id) => authorNames[id]).whereType<String>().toList(),
      isbn: r.isbn,
      pages: r.totalPages?.round(),
      publishedDate: r.datePublished,
      coverUrl: r.coverUrl,
      apiCategories: r.apiCategories,
      genres: r.genreIds.map((id) => genreNames[id]).whereType<String>().toList(),
      reading: hasReading
          ? ReadingStatus(
              status: r.status,
              currentPage: r.currentPage,
              dateStarted: r.dateStarted,
              dateFinished: r.dateFinished,
              rating: r.rating,
            )
          : null,
    );
  }
}
