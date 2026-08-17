import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/books_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/scan_queue_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/books_repository.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import 'dedupe_screen.dart';
import 'genre_confirm_screen.dart';

/// Design screen 05 — review queue. Rows show a status badge; tapping a
/// duplicate opens [DedupeScreen], tapping needs-genre opens
/// [GenreConfirmScreen]. "Add ready now" commits every ready item via the
/// NBLM-6 write path.
class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);
    final readyCount = queue.where((item) => item.status == QueueItemStatus.ready).length;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.queueTitle(queue.length),
                    style: TextStyle(color: tokens.text, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel, style: TextStyle(color: tokens.accent)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
                itemCount: queue.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
                itemBuilder: (context, i) => _QueueRow(tokens: tokens, l10n: l10n, item: queue[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: readyCount == 0 || _saving ? null : _addReadyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: tokens.track,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(
                    l10n.addReadyNow(readyCount),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addReadyNow() async {
    final connection = ref.read(notionConnectionProvider);
    if (connection is! NotionConnected) return;
    setState(() => _saving = true);
    await ref.read(scanQueueProvider.notifier).commitReady(
          booksRepository: BooksRepository(NotionApi()),
          connection: connection,
        );
    ref.invalidate(booksProvider);
    if (!mounted) return;
    setState(() => _saving = false);
    final remaining = ref.read(scanQueueProvider);
    if (remaining.isEmpty) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}

class _QueueRow extends ConsumerWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final QueueItem item;

  const _QueueRow({required this.tokens, required this.l10n, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (label, color) = switch (item.status) {
      QueueItemStatus.ready => (l10n.statusReady, tokens.accent),
      QueueItemStatus.duplicate => (l10n.statusDuplicate, tokens.alert),
      QueueItemStatus.needsGenre => (l10n.statusNeedsGenre, tokens.muted),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
      onTap: item.status == QueueItemStatus.ready
          ? null
          : () {
              if (item.status == QueueItemStatus.duplicate) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => DedupeScreen(itemId: item.id)));
              } else {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => GenreConfirmScreen(itemId: item.id)));
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.cardPaddingHorizontal, vertical: AppSpacing.cardPaddingVertical),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
          border: Border.all(color: item.status == QueueItemStatus.duplicate ? tokens.alert : tokens.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: TextStyle(color: tokens.text, fontSize: 15, fontWeight: FontWeight.w600)),
                  if (item.authors.isNotEmpty)
                    Text(item.authors.join(', '), style: TextStyle(color: tokens.muted, fontSize: 12.5)),
                ],
              ),
            ),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
