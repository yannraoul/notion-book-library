import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/books_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/books_repository.dart';
import '../services/book_lookup_service.dart';
import '../services/notion_api.dart';
import '../theme/spacing.dart';
import 'manual_search_screen.dart';
import 'queue_screen.dart';

/// Design screen 06 — OCR ranked list. [ocrGuess] is the raw text ML Kit
/// read off the cover photo; results and their confidence % come from
/// [BookLookupService.searchText] (same service Manual Search uses).
class OcrCandidatesScreen extends ConsumerStatefulWidget {
  final String ocrGuess;
  const OcrCandidatesScreen({super.key, required this.ocrGuess});

  @override
  ConsumerState<OcrCandidatesScreen> createState() => _OcrCandidatesScreenState();
}

class _OcrCandidatesScreenState extends ConsumerState<OcrCandidatesScreen> {
  final _lookupService = BookLookupService();
  List<BookLookupResult>? _results;

  @override
  void initState() {
    super.initState();
    _lookupService.searchText(widget.ocrGuess).then((results) {
      if (mounted) setState(() => _results = results);
    });
  }

  Future<void> _select(BookLookupResult result) async {
    final connection = ref.read(notionConnectionProvider);
    if (connection is! NotionConnected) return;
    final existingBooks = ref.read(booksProvider).valueOrNull ?? [];
    ref.read(scanQueueProvider.notifier).addFromLookup(
          result,
          booksRepository: BooksRepository(NotionApi()),
          existingBooks: existingBooks,
        );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const QueueScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: Text(l10n.detailBack, style: TextStyle(color: tokens.text)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
              child: Text(l10n.ocrTitle, style: TextStyle(color: tokens.text, fontSize: 19, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _results == null
                  ? Center(child: CircularProgressIndicator(color: tokens.accent))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
                      itemCount: _results!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
                      itemBuilder: (context, i) {
                        final result = _results![i];
                        final confidence = result.confidence == null ? null : '${(result.confidence! * 100).round()}%';
                        return InkWell(
                          onTap: () => _select(result),
                          borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.cardPaddingHorizontal,
                              vertical: AppSpacing.cardPaddingVertical,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
                              border: Border.all(color: tokens.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(result.title, style: TextStyle(color: tokens.text, fontSize: 14.5, fontWeight: FontWeight.w600)),
                                      if (result.authors.isNotEmpty)
                                        Text(result.authors.join(', '), style: TextStyle(color: tokens.muted, fontSize: 12.5)),
                                    ],
                                  ),
                                ),
                                if (confidence != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
                                    child: Text(confidence, style: TextStyle(color: tokens.accent, fontSize: 11.5, fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
              child: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => ManualSearchScreen(initialQuery: widget.ocrGuess)),
                  ),
                  child: Text(l10n.ocrNone, style: TextStyle(color: tokens.alert)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
