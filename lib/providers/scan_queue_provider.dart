import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../services/author_matcher.dart';
import '../services/book_lookup_service.dart';
import 'notion_connection_provider.dart';

enum QueueItemStatus { ready, duplicate, needsGenre, needsAuthorConfirm }

/// Priority chain for a queue item's status: a duplicate always wins;
/// otherwise ambiguous authors block before genre does (so confirming
/// genre on an item that still has ambiguous authors correctly falls back
/// to [QueueItemStatus.needsAuthorConfirm] instead of jumping to `ready`);
/// otherwise a missing genre blocks; otherwise it's ready.
QueueItemStatus _computeStatus({
  required bool duplicate,
  required Map<String, List<AuthorMatch>> ambiguousAuthors,
  required String? confirmedGenre,
}) {
  if (duplicate) return QueueItemStatus.duplicate;
  if (ambiguousAuthors.isNotEmpty) return QueueItemStatus.needsAuthorConfirm;
  if (confirmedGenre == null) return QueueItemStatus.needsGenre;
  return QueueItemStatus.ready;
}

/// One scanned/looked-up book, not yet saved to Notion. Mirrors the
/// design prototype's queue array shape (`docs/Backlog shelf.md`,
/// design screens 05/08/09).
class QueueItem {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn;
  final int? pages;
  final DateTime? publishedDate;
  final String? coverUrl;
  final String? apiCategories;
  final String? confirmedGenre;

  /// Raw scanned author name -> ranked existing-author candidates, for
  /// every author of this item whose match against `Authors*` was
  /// ambiguous (close but not identical) — never populated for an exact
  /// match (silently linked) or no match at all (silently treated as
  /// new), see `author_matcher.dart`. Non-empty blocks [status] at
  /// [QueueItemStatus.needsAuthorConfirm].
  final Map<String, List<AuthorMatch>> ambiguousAuthors;

  final QueueItemStatus status;
  final Book? duplicateOf;

  const QueueItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn,
    this.pages,
    this.publishedDate,
    this.coverUrl,
    this.apiCategories,
    this.confirmedGenre,
    this.ambiguousAuthors = const {},
    required this.status,
    this.duplicateOf,
  });

  QueueItem copyWith({
    String? title,
    String? subtitle,
    int? pages,
    DateTime? publishedDate,
    String? isbn,
    List<String>? authors,
    String? confirmedGenre,
    Map<String, List<AuthorMatch>>? ambiguousAuthors,
    QueueItemStatus? status,
  }) {
    return QueueItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      isbn: isbn ?? this.isbn,
      pages: pages ?? this.pages,
      publishedDate: publishedDate ?? this.publishedDate,
      coverUrl: coverUrl,
      apiCategories: apiCategories,
      confirmedGenre: confirmedGenre ?? this.confirmedGenre,
      ambiguousAuthors: ambiguousAuthors ?? this.ambiguousAuthors,
      status: status ?? this.status,
      duplicateOf: duplicateOf,
    );
  }
}

/// Holds the in-progress scan session's queue — cleared when a new scan
/// session starts or once items are committed to Notion. Not persisted;
/// this is ephemeral UI state, unlike the shelf itself.
class ScanQueueNotifier extends Notifier<List<QueueItem>> {
  int _nextId = 0;

  @override
  List<QueueItem> build() => const [];

  /// Adds a lookup result to the queue, running dedupe against the
  /// current shelf, carrying over the API's suggested genre (never
  /// auto-confirmed — [QueueItemStatus.needsGenre] still requires the
  /// genre-confirm screen), and checking each author against
  /// [existingAuthorNames] for an ambiguous near-match. Exact matches and
  /// names with no similar existing author both stay silent — only an
  /// ambiguous match blocks the item at [QueueItemStatus.needsAuthorConfirm].
  void addFromLookup(
    BookLookupResult result, {
    required BooksRepository booksRepository,
    required List<Book> existingBooks,
    required Map<String, String> existingAuthorNames,
  }) {
    final duplicate = booksRepository.findDuplicate(
      title: result.title,
      isbn: result.isbn,
      authors: result.authors,
      existing: existingBooks,
    );
    final ambiguousAuthors = <String, List<AuthorMatch>>{};
    for (final author in result.authors) {
      final decision = resolveAuthorMatch(author, existingAuthorNames.values);
      if (decision is AuthorMatchAmbiguous) ambiguousAuthors[author] = decision.candidates;
    }
    final status = _computeStatus(duplicate: duplicate != null, ambiguousAuthors: ambiguousAuthors, confirmedGenre: result.suggestedGenre);
    state = [
      ...state,
      QueueItem(
        id: '${_nextId++}',
        title: result.title,
        subtitle: result.subtitle,
        authors: result.authors,
        isbn: result.isbn,
        pages: result.pages,
        publishedDate: result.publishedDate,
        coverUrl: result.coverUrl,
        apiCategories: result.apiCategories,
        confirmedGenre: result.suggestedGenre,
        ambiguousAuthors: ambiguousAuthors,
        status: status,
        duplicateOf: duplicate,
      ),
    ];
  }

