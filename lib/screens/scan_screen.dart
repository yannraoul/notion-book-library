import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
import 'ocr_candidates_screen.dart';
import 'queue_screen.dart';

enum _ScanMode { barcode, cover }

/// Design screens 03/04 — the scan viewfinder. A single
/// [MobileScannerController] (`returnImage: true`) serves both modes:
/// barcode mode reads `capture.barcodes` (fires on every analyzed frame,
/// confirmed by reading the package source — not just on a hit),
/// cover-photo mode waits for the next frame delivered *after* a capture
/// tap (not whatever frame the analyzer last cached — see NBLB-7) and
/// runs on-device OCR on its `capture.image` bytes. This *must* stay a single
/// controller: `MobileScannerController` holds the native camera session
/// through a process-wide static owner field (confirmed by reading the
/// package source), so starting a second controller before the first has
/// fully released it throws "already running" — tried splitting this into
/// a controller per mode to avoid the `returnImage` cost in barcode mode,
/// and that's exactly what broke (see NBLB-6). Camera capture itself can't
/// be exercised on `flutter run -d windows` (see `CLAUDE.md`) — unverified
/// until the Codemagic/Sideloadly loop.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // Reverted NBLB-8's `formats: [BarcodeFormat.ean13]` restriction (see
  // NBLB-9) — cover-mode capture started failing outright right after that
  // change landed, and cover mode shares this same controller/analysis
  // pipeline even though it doesn't care about barcode formats at all.
  // Wasn't expected to help barcode detection much anyway (mobile_scanner's
  // own default is already "detect everything"); not worth the risk of it
  // being what's starving cover mode of frames.
  final _controller = MobileScannerController(returnImage: true);
  final _lookupService = BookLookupService();
  final _textRecognizer = TextRecognizer();
  final _recentIsbns = <String>{};

  _ScanMode _mode = _ScanMode.barcode;
  int _scannedCount = 0;
  bool _showHint = false;
  bool _busy = false;
  Timer? _hintTimer;
  StreamSubscription<BarcodeCapture>? _subscription;
  Completer<BarcodeCapture>? _freshFrameRequest;

  @override
  void initState() {
    super.initState();
    _subscription = _controller.barcodes.listen(_onCapture, onError: _onScanError);
    _armHintTimer();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _subscription?.cancel();
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  void _onScanError(Object error, StackTrace stackTrace) {
    debugPrint('ScanScreen: camera stream error: $error');
  }

  void _armHintTimer() {
    _hintTimer?.cancel();
    setState(() => _showHint = false);
    _hintTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted && _mode == _ScanMode.barcode && _scannedCount == 0) {
        setState(() => _showHint = true);
      }
    });
  }

  void _onCapture(BarcodeCapture capture) {
    final pendingFrame = _freshFrameRequest;
    if (pendingFrame != null && !pendingFrame.isCompleted) {
      pendingFrame.complete(capture);
    }
    if (_mode != _ScanMode.barcode || _busy) return;
    if (capture.barcodes.isEmpty) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      // Log every raw detection (format + value + length), not just ones
      // that pass the ISBN filter below — this is the only way to tell,
      // from a future device run, whether Vision is detecting nothing at
      // all vs. detecting something the filter then rejects (e.g. a
      // shorter/longer payload than a plain EAN-13, or a non-EAN format).
      debugPrint('ScanScreen: detected barcode format=${barcode.format} raw=$raw');
      if (raw == null) continue;
      if (!(raw.startsWith('978') || raw.startsWith('979')) || raw.length != 13) continue;
      if (!_recentIsbns.add(raw)) continue;
      _lookupIsbn(raw);
      break;
    }
  }

  Future<void> _lookupIsbn(String isbn) async {
    setState(() => _busy = true);
    final result = await _lookupService.lookupIsbn(isbn);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result == null) return;
    _addToQueue(result);
  }

  void _addToQueue(BookLookupResult result) {
    final connection = ref.read(notionConnectionProvider);
    if (connection is! NotionConnected) return;
    final existingBooks = ref.read(booksProvider).valueOrNull ?? [];
    ref.read(scanQueueProvider.notifier).addFromLookup(
          result,
          booksRepository: BooksRepository(NotionApi()),
          existingBooks: existingBooks,
        );
    setState(() => _scannedCount++);
    _armHintTimer();
  }

  Future<void> _captureCover() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // Wait for a frame delivered strictly after this tap, instead of
      // reusing whatever the analyzer last cached: frame delivery is
      // throttled (`detectionTimeoutMs`), so a cached frame from just
      // before a quick reframe/mode-switch could otherwise still show
      // whatever the camera was pointed at a moment earlier.
      final request = Completer<BarcodeCapture>();
      _freshFrameRequest = request;
      final capture = await request.future.timeout(const Duration(seconds: 5));
      final image = capture.image;
      if (image == null) throw StateError('captured frame had no image bytes');

      final file = await File(
        '${Directory.systemTemp.path}/shelf_cover_${DateTime.now().microsecondsSinceEpoch}.jpg',
      ).writeAsBytes(image);
      final recognized = await _textRecognizer.processImage(InputImage.fromFilePath(file.path));
      await file.delete();
      if (!mounted) return;
      setState(() => _busy = false);
      final guess = recognized.text.trim();
      debugPrint('ScanScreen: OCR guess (${guess.length} chars): $guess');
      if (guess.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scanCoverNoText)));
        return;
      }
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OcrCandidatesScreen(ocrGuess: guess)));
    } catch (e) {
      debugPrint('ScanScreen: cover capture failed: $e');
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scanCoverCaptureFailed('$e'))));
      }
    } finally {
      _freshFrameRequest = null;
    }
  }

  void _setMode(_ScanMode mode) {
    setState(() => _mode = mode);
    _armHintTimer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = ref.watch(colorTokensProvider(MediaQuery.platformBrightnessOf(context)));
    final queue = ref.watch(scanQueueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(l10n.scanCancel, style: const TextStyle(color: Colors.white)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: tokens.accentSoft, borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
                    child: Text(
                      l10n.scannedCount(_scannedCount),
                      style: TextStyle(color: tokens.accent, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
              child: _ModeToggle(tokens: tokens, l10n: l10n, mode: _mode, onChanged: _setMode),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Barcode mode restricts native analysis to the same
                      // rect the guide box shows — excludes surrounding
                      // clutter/glare instead of scanning the full frame.
                      // Cover mode needs the whole frame (OCR reads more
                      // than what's in the guide), so no window there.
                      final scanWindow = _mode == _ScanMode.barcode
                          ? Rect.fromCenter(center: constraints.biggest.center(Offset.zero), width: 220, height: 220)
                          : null;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          MobileScanner(
                            controller: _controller,
                            scanWindow: scanWindow,
                            errorBuilder: (context, error) {
                              debugPrint('ScanScreen: camera init error: ${error.errorCode} ${error.errorDetails?.message}');
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    l10n.scanCameraError(error.errorDetails?.message ?? error.errorCode.name),
                                    style: const TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: tokens.accent.withValues(alpha: 0.7), width: 2),
                              borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
                            ),
                            // Cover mode frames a portrait book cover, not a
                            // square barcode target — a square guide made it
                            // hard to center a rectangular cover.
                            width: _mode == _ScanMode.cover ? 190 : 220,
                            height: _mode == _ScanMode.cover ? 270 : 220,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: ValueListenableBuilder<MobileScannerState>(
                              valueListenable: _controller,
                              builder: (context, state, _) {
                                final torchOn = state.torchState == TorchState.on;
                                return GestureDetector(
                                  onTap: () => _controller.toggleTorch(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: torchOn ? tokens.accent : Colors.black.withValues(alpha: 0.4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(torchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 20),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (_mode == _ScanMode.cover)
                            Positioned(
                              bottom: 20,
                              child: GestureDetector(
                                onTap: _captureCover,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: tokens.accent, width: 3),
                                  ),
                                  child: _busy
                                      ? const Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(strokeWidth: 2))
                                      : null,
                                ),
                              ),
                            ),
                          if (_showHint)
                            Positioned(
                              bottom: _mode == _ScanMode.cover ? 96 : 20,
                              child: Text(
                                l10n.scanHint,
                                style: TextStyle(color: tokens.accent, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (queue.isNotEmpty) _ThumbnailStrip(tokens: tokens, queue: queue),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: queue.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QueueScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white24,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
                  ),
                  child: Text(l10n.reviewQueue(queue.length), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final AppColorTokens tokens;
  final AppLocalizations l10n;
  final _ScanMode mode;
  final ValueChanged<_ScanMode> onChanged;

  const _ModeToggle({required this.tokens, required this.l10n, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppSpacing.pillRadius)),
      child: Row(
        children: [
          Expanded(child: _segment(l10n.modeBarcode, _ScanMode.barcode)),
          Expanded(child: _segment(l10n.modeCover, _ScanMode.cover)),
        ],
      ),
    );
  }

  Widget _segment(String label, _ScanMode value) {
    final active = mode == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius - 4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ThumbnailStrip extends StatelessWidget {
  final AppColorTokens tokens;
  final List<QueueItem> queue;

  const _ThumbnailStrip({required this.tokens, required this.queue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontalPadding, vertical: 8),
        itemCount: queue.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: genreColor(queue[i].confirmedGenre ?? ''),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
