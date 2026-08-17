import 'genre_matcher.dart';
import 'google_books_api.dart';
import 'open_library_api.dart';

/// Orchestrates [GoogleBooksApi] and [OpenLibraryApi] per the precedence
/// rule in `docs/Backlog shelf.md`: Google Books first (cleaner category
/// data), Open Library fills gaps (better coverage on older/obscure
/// titles, no key ever needed) whenever Google Books has no match or thin
/// data (missing pages, categories, and cover all at once).
class BookLookupService {
  final GoogleBooksApi googleBooks;
  final OpenLibraryApi openLibrary;

  BookLookupService({GoogleBooksApi? googleBooks, OpenLibraryApi? openLibrary})
      : googleBooks = googleBooks ?? GoogleBooksApi(),
        openLibrary = openLibrary ?? OpenLibraryApi();

  Future<BookLookupResult?> lookupIsbn(String isbn) async {
    final google = await googleBooks.lookupIsbn(isbn);
    if (google != null && !google.isThin) {
      return _fromGoogle(google, isbn: isbn);
    }
    final openLib = await openLibrary.lookupIsbn(isbn);
    if (google == null && openLib == null) return null;
    if (google == null) return _fromOpenLibrary(openLib!, isbn: isbn);
    // Google matched but was thin — fill gaps from Open Library.
    return _fromGoogle(google, isbn: isbn, fallback: openLib);
  }

  /// Ranked candidates for the OCR/manual-search screens — Google Books
  /// first, topped up with Open Library if there are fewer than 5,
  /// de-duped by ISBN (falling back to normalized title), each scored
  /// against [query] by a simple token-overlap ratio (no LLM).
  Future<List<BookLookupResult>> searchText(String query) async {
    final results = <BookLookupResult>[];
    final seen = <String>{};

    void addAll(Iterable<BookLookupResult> items) {
      for (final item in items) {
        final key = item.isbn ?? _normalize(item.title);
        if (seen.add(key)) results.add(item);
      }
    }

    final google = await googleBooks.search(query);
    addAll(google.map((v) => _fromGoogle(v)));

    if (results.length < 5) {
      final openLib = await openLibrary.search(query);
      addAll(openLib.map((v) => _fromOpenLibrary(v)));
    }

    final scored = results.map((r) => r.copyWith(confidence: _similarity(query, r.title))).toList();
    scored.sort((a, b) => (b.confidence ?? 0).compareTo(a.confidence ?? 0));
    return scored.take(5).toList();
  }

  BookLookupResult _fromGoogle(GoogleBooksVolume v, {String? isbn, OpenLibraryVolume? fallback}) {
    final categories = v.categories.isNotEmpty ? v.categories : (fallback?.subjects ?? const []);
    final rawCategories = categories.take(6).join(', ');
    return BookLookupResult(
      title: v.title,
      subtitle: v.subtitle,
      authors: v.authors,
      isbn: isbn ?? v.isbn13 ?? v.isbn10,
      pages: v.pageCount ?? fallback?.pages,
      publishedDate: v.publishedDate ?? fallback?.publishedDate,
      coverUrl: v.thumbnailUrl ?? fallback?.coverUrl,
      apiCategories: rawCategories.isEmpty ? null : rawCategories,
      suggestedGenre: suggestGenre(rawCategories),
    );
  }

  BookLookupResult _fromOpenLibrary(OpenLibraryVolume v, {String? isbn}) {
    final rawSubjects = v.subjects.take(6).join(', ');
    return BookLookupResult(
      title: v.title,
      subtitle: v.subtitle,
      authors: v.authors,
      isbn: isbn ?? v.isbn13 ?? v.isbn10,
      pages: v.pages,
      publishedDate: v.publishedDate,
      coverUrl: v.coverUrl,
      apiCategories: rawSubjects.isEmpty ? null : rawSubjects,
      suggestedGenre: suggestGenre(rawSubjects),
    );
  }

  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  /// Token-overlap ratio between [query] and [title], 0.0-1.0.
  double _similarity(String query, String title) {
    final a = _normalize(query).split(' ').where((t) => t.isNotEmpty).toSet();
    final b = _normalize(title).split(' ').where((t) => t.isNotEmpty).toSet();
    if (a.isEmpty || b.isEmpty) return 0;
    final overlap = a.intersection(b).length;
    return overlap / a.union(b).length;
  }
}

/// Unified lookup result — the same field set [BooksRepository.createBook]
/// already accepts, plus [suggestedGenre] (never auto-confirmed) and
/// [confidence] (search results only).
class BookLookupResult {
  final String title;
  final String? subtitle;
  final List<String> authors;
  final String? isbn;
  final int? pages;
  final DateTime? publishedDate;
  final String? coverUrl;
  final String? apiCategories;
  final String? suggestedGenre;
  final double? confidence;

  const BookLookupResult({
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.isbn,
    this.pages,
    this.publishedDate,
    this.coverUrl,
    this.apiCategories,
    this.suggestedGenre,
    this.confidence,
  });

  BookLookupResult copyWith({double? confidence}) {
    return BookLookupResult(
      title: title,
      subtitle: subtitle,
      authors: authors,
      isbn: isbn,
      pages: pages,
      publishedDate: publishedDate,
      coverUrl: coverUrl,
      apiCategories: apiCategories,
      suggestedGenre: suggestedGenre,
      confidence: confidence ?? this.confidence,
    );
  }
}
