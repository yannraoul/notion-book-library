import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

/// Home screen's own "All / By genre / Recent" tab state — distinct from
/// `nav_provider.dart`'s `selectedTabProvider` (the root Home/Settings
/// index), a different concept despite the similar name.
enum ShelfTab { all, genre, recent }

final shelfTabProvider = StateProvider<ShelfTab>((ref) => ShelfTab.all);

/// Genre names checked in the "By genre" filter sheet. Only applied when
/// [shelfTabProvider] is [ShelfTab.genre] — matches the design prototype's
/// tab-scoped behavior (a filter picked on that tab doesn't silently
/// persist onto Recent/All).
final genreFilterProvider = StateProvider<Set<String>>((ref) => {});

final shelfSearchQueryProvider = StateProvider<String>((ref) => '');

String _normalize(String s) => s.toLowerCase().trim();

/// Applies the Home screen's search + tab-scoped genre filter + tab-scoped
/// sort, in that order — search narrows within whatever the active tab
/// already shows, per `Shelf.dc.html`'s tab-scoped filter/sort logic
/// (lines 787-793) that this mirrors for the tab/genre part.
List<Book> filterAndSortBooks(
  List<Book> books, {
  required String searchQuery,
  required ShelfTab tab,
  required Set<String> genreFilter,
}) {
  var result = books;

  final query = _normalize(searchQuery);
  if (query.isNotEmpty) {
    result = result.where((book) {
      if (_normalize(book.title).contains(query)) return true;
      if (book.subtitle != null && _normalize(book.subtitle!).contains(query)) return true;
      return book.authors.any((author) => _normalize(author).contains(query));
    }).toList();
  }

  if (tab == ShelfTab.genre && genreFilter.isNotEmpty) {
    result = result.where((book) => book.genres.any(genreFilter.contains)).toList();
  }

  result = [...result];
  if (tab == ShelfTab.recent) {
    result.sort((a, b) => (b.dateAdded ?? DateTime(0)).compareTo(a.dateAdded ?? DateTime(0)));
  } else {
    result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }
  return result;
}
