import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/nav_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/shelf_filter_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'manual_entry_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final connection = ref.watch(notionConnectionProvider);
    final booksAsync = connection is NotionConnected ? ref.watch(booksProvider) : null;
    final hasBooks = booksAsync?.valueOrNull?.isNotEmpty ?? false;
    final tab = ref.watch(shelfTabProvider);
    final genreFilter = ref.watch(genreFilterProvider);
    final searchQuery = ref.watch(shelfSearchQueryProvider);

    return Scaffold(
      backgroundColor: tokens.bg,
      floatingActionButton: hasBooks ? _AddFab(tokens: tokens, l10n: l10n) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HomeHeader(tokens: tokens, l10n: l10n),
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
                    data: (books) {
                      if (books.isEmpty) return _EmptyState(tokens: tokens, l10n: l10n);
                      final filtered = filterAndSortBooks(books, searchQuery: searchQuery, tab: tab, genreFilter: genreFilter);
                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(l10n.shelfNoResults, style: AppTypography.bodyMuted(tokens.muted)),
                          ),
                        );
                      }
                      return _BookGrid(tokens: tokens, books: filtered);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Header row — the shelf title + search icon by default, swapping to a
/// live search field across title/author/subtitle on tap (the design
/// prototype's search icon is explicitly decorative, so this expand/
/// collapse pattern has no reference to match, just app convention).
class _HomeHeader extends ConsumerStatefulWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _HomeHeader({required this.tokens, required this.l10n});

  @override
  ConsumerState<_HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<_HomeHeader> {
  bool _expanded = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.clear();
    ref.read(shelfSearchQueryProvider.notifier).state = '';
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = widget.tokens;
    final l10n = widget.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
      child: _expanded
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: (value) => ref.read(shelfSearchQueryProvider.notifier).state = value,
                    style: TextStyle(color: tokens.text, fontSize: 15),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.shelfSearchHint,
                      hintStyle: TextStyle(color: tokens.muted),
                      filled: true,
                      fillColor: tokens.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(onTap: _close, child: Icon(Icons.close, size: 20, color: tokens.muted)),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.shelfTitle, style: AppTypography.screenTitle(tokens.text)),
                GestureDetector(onTap: () => setState(() => _expanded = true), child: _SearchButton(tokens: tokens)),
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

class _TabsRow extends ConsumerWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  const _TabsRow({required this.tokens, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shelfTabProvider);

    void select(ShelfTab next) {
      ref.read(shelfTabProvider.notifier).state = next;
      // Matches the design prototype's `setTabGenre`: tapping "By genre"
      // always (re)opens the filter sheet, even if already on that tab.
      if (next == ShelfTab.genre) {
        showModalBottomSheet(
          context: context,
          backgroundColor: tokens.surface,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => const _GenreFilterSheet(),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.border))),
      child: Row(
        children: [
          _TabLabel(label: l10n.tabAll, active: tab == ShelfTab.all, tokens: tokens, onTap: () => select(ShelfTab.all)),
          const SizedBox(width: 18),
          _TabLabel(label: l10n.tabGenre, active: tab == ShelfTab.genre, tokens: tokens, onTap: () => select(ShelfTab.genre)),
          const SizedBox(width: 18),
          _TabLabel(label: l10n.tabRecent, active: tab == ShelfTab.recent, tokens: tokens, onTap: () => select(ShelfTab.recent)),
        ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String label;
  final bool active;
  final AppColorTokens tokens;
  final VoidCallback onTap;
  const _TabLabel({required this.label, required this.active, required this.tokens, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
      ),
    );
  }
}

/// Bottom sheet for the "By genre" tab — genre names come live from
/// Notion's `Genres*` database (same `queryRelationNames` call NBLM-9's
/// `GenreConfirmScreen` uses), not the old hardcoded `genreHues` list.
/// Checkboxes filter the grid live; "Apply" just closes the sheet.
class _GenreFilterSheet extends ConsumerStatefulWidget {
  const _GenreFilterSheet();

  @override
  ConsumerState<_GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends ConsumerState<_GenreFilterSheet> {
  List<String>? _genres;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    final connection = ref.read(notionConnectionProvider);
    final genresDbId = connection is NotionConnected ? connection.genresDatabaseId : null;
    if (connection is! NotionConnected || genresDbId == null) {
      setState(() => _genres = const []);
      return;
    }
    try {
      final names = await NotionApi().queryRelationNames(connection.token, genresDbId);
      final sorted = names.values.toSet().toList()..sort();
      if (mounted) setState(() => _genres = sorted);
    } catch (_) {
      if (mounted) setState(() => _genres = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final selected = ref.watch(genreFilterProvider);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.filterByGenre.toUpperCase(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: tokens.muted),
              ),
              const SizedBox(height: 12),
              if (_genres == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: tokens.accent)),
                )
              else if (_genres!.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.filterGenreEmpty, style: TextStyle(color: tokens.muted, fontSize: 14)),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _genres!
                          .map(
                            (genre) => _GenreCheckRow(
                              tokens: tokens,
                              label: genre,
                              checked: selected.contains(genre),
                              onToggle: () {
                                final next = {...selected};
                                if (!next.remove(genre)) next.add(genre);
                                ref.read(genreFilterProvider.notifier).state = next;
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.apply, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenreCheckRow extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final bool checked;
  final VoidCallback onToggle;
  const _GenreCheckRow({required this.tokens, required this.label, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: checked ? tokens.accent : tokens.border, width: 1.5),
                color: checked ? tokens.accent : Colors.transparent,
              ),
              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 14.5, color: tokens.text)),
          ],
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
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
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
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen()));
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
