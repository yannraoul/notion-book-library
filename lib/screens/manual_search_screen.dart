import 'dart:async';

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
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import 'queue_screen.dart';

/// Design screen 07 — manual search, reached from the OCR ranked list's
/// "None of these" link (or, during development, directly — the only
/// leg of the pipeline that takes real keyboard input, so it's the one
/// used to test the whole downstream queue/dedupe/genre-confirm flow on
/// `flutter run -d windows` without a camera).
class ManualSearchScreen extends ConsumerStatefulWidget {
  final String initialQuery;
  const ManualSearchScreen({super.key, this.initialQuery = ''});

  @override
  ConsumerState<ManualSearchScreen> createState() => _ManualSearchScreenState();
}

class _ManualSearchScreenState extends ConsumerState<ManualSearchScreen> {
  late final TextEditingController _controller;
  final _lookupService = BookLookupService();
  Timer? _debounce;
  List<BookLookupResult> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) _search(widget.initialQuery);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await _lookupService.searchText(query.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
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
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(l10n.detailBack, style: TextStyle(color: tokens.text)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.manualSearchLabel, style: TextStyle(color: tokens.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onChanged,
                    style: TextStyle(color: tokens.text, fontSize: 15),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: tokens.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.accent, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.accent, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
                        borderSide: BorderSide(color: tokens.accent, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: tokens.accent))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
                      itemBuilder: (context, i) {
                        final result = _results[i];
                        return _ResultRow(tokens: tokens, result: result, onTap: () => _select(result));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final AppColorTokens tokens;
  final BookLookupResult result;
  final VoidCallback onTap;

  const _ResultRow({required this.tokens, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final confidence = result.confidence == null ? null : '${(result.confidence! * 100).round()}%';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPaddingHorizontal, vertical: AppSpacing.cardPaddingVertical),
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
            if (confidence != null) Text(confidence, style: TextStyle(color: tokens.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
