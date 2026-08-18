import 'package:flutter/material.dart';

import '../models/book.dart';
import '../theme/color_tokens.dart';

/// Real cover art when available, falling back to a flat genre-color block
/// (with the genre name overlaid) when there's no cover or the image fails
/// to load — Notion's `Cover` file URLs are signed and expire (~1hr), so a
/// cached URL can easily be dead by the time this renders. `width`/`height`
/// are both optional: omit both for the shelf-grid tile (fills its parent,
/// e.g. an `Expanded`), or pass both for a fixed size like book detail's
/// 150x225 hero cover.
class BookCover extends StatelessWidget {
  final Book book;
  final double? width;
  final double? height;

  const BookCover({super.key, required this.book, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl;
    final content = coverUrl == null
        ? _GenreBlock(book: book)
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              coverUrl,
              width: width ?? double.infinity,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _GenreBlock(book: book),
            ),
          );
    return width == null && height == null ? content : SizedBox(width: width, height: height, child: content);
  }
}

class _GenreBlock extends StatelessWidget {
  final Book book;
  const _GenreBlock({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: genreColor(book.primaryGenre),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        book.primaryGenre,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}
