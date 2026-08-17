/// Mirrors the `Books*` database's `Status` property (Notion's dedicated
/// `status` type, not `select`). Fixed, Notion-enforced 4-value vocabulary.
/// Shelf only ever reads this — never writes it, that stays Habits' job.
enum BookStatus {
  toRead('To read'),
  reading('Reading'),
  finished('Finished'),
  stopped('Stopped');

  final String notionName;

  const BookStatus(this.notionName);

  static BookStatus? fromNotionName(String? name) {
    for (final status in values) {
      if (status.notionName == name) return status;
    }
    return null;
  }
}

/// Reading-progress fields owned and written by the sister Habits app —
/// Shelf only ever displays these, never edits them. `rating` is 1-5 (star
/// count), or null if unrated.
class ReadingStatus {
  final BookStatus? status;
  final double? currentPage;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final int? rating;

  const ReadingStatus({
    this.status,
    this.currentPage,
    this.dateStarted,
    this.dateFinished,
    this.rating,
  });
}

/// Decoupled from Notion's `Books*` property shape on purpose —
/// `services/`/`repositories/` translate to/from Notion's relation/select/
/// files shapes, so the rest of the app never depends on it directly.
class Book {
  final String id;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn;
  final int? pages;
  final DateTime? publishedDate;
  final String? coverUrl;

  /// Raw API category/subject dump — reference only, never the curated
  /// `genres` relation. See `docs/Backlog shelf.md`.
  final String? apiCategories;

  /// Genre names (already resolved from the `Genres` relation to display
  /// text via `Authors*`/`Genres*`'s `Name` property — not raw Notion
  /// relation ids). The first entry is the "primary" genre used for the
  /// shelf-grid tile's cover color/label.
  final List<String> genres;

  /// Read-only, owned by Habits. Null until Habits' Reading module has
  /// started this book.
  final ReadingStatus? reading;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn,
    this.pages,
    this.publishedDate,
    this.coverUrl,
    this.apiCategories,
    this.genres = const [],
    this.reading,
  });

  String get primaryGenre => genres.isNotEmpty ? genres.first : '';
}
