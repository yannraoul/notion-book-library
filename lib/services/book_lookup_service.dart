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

    final scored = results.map((r) => r.copyWith(confidence: confidence(query, r))).toList();
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

  Set<String> _tokenize(String s) => _normalize(s).split(' ').where((t) => t.isNotEmpty).toSet();

  /// Token-overlap (Jaccard) ratio between two token sets, 0.0-1.0.
  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.intersection(b).length / a.union(b).length;
  }

  static const double _titleWeight = 0.65;
  static const double _authorWeight = 0.35;

  /// Confidence score for [r] against [query]. A query mixing title and
  /// author text (the only kind this app produces — OCR guesses and manual
  /// search are both a single free-text field) used to be compared to the
  /// title alone, so author-name tokens could out-vote the real title and
  /// rank an unrelated book above the correct one (see the known-limitation
  /// note in planning/features/NBLM-7.md). Instead, claim each query token
  /// for whichever field it actually matches: tokens that overlap the
  /// author's name are set aside before scoring the title on what's left,
  /// and only contribute an author score of their own (how much of the
  /// author's name was found in the query) when the query references the
  /// author at all — most queries are title-only, and treating "author not
  /// mentioned" the same as "author mismatch" would cap even a perfect
  /// title match well below 1.0.
  double confidence(String query, BookLookupResult r) {
    final queryTokens = _tokenize(query);
    final authorTokens = _tokenize(r.authors.join(' '));
    final titleTokens = _tokenize(r.title);

    final authorClaimed = queryTokens.intersection(authorTokens);
    if (authorClaimed.isEmpty) {
      return _jaccard(queryTokens, titleTokens);
    }

    final titleQueryTokens = queryTokens.difference(authorClaimed);
    final titleScore = _jaccard(titleQueryTokens.isEmpty ? queryTokens : titleQueryTokens, titleTokens);
    final authorScore = authorClaimed.length / authorTokens.length;

    return _titleWeight * titleScore + _authorWeight * authorScore;
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