  /// Dedupe dialog's "Fill in missing details" — merges the scan's
  /// isbn/pages/publishedDate into the item. A real merge into the
  /// *existing* Notion row happens on save; here we just stop treating it
  /// as a duplicate, falling through to any still-pending author/genre
  /// confirmation rather than jumping straight to ready.
  void resolveFillMissing(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: _computeStatus(duplicate: false, ambiguousAuthors: item.ambiguousAuthors, confirmedGenre: item.confirmedGenre),
          )
        else
          item,
    ];
  }

  /// Dedupe dialog's "Add as separate book" — keeps it in the queue as
  /// its own new entry.
  void resolveAddSeparate(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            status: _computeStatus(duplicate: false, ambiguousAuthors: item.ambiguousAuthors, confirmedGenre: item.confirmedGenre),
          )
        else
          item,
    ];
  }

  void confirmGenre(String id, String genre) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(
            confirmedGenre: genre,
            status: _computeStatus(duplicate: false, ambiguousAuthors: item.ambiguousAuthors, confirmedGenre: genre),
          )
        else
          item,
    ];
  }

  /// Author-confirm screen's per-author resolution — replaces
  /// [originalName] in the item's author list with [resolvedName] (the
  /// canonical existing name, or the same raw name kept as new), so
  /// `resolveAuthorIds`'s exact-match logic finds it unambiguously at
  /// commit time. Once every ambiguous author is resolved, falls through
  /// to any still-pending genre confirmation rather than jumping straight
  /// to ready.
  void confirmAuthor(String id, String originalName, String resolvedName) {
    state = [
      for (final item in state)
        if (item.id == id)
          () {
            final remainingAmbiguous = {
              for (final entry in item.ambiguousAuthors.entries)
                if (entry.key != originalName) entry.key: entry.value,
            };
            return item.copyWith(
              authors: [for (final a in item.authors) a == originalName ? resolvedName : a],
              ambiguousAuthors: remainingAmbiguous,
              status: _computeStatus(duplicate: false, ambiguousAuthors: remainingAmbiguous, confirmedGenre: item.confirmedGenre),
            );
          }()
        else
          item,
    ];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  /// Saves every [QueueItemStatus.ready] item via the NBLM-6 write path,
  /// removing each from the queue as it's committed. Returns the number
  /// saved.
  Future<int> commitReady({required BooksRepository booksRepository, required NotionConnected connection}) async {
    final ready = state.where((item) => item.status == QueueItemStatus.ready).toList();
    var saved = 0;
    for (final item in ready) {
      await booksRepository.createBook(
        token: connection.token,
        booksDbId: connection.booksDatabaseId!,
        authorsDbId: connection.authorsDatabaseId!,
        genresDbId: connection.genresDatabaseId!,
        title: item.title,
        subtitle: item.subtitle,
        isbn: item.isbn,
        pages: item.pages,
        publishedDate: item.publishedDate,
        coverUrl: item.coverUrl,
        apiCategories: item.apiCategories,
        authorNames: item.authors,
        genreNames: item.confirmedGenre == null ? const [] : [item.confirmedGenre!],
      );
      remove(item.id);
      saved++;
    }
    return saved;
  }

  void clear() => state = const [];
}

final scanQueueProvider = NotifierProvider<ScanQueueNotifier, List<QueueItem>>(ScanQueueNotifier.new);
