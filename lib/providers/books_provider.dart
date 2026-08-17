import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';

/// Sample data only — mirrors the design prototype's own `SEED_BOOKS`.
/// Replaced by a real Notion-backed repository once NBLM-x (Notion
/// connection) lands; nothing downstream should assume this is permanent.
const _sampleBooks = [
  Book(
    id: 'sample-1',
    title: 'Atomic Habits',
    author: 'James Clear',
    genres: ['selfhelp'],
  ),
  Book(
    id: 'sample-2',
    title: 'Deep Work',
    author: 'Cal Newport',
    genres: ['business'],
  ),
  Book(
    id: 'sample-3',
    title: 'Dune',
    author: 'Frank Herbert',
    genres: ['scifi'],
    reading: ReadingStatus(status: 'Reading', currentPage: 210),
  ),
  Book(
    id: 'sample-4',
    title: 'Mistborn',
    author: 'Brandon Sanderson',
    genres: ['fantasy'],
  ),
  Book(
    id: 'sample-5',
    title: 'Project Hail Mary',
    author: 'Andy Weir',
    genres: ['scifi'],
  ),
  Book(
    id: 'sample-6',
    title: 'Legendary',
    author: 'A. Sable',
    genres: ['fantasy'],
  ),
];

final booksProvider = StateProvider<List<Book>>((ref) => _sampleBooks);
