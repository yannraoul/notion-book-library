import 'package:intl/intl.dart';

import '../models/book.dart';
import 'app_database.dart';

/// Local cache mirroring `BooksRepository`'s resolved [Book] read surface,
/// so it can fall back to last-known data whenever a live Notion call
/// fails.
class BooksCache {
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  final AppDatabase _appDb;

  BooksCache({AppDatabase? appDatabase}) : _appDb = appDatabase ?? AppDatabase();

  /// Replaces the entire cached Books table — [books] is always the
  /// database's full contents fetched from Notion, so a full replace also
  /// picks up deletions/renames rather than leaving stale rows behind.
  Future<void> writeBooks(List<Book> books) async {
    final db = await _appDb.database;
    await db.transaction((txn) async {
      await txn.delete('books');
      for (final book in books) {
        await txn.insert('books', _row(book));
      }
    });
  }

  /// Adds a single newly-created book without touching the rest of the
  /// cached table — unlike [writeBooks], which always replaces everything.
  Future<void> insertBook(Book book) async {
    final db = await _appDb.database;
    await db.insert('books', _row(book));
  }

  Future<List<Book>> readBooks() async {
    final db = await _appDb.database;
    final rows = await db.query('books');
    return rows.map(_fromRow).toList();
  }

  Map<String, Object?> _row(Book book) => {
        'id': book.id,
        'title': book.title,
        'subtitle': book.subtitle,
        'authors': book.authors.join(', '),
        'isbn': book.isbn,
        'pages': book.pages,
        'published_date': book.publishedDate != null ? _dateFormat.format(book.publishedDate!) : null,
        'cover_url': book.coverUrl,
        // Full ISO 8601 (date + time), not the date-only `_dateFormat` used
        // above — Notion's `created_time` carries time-of-day and "Recent"
        // needs that precision to order same-day adds correctly.
        'date_added': book.dateAdded?.toIso8601String(),
        'api_categories': book.apiCategories,
        'genres': book.genres.join(', '),
        'status': book.reading?.status?.notionName,
        'current_page': book.reading?.currentPage,
        'date_started': book.reading?.dateStarted != null ? _dateFormat.format(book.reading!.dateStarted!) : null,
        'date_finished': book.reading?.dateFinished != null ? _dateFormat.format(book.reading!.dateFinished!) : null,
        'rating': book.reading?.rating,
      };

  Book _fromRow(Map<String, Object?> row) {
    final publishedDate = row['published_date'] as String?;
    final dateStarted = row['date_started'] as String?;
    final dateFinished = row['date_finished'] as String?;
    final authors = row['authors'] as String?;
    final genres = row['genres'] as String?;
    final status = BookStatus.fromNotionName(row['status'] as String?);
    final currentPage = (row['current_page'] as num?)?.toDouble();
    final rating = row['rating'] as int?;
    final reading = (status != null || currentPage != null || dateStarted != null || dateFinished != null || rating != null)
        ? ReadingStatus(
            status: status,
            currentPage: currentPage,
            dateStarted: dateStarted != null ? _dateFormat.parse(dateStarted) : null,
            dateFinished: dateFinished != null ? _dateFormat.parse(dateFinished) : null,
            rating: rating,
          )
        : null;
    return Book(
      id: row['id'] as String,
      title: row['title'] as String,
      subtitle: row['subtitle'] as String?,
      authors: authors == null || authors.isEmpty ? const [] : authors.split(', '),
      isbn: row['isbn'] as String?,
      pages: row['pages'] as int?,
      publishedDate: publishedDate != null ? _dateFormat.parse(publishedDate) : null,
      coverUrl: row['cover_url'] as String?,
      dateAdded: (row['date_added'] as String?) != null ? DateTime.parse(row['date_added'] as String) : null,
      apiCategories: row['api_categories'] as String?,
      genres: genres == null || genres.isEmpty ? const [] : genres.split(', '),
      reading: reading,
    );
  }
}
