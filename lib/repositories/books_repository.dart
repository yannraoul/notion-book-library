import '../database/books_cache.dart';
import '../models/book.dart';
import '../services/notion_api.dart';

/// Translates between Notion's `Books*`/`Authors*`/`Genres*` databases and
/// the app's own [Book] model, and orchestrates creating new `Books*` rows
/// (NBLM-6). Never writes `Status`/`Current page`/`Date started`/`Date
/// finished`/`Rating`, that's permanently Habits' job.
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

  /// Resolves author names to `Authors*` relation ids — matches existing
  /// rows case/whitespace-insensitively, creates a new row for any name
  /// not found. Authors are create-or-link, unlike genres.
  Future<List<String>> resolveAuthorIds(String token, String authorsDbId, List<String> authorNames) async {
    final existing = await api.queryRelationNames(token, authorsDbId);
    final ids = <String>[];
    for (final name in authorNames) {
      final match = existing.entries.firstWhere(
        (entry) => entry.value.trim().toLowerCase() == name.trim().toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );
      if (match.key.isNotEmpty) {
        ids.add(match.key);
      } else {
        ids.add(await api.createRelationPage(token, authorsDbId, name.trim()));
      }
    }
    return ids;
  }

  /// Resolves genre display names to `Genres*` relation ids. Only ever
  /// matches existing rows — the genre list is fixed/closed, so a name with
  /// no match is a real bug (the UI only ever offers picks from that same
  /// fixed list) rather than something to silently skip.
  Future<List<String>> resolveGenreIds(String token, String genresDbId, List<String> genreNames) async {
    final existing = await api.queryRelationNames(token, genresDbId);
    return genreNames.map((name) {
      final match = existing.entries.firstWhere(
        (entry) => entry.value == name,
        orElse: () => throw StateError('No Genres* row named "$name" — the fixed genre list is out of sync with Notion.'),
      );
      return match.key;
    }).toList();
  }

  /// Creates a new `Books*` row and writes it into the cache. Returns the
  /// resulting [Book] built from the fields we already know we wrote —
  /// no re-fetch needed.
  Future<Book> createBook({
    required String token,
    required String booksDbId,
    required String authorsDbId,
    required String genresDbId,
    required String title,
    String? subtitle,
    String? isbn,
    int? pages,
    DateTime? publishedDate,
    String? coverUrl,
    String? apiCategories,
    List<String> authorNames = const [],
    List<String> genreNames = const [],
  }) async {
    final authorIds = await resolveAuthorIds(token, authorsDbId, authorNames);
    final genreIds = await resolveGenreIds(token, genresDbId, genreNames);
    final id = await api.createBookPage(
      token,
      booksDbId: booksDbId,
      title: title,
      subtitle: subtitle,
      isbn: isbn,
      pages: pages,
      publishedDate: publishedDate,
      coverUrl: coverUrl,
      apiCategories: apiCategories,
      authorPageIds: authorIds,
      genrePageIds: genreIds,
    );
    final book = Book(
      id: id,
      title: title,
      subtitle: subtitle,
      authors: authorNames,
      isbn: isbn,
      pages: pages,
      publishedDate: publishedDate,
      coverUrl: coverUrl,
      apiCategories: apiCategories,
      genres: genreNames,
    );
    await cache.insertBook(book);
    return book;
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
