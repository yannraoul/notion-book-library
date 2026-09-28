import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../l10n/app_localizations.dart';
import '../providers/authors_provider.dart';
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

/// Design screens 03/04 — the scan viewfinder. Barcode mode reads
/// `MobileScannerController.barcodes`. Cover-photo mode does NOT use that
/// stream for its image: on iOS, `mobile_scanner` only emits an event when
/// Vision actually finds a barcode (`if results.isEmpty { return }` in the
/// plugin's `captureOutput`), so a cover with no barcode in view never
/// delivers a frame — that was the root cause of the recurring "cover capture
/// times out" bugs (NBLB-3/7/9/10). Cover mode instead stops the scanner and
/// opens the native camera via `image_picker`, then runs on-device OCR on the
/// resulting file (NBLB-12). `MobileScanner` itself stays continuously
/// mounted in both modes — cover mode just covers it with an opaque static
/// prompt instead of unmounting it, since unmounting/remounting it re-runs
/// its own start/stop lifecycle on the same controller and NBLB-6 already
/// found that race-prone (NBLB-13). The scanner also stays a single
/// controller (NBLB-6). Camera capture can't be exercised on
/// `flutter run -d windows` (see `CLAUDE.md`).
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  // No `scanWindow`/`formats` restriction: Vision's `regionOfInterest` needs
  // the whole barcode inside the window, and the 220pt window added in NBLB-8
  // is the likely cause of previously-scannable barcodes going undetected
  // (NBLB-12). The on-screen guide box is cosmetic only.
  final _controller = MobileScannerController();
  final _lookupService = BookLookupService();
  final _textRecognizer = TextRecognizer();
  final _recentIsbns = <String>{};

  _ScanMode _mode = _ScanMode.barcode;
  int _scannedCount = 0;
  bool _showHint = false;
  bool _busy = false;
  Timer? _hintTimer;
  StreamSubscription<BarcodeCapture>? _subscription;
  final _picker = ImagePicker();

  // On-screen detection diagnostics — the only way to see what Vision is
  // actually reporting on-device without a Mac console (NBLB-13). Remove
  // once barcode detection is confirmed working reliably again.
  int _detectionCount = 0;
  String? _lastDetectionDebug;

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
    if (_mode != _ScanMode.barcode || _busy) return;
    if (capture.barcodes.isEmpty) return;
    // Log every raw detection (format + value + length), not just ones that
    // pass the ISBN filter below, and mirror it on-screen (`_lastDetectionDebug`)
    // since debugPrint output isn't visible on a device without a Mac console
    // — this is the only way to tell, from the next on-device run, whether
    // Vision is detecting nothing at all vs. detecting something the filter
    // then rejects (e.g. a shorter/longer payload than a plain EAN-13, or a
    // non-EAN format).
    final first = capture.barcodes.first;
    debugPrint('ScanScreen: detected barcode format=${first.format} raw=${first.rawValue}');
    setState(() {
      _detectionCount++;
      _lastDetectionDebug = '${first.format.name} "${first.rawValue ?? ''}" (len ${first.rawValue?.length ?? 0})';
    });
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
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
    final existingAuthorNames = ref.read(authorNamesProvider).valueOrNull ?? {};
    ref.read(scanQueueProvider.notifier).addFromLookup(
          result,
          booksRepository: BooksRepository(NotionApi()),
          existingBooks: existingBooks,
          existingAuthorNames: existingAuthorNames,
        );
    setState(() => _scannedCount++);
    _armHintTimer();
  }

  Future<void> _captureCover() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // The live scanner holds the camera session; release it before the
      // native camera opens, and resume it afterwards.
      await _controller.stop();
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 2000, imageQuality: 85);
      unawaited(_controller.start().catchError((Object e) => debugPrint('ScanScreen: camera restart failed: $e')));
      if (photo == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final recognized = await _textRecognizer.processImage(InputImage.fromFilePath(photo.path));
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
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Stays mounted in both modes — see the class doc
                          // comment for why (NBLB-13).
                          MobileScanner(
                            controller: _controller,
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
                          if (_mode == _ScanMode.cover)
                            // Opaque cover over the live feed above — tapping
                            // the shutter opens iOS's own camera, so showing
                            // Shelf's live feed right up to that moment made
                            // it look like two cameras stacked on each other
                            // (NBLB-13).
                            Positioned.fill(
                              child: Container(
                                color: const Color(0xFF0a0a0a),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.menu_book_rounded, size: 48, color: tokens.accent),
                                      const SizedBox(height: 16),
                                      Text(
                                        l10n.scanCoverPrompt,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_mode == _ScanMode.barcode) ...[
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: tokens.accent.withValues(alpha: 0.7), width: 2),
                                borderRadius: BorderRadius.circular(AppSpacing.settingsCardRadius),
                              ),
                              width: 220,
                              height: 220,
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
                            if (_showHint)
                              Positioned(
                                bottom: 20,
                                child: Text(
                                  l10n.scanHint,
                                  style: TextStyle(color: tokens.accent, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            // Temporary on-device diagnostics — see
                            // `_detectionCount`'s doc comment.
                            Positioned(
                              bottom: 46,
                              child: Text(
                                l10n.scanDebugInfo(_detectionCount, _lastDetectionDebug ?? '—'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                              ),
                            ),
                          ],
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
