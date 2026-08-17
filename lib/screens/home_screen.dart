import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'manual_entry_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final connection = ref.watch(notionConnectionProvider);
    final booksAsync = connection is NotionConnected ? ref.watch(booksProvider) : null;
    final hasBooks = booksAsync?.valueOrNull?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: tokens.bg,
      floatingActionButton: hasBooks ? _AddFab(tokens: tokens, l10n: l10n) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontalPadding,
              vertical: 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.shelfTitle, style: AppTypography.screenTitle(tokens.text)),
                _SearchButton(tokens: tokens),
              ],
            ),
          ),
          if (hasBooks) _TabsRow(tokens: tokens, l10n: l10n),
          Expanded(
            child: connection is! NotionConnected
                ? _NotConnectedState(tokens: tokens, l10n: l10n)
                : booksAsync!.when(
                    loading: () => Center(child: CircularProgressIndicator(color: tokens.accent)),
                    error: (error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          l10n.homeLoadError('$error'),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMuted(tokens.muted),
                        ),
                      ),
                    ),
                    data: (books) => books.isEmpty
                        ? _EmptyState(tokens: tokens, l10n: l10n)
                        : _BookGrid(tokens: tokens, books: books),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotConnectedState extends ConsumerWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _NotConnectedState({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.homeNotConnected,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted(tokens.muted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ref.read(selectedTabProvider.notifier).state = 1,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                ),
              ),
              child: Text(l10n.navSettings, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  final AppColorTokens tokens;
  const _SearchButton({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tokens.surface,
        border: Border.all(color: tokens.border),
      ),
      child: Icon(Icons.search, size: 18, color: tokens.muted),
    );
  }
}

class _TabsRow extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _TabsRow({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.border))),
      child: Row(
        children: [
          _TabLabel(label: l10n.tabAll, active: true, tokens: tokens),
          const SizedBox(width: 18),
          _TabLabel(label: l10n.tabGenre, active: false, tokens: tokens),
          const SizedBox(width: 18),
          _TabLabel(label: l10n.tabRecent, active: false, tokens: tokens),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final AppColorTokens tokens;
  const _TabLabel({required this.label, required this.active, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? tokens.accent : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: active ? tokens.text : tokens.muted,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _EmptyState({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: tokens.track,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: tokens.border),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.emptyTitle,
            textAlign: TextAlign.center,
            style: AppTypography.detailTitle(tokens.text).copyWith(fontSize: 19),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.emptyMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMuted(tokens.muted),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showComingSoon(context, l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                ),
              ),
              child: Text(l10n.emptyCta, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualEntryScreen())),
            child: Text(l10n.emptyManual, style: TextStyle(color: tokens.accent, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

class _BookGrid extends StatelessWidget {
  final AppColorTokens tokens;
  final List<Book> books;
  const _BookGrid({required this.tokens, required this.books});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontalPadding,
        16,
        AppSpacing.screenHorizontalPadding,
        90,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.52,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) => _BookTile(tokens: tokens, book: books[i]),
    );
  }
}

class _BookTile extends StatelessWidget {
  final AppColorTokens tokens;
  final Book book;
  const _BookTile({required this.tokens, required this.book});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _BookCover(book: book)),
        const SizedBox(height: 6),
        Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: tokens.text),
        ),
        Text(
          book.authors.join(', '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, color: tokens.muted),
        ),
      ],
    );
  }
}

/// Real cover art when available, falling back to a flat genre-color block
/// (with the genre name overlaid) when there's no cover or the image fails
/// to load — Notion's `Cover` file URLs are signed and expire (~1hr), so a
/// cached URL can easily be dead by the time this renders.
class _BookCover extends StatelessWidget {
  final Book book;
  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverUrl;
    if (coverUrl == null) return _GenreBlock(book: book);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        coverUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _GenreBlock(book: book),
      ),
    );
  }
}

class _GenreBlock extends StatelessWidget {
  final Book book;
  const _GenreBlock({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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

class _AddFab extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _AddFab({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: tokens.surface,
      shape: CircleBorder(side: BorderSide(color: tokens.accent, width: 1.5)),
      onPressed: () => _showAddMenu(context),
      child: Icon(Icons.add, color: tokens.accent),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: tokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.addSheetScan, style: TextStyle(color: tokens.text, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon(context, l10n);
              },
            ),
            ListTile(
              title: Text(l10n.addSheetManual, style: TextStyle(color: tokens.text, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context, AppLocalizations l10n) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.comingSoon)),
  );
}
