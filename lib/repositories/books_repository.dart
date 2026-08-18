import 'dart:typed_data';

import '../database/books_cache.dart';
import '../models/book.dart';
import '../services/notion_api.dart';

/// Normalizes for loose comparison — lowercase, punctuation stripped,
/// whitespace collapsed.
String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

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

  /// Resolves genre display names to `Genres*` relation ids — matches
  /// existing rows case/whitespace-insensitively, creates a new row for any
  /// name not found (NBLM-9: genres are create-or-link now, same as
  /// [resolveAuthorIds] — Yann adds genres directly in Notion sometimes, so
  /// the app can no longer treat that list as fixed/closed).
  Future<List<String>> resolveGenreIds(String token, String genresDbId, List<String> genreNames) async {
    final existing = await api.queryRelationNames(token, genresDbId);
    final ids = <String>[];
    for (final name in genreNames) {
      final match = existing.entries.firstWhere(
        (entry) => entry.value.trim().toLowerCase() == name.trim().toLowerCase(),
        orElse: () => const MapEntry('', ''),
      );
      if (match.key.isNotEmpty) {
        ids.add(match.key);
      } else {
        ids.add(await api.createGenrePage(token, genresDbId, name.trim()));
      }
    }
    return ids;
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
      dateAdded: DateTime.now(),
      apiCategories: apiCategories,
      genres: genreNames,
    );
    await cache.insertBook(book);
    return book;
  }

  /// Updates Shelf-owned fields on an existing `Books*` row (book detail's
  /// write path). Every field is optional — only non-null ones are sent to
  /// Notion and merged into the returned/cached [Book], so a caller can
  /// write any subset of fields in one call. [current.reading] is always
  /// carried through untouched: this method has no parameter for it at
  /// all, so there's no way for a caller to accidentally overwrite a
  /// Habits-owned field through this path.
  ///
  /// [coverUrl] and [coverImageBytes] are mutually exclusive — pass
  /// [coverImageBytes] (+ [coverImageFilename]/[coverImageContentType]) to
  /// upload a local image directly to Notion (no external hosting, same as
  /// picking a file in Notion's own UI) instead of linking an external
  /// URL. The uploaded file is attached and resolved to Notion's own
  /// signed URL before this returns, via [NotionApi.updateBookPage]'s
  /// response — no extra round trip needed.
  Future<Book> updateBook({
    required String token,
    required String authorsDbId,
    required String genresDbId,
    required Book current,
    String? title,
    String? isbn,
    int? pages,
    DateTime? publishedDate,
    String? coverUrl,
    Uint8List? coverImageBytes,
    String? coverImageFilename,
    String? coverImageContentType,
    List<String>? authorNames,
    List<String>? genreNames,
  }) async {
    final authorIds = authorNames == null ? null : await resolveAuthorIds(token, authorsDbId, authorNames);
    final genreIds = genreNames == null ? null : await resolveGenreIds(token, genresDbId, genreNames);
    final coverFileUploadId = coverImageBytes == null
        ? null
        : await uploadCoverImage(
            token,
            coverImageBytes,
            filename: coverImageFilename ?? 'cover.jpg',
            contentType: coverImageContentType ?? 'application/octet-stream',
          );
    final resolvedCoverUrl = await api.updateBookPage(
      token,
      current.id,
      title: title,
      isbn: isbn,
      pages: pages,
      publishedDate: publishedDate,
      coverUrl: coverFileUploadId == null ? coverUrl : null,
      coverFileUploadId: coverFileUploadId,
      coverFilename: coverImageFilename,
      authorPageIds: authorIds,
      genrePageIds: genreIds,
    );
    final updated = Book(
      id: current.id,
      title: title ?? current.title,
      subtitle: current.subtitle,
      authors: authorNames ?? current.authors,
      isbn: isbn ?? current.isbn,
      pages: pages ?? current.pages,
      publishedDate: publishedDate ?? current.publishedDate,
      coverUrl: coverFileUploadId != null ? (resolvedCoverUrl ?? current.coverUrl) : (coverUrl ?? current.coverUrl),
      dateAdded: current.dateAdded,
      apiCategories: current.apiCategories,
      genres: genreNames ?? current.genres,
      reading: current.reading,
    );
    await cache.updateBook(updated);
    return updated;
  }

  /// Uploads [bytes] directly to Notion — no external hosting needed, the
  /// same capability Notion's own UI already offers for a page cover.
  /// Returns the resulting file_upload id, ready to attach via
  /// [NotionApi.updateBookPage]'s `coverFileUploadId`.
  Future<String> uploadCoverImage(
    String token,
    Uint8List bytes, {
    required String filename,
    required String contentType,
  }) async {
    final upload = await api.createFileUpload(token, filename: filename, contentType: contentType);
    await api.sendFileUpload(token, upload.uploadUrl, bytes, filename: filename, contentType: contentType);
    return upload.id;
  }

  /// Matches a scanned/looked-up candidate against the existing shelf, per
  /// `docs/Backlog shelf.md`'s dedupe rule: ISBN exact match first: if
  /// that finds nothing (or the candidate has no ISBN), fuzzy fallback =
  /// normalized title exact match AND at least one normalized author in
  /// common. Deliberately simple/deterministic rather than a string-
  /// distance algorithm — no LLM, and this is the plainest rule that
  /// satisfies "fuzzy" without adding a fuzzy-matching dependency.
  Book? findDuplicate({
    required String title,
    String? isbn,
    List<String> authors = const [],
    required List<Book> existing,
  }) {
    if (isbn != null && isbn.isNotEmpty) {
      for (final book in existing) {
        if (book.isbn != null && book.isbn == isbn) return book;
      }
    }
    final normalizedTitle = _normalize(title);
    final normalizedAuthors = authors.map(_normalize).toSet();
    for (final book in existing) {
      if (_normalize(book.title) != normalizedTitle) continue;
      if (normalizedAuthors.isEmpty) return book;
      final bookAuthors = book.authors.map(_normalize).toSet();
      if (bookAuthors.intersection(normalizedAuthors).isNotEmpty) return book;
    }
    return null;
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
      dateAdded: r.dateAdded,
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
