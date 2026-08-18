import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../widgets/genre_chip.dart';

/// Design screen 09 — genre confirm. Never auto-writes an unconfirmed
/// genre (`docs/Backlog shelf.md`) — Confirm is the only way a genre
/// reaches the queue item, even when [genre_matcher.suggestGenre] already
/// pre-selected one. Genre options come live from Notion's `Genres*`
/// database (NBLM-9), not the fixed [genreHues] list NBLM-4 originally
/// assumed — falls back to that static list only if the live fetch fails,
/// same live-first/fallback pattern as [BooksRepository.loadBooks].
class GenreConfirmScreen extends ConsumerStatefulWidget {
  final String itemId;
  const GenreConfirmScreen({super.key, required this.itemId});

  @override
  ConsumerState<GenreConfirmScreen> createState() => _GenreConfirmScreenState();
}

class _GenreConfirmScreenState extends ConsumerState<GenreConfirmScreen> {
  String? _selected;
  late final TextEditingController _newGenreController;
  List<String>? _liveGenres;

  @override
  void initState() {
    super.initState();
    _newGenreController = TextEditingController();
    _loadGenres();
  }

  @override
  void dispose() {
    _newGenreController.dispose();
    super.dispose();
  }

  Future<void> _loadGenres() async {
    final connection = ref.read(notionConnectionProvider);
    final genresDbId = connection is NotionConnected ? connection.genresDatabaseId : null;
    if (connection is! NotionConnected || genresDbId == null) {
      setState(() => _liveGenres = genreHues.keys.toList());
      return;
    }
    try {
      final names = await NotionApi().queryRelationNames(connection.token, genresDbId);
      final sorted = names.values.toSet().toList()..sort();
      if (mounted) setState(() => _liveGenres = sorted);
    } catch (_) {
      if (mounted) setState(() => _liveGenres = genreHues.keys.toList());
    }
  }

  void _selectExisting(String genre) {
    _newGenreController.clear();
    setState(() => _selected = genre);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);
    final item = queue.where((i) => i.id == widget.itemId).firstOrNull;
    if (item == null) {
      return Scaffold(backgroundColor: tokens.bg, body: const SizedBox.shrink());
    }
    _selected ??= item.confirmedGenre;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.genreConfirmTitle, style: TextStyle(color: tokens.text, fontSize: 19, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              if (_liveGenres == null)
                Center(child: CircularProgressIndicator(color: tokens.accent))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _liveGenres!
                      .map((genre) => GenreChip(
                            tokens: tokens,
                            label: genre,
                            selected: _selected == genre,
                            onTap: () => _selectExisting(genre),
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _newGenreController,
                onChanged: (value) {
                  final trimmed = value.trim();
                  if (trimmed.isNotEmpty) setState(() => _selected = trimmed);
                },
                style: TextStyle(color: tokens.text, fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.genreNewHint,
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
              if (item.apiCategories != null) ...[
                const SizedBox(height: 14),
                Text(
                  '${l10n.fromApi} "${item.apiCategories}"',
                  style: TextStyle(color: tokens.muted, fontSize: 12.5),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () {
                          ref.read(scanQueueProvider.notifier).confirmGenre(widget.itemId, _selected!);
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: tokens.track,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.confirm, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
