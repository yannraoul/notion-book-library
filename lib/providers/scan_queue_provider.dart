import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../repositories/books_repository.dart';
import '../services/book_lookup_service.dart';
import 'notion_connection_provider.dart';

enum QueueItemStatus { ready, duplicate, needsGenre }

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
    required this.status,
    this.duplicateOf,
  });

  QueueItem copyWith({
    String? title,
    String? subtitle,
    int? pages,
    DateTime? publishedDate,
    String? isbn,
    String? confirmedGenre,
    QueueItemStatus? status,
  }) {
    return QueueItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors,
      isbn: isbn ?? this.isbn,
      pages: pages ?? this.pages,
      publishedDate: publishedDate ?? this.publishedDate,
      coverUrl: coverUrl,
      apiCategories: apiCategories,
      confirmedGenre: confirmedGenre ?? this.confirmedGenre,
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
  /// current shelf and carrying over the API's suggested genre (never
  /// auto-confirmed — [QueueItemStatus.needsGenre] still requires the
  /// genre-confirm screen).
  void addFromLookup(BookLookupResult result, {required BooksRepository booksRepository, required List<Book> existingBooks}) {
    final duplicate = booksRepository.findDuplicate(
      title: result.title,
      isbn: result.isbn,
      authors: result.authors,
      existing: existingBooks,
    );
    final status = duplicate != null
        ? QueueItemStatus.duplicate
        : result.suggestedGenre == null
            ? QueueItemStatus.needsGenre
            : QueueItemStatus.ready;
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
        status: status,
        duplicateOf: duplicate,
      ),
    ];
  }

  /// Dedupe dialog's "Fill in missing details" — merges the scan's
  /// isbn/pages/publishedDate into the item and marks it ready. A real
  /// merge into the *existing* Notion row happens on save; here we just
  /// stop treating it as a duplicate.
  void resolveFillMissing(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: QueueItemStatus.ready) else item,
    ];
  }

  /// Dedupe dialog's "Add as separate book" — keeps it in the queue as
  /// its own new entry.
  void resolveAddSeparate(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(status: QueueItemStatus.ready) else item,
    ];
  }

  void confirmGenre(String id, String genre) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(confirmedGenre: genre, status: QueueItemStatus.ready) else item,
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
