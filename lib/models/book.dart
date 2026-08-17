/// Reading-progress fields owned and written by the sister Habits app —
/// Shelf only ever displays these, never edits them.
class ReadingStatus {
  final String status;
  final int? currentPage;

  const ReadingStatus({required this.status, this.currentPage});
}

/// Decoupled from Notion's `Books` db property shape on purpose — a future
/// `notion_api.dart`/`repositories/` layer translates to/from this, so the
/// rest of the app never depends on Notion's schema directly.
class Book {
  final String id;
  final String title;
  final String? subtitle;
  final String author;
  final String? isbn;
  final int? pages;
  final String? publishedDate;

  /// Genre ids (see `lib/theme/color_tokens.dart`'s `genreHues`). The first
  /// entry is the "primary" genre used for the shelf-grid tile's cover
  /// color and label.
  final List<String> genres;

  /// Read-only, owned by Habits. Null until Habits' Reading module has
  /// started this book.
  final ReadingStatus? reading;

  const Book({
    required this.id,
    required this.title,
    this.subtitle,
    required this.author,
    this.isbn,
    this.pages,
    this.publishedDate,
    this.genres = const [],
    this.reading,
  });

  String get primaryGenre => genres.isNotEmpty ? genres.first : 'fiction';
}
