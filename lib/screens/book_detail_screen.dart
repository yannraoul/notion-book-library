import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/book.dart';
import '../providers/books_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/books_repository.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/author_chip_input.dart';
import '../widgets/book_cover.dart';
import '../widgets/genre_chip.dart';

/// Design screen 10 — book detail. Read-only by default (plain text, no
/// input chrome anywhere) to avoid a stray tap editing a Notion field by
/// accident — tapping "Edit" switches every Shelf-owned field to an
/// editable draft; "Save" commits the whole draft in one write and returns
/// to read-only, "Cancel" discards it. The reading-status card is never
/// part of that draft and never editable in either mode: Shelf must never
/// write `Status`/`Current page`/`Date started`/`Date finished`/`Rating`,
/// that stays Habits' job forever (see `CLAUDE.md`).
class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late Book _book;
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _pagesController = TextEditingController();
  final _coverUrlController = TextEditingController();

  bool _editing = false;
  bool _saving = false;
  DateTime? _draftPublishedDate;
  List<String> _draftAuthors = [];
  Set<String> _draftGenres = {};

  /// A freshly-picked local image, staged for upload on Save — takes
  /// priority over [_coverUrlController] when both are set (picking a file
  /// clears the URL field, see [_pickCoverImage]). Previewed immediately
  /// via `Image.memory` since we already have the bytes, without waiting
  /// for the round trip to Notion.
  Uint8List? _draftCoverBytes;
  String? _draftCoverFilename;

  List<String>? _liveGenres;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadGenres();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _pagesController.dispose();
    _coverUrlController.dispose();
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

  void _startEditing() {
    _titleController.text = _book.title;
    _isbnController.text = _book.isbn ?? '';
    _pagesController.text = _book.pages?.toString() ?? '';
    _coverUrlController.text = _book.coverUrl ?? '';
    setState(() {
      _draftPublishedDate = _book.publishedDate;
      _draftAuthors = List.of(_book.authors);
      _draftGenres = Set.of(_book.genres);
      _draftCoverBytes = null;
      _draftCoverFilename = null;
      _editing = true;
    });
  }

  void _cancelEditing() => setState(() => _editing = false);

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _draftCoverBytes = file.bytes;
      _draftCoverFilename = file.name;
      _coverUrlController.clear();
    });
  }

  String _guessImageContentType(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }

  Future<void> _save() async {
    final connection = ref.read(notionConnectionProvider);
    if (connection is! NotionConnected || connection.authorsDatabaseId == null || connection.genresDatabaseId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await BooksRepository(NotionApi()).updateBook(
        token: connection.token,
        authorsDbId: connection.authorsDatabaseId!,
        genresDbId: connection.genresDatabaseId!,
        current: _book,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        pages: int.tryParse(_pagesController.text.trim()),
        publishedDate: _draftPublishedDate,
        coverUrl: _draftCoverBytes == null ? _coverUrlController.text.trim() : null,
        coverImageBytes: _draftCoverBytes,
        coverImageFilename: _draftCoverFilename,
        coverImageContentType: _draftCoverFilename == null ? null : _guessImageContentType(_draftCoverFilename!),
        authorNames: _draftAuthors,
        genreNames: _draftGenres.toList(),
      );
      ref.invalidate(booksProvider);
      if (mounted) setState(() => _book = updated);
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manualEntryError('$e'))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPublishedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftPublishedDate ?? DateTime.now(),
      firstDate: DateTime(1400),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _draftPublishedDate = picked);
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _saving ? null : (_editing ? _cancelEditing : () => Navigator.of(context).pop()),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(_editing ? l10n.cancel : l10n.detailBack, style: TextStyle(color: tokens.text)),
                  ),
                  TextButton(
                    onPressed: _saving ? null : (_editing ? _save : _startEditing),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    child: Text(
                      _editing ? (_saving ? l10n.manualEntrySaving : l10n.save) : l10n.detailEdit,
                      style: TextStyle(color: tokens.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontalPadding,
                  0,
                  AppSpacing.screenHorizontalPadding,
                  AppSpacing.screenHorizontalPadding,
                ),
                children: [
                  Center(
                    child: _draftCoverBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(_draftCoverBytes!, width: 150, height: 225, fit: BoxFit.cover),
                          )
                        : BookCover(book: _book, width: 150, height: 225),
                  ),
                  if (_editing) ...[
                    const SizedBox(height: 10),
                    Text(l10n.fieldCover, textAlign: TextAlign.center, style: AppTypography.sectionLabel(tokens.muted)),
                    const SizedBox(height: 6),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: _pickCoverImage,
                        icon: const Icon(Icons.upload_rounded, size: 16),
                        label: Text(l10n.coverUploadButton, style: const TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: tokens.text,
                          side: BorderSide(color: tokens.border),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.coverUrlOrHint, textAlign: TextAlign.center, style: TextStyle(color: tokens.muted, fontSize: 11.5)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _coverUrlController,
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {
                        _draftCoverBytes = null;
                        _draftCoverFilename = null;
                      }),
                      style: TextStyle(color: tokens.text, fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l10n.fieldCoverUrlHint,
                        hintStyle: TextStyle(color: tokens.muted, fontSize: 12.5),
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
                  ],
                  const SizedBox(height: 18),
                  if (_editing)
                    TextField(
                      controller: _titleController,
                      textAlign: TextAlign.center,
                      style: AppTypography.detailTitle(tokens.text),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tokens.accent, width: 1.5)),
                      ),
                    )
                  else
                    Text(_book.title, textAlign: TextAlign.center, style: AppTypography.detailTitle(tokens.text)),
                  const SizedBox(height: 10),
                  if (_editing)
                    AuthorChipInput(authors: _draftAuthors, onChanged: (next) => setState(() => _draftAuthors = next))
                  else if (_book.authors.isNotEmpty)
                    Text(
                      _book.authors.join(', '),
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMuted(tokens.muted),
                    ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPaddingHorizontal,
                      vertical: AppSpacing.cardPaddingVertical,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(color: tokens.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MetaRow(
                          tokens: tokens,
                          label: l10n.detailIsbn,
                          child: _editing
                              ? TextField(
                                  controller: _isbnController,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(color: tokens.text, fontSize: 14),
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                )
                              : Text(_book.isbn ?? l10n.pageDash, textAlign: TextAlign.end, style: TextStyle(color: tokens.text, fontSize: 14)),
                        ),
                        const SizedBox(height: AppSpacing.cardRowGap),
                        _MetaRow(
                          tokens: tokens,
                          label: l10n.detailPages,
                          child: _editing
                              ? TextField(
                                  controller: _pagesController,
                                  textAlign: TextAlign.end,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: tokens.text, fontSize: 14),
                                  decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                                )
                              : Text(
                                  _book.pages?.toString() ?? l10n.pageDash,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(color: tokens.text, fontSize: 14),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.cardRowGap),
                        _MetaRow(
                          tokens: tokens,
                          label: l10n.detailPublished,
                          child: _editing
                              ? InkWell(
                                  onTap: _pickPublishedDate,
                                  child: Text(
                                    _draftPublishedDate == null ? l10n.pageDash : _formatDate(_draftPublishedDate!),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(color: tokens.text, fontSize: 14),
                                  ),
                                )
                              : Text(
                                  _book.publishedDate == null ? l10n.pageDash : _formatDate(_book.publishedDate!),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(color: tokens.text, fontSize: 14),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.cardRowGap),
                        Text(l10n.detailGenres, style: AppTypography.sectionLabel(tokens.muted)),
                        const SizedBox(height: 8),
                        if (_editing)
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
                                        selected: _draftGenres.contains(genre),
                                        onTap: () => setState(() {
                                          if (!_draftGenres.remove(genre)) _draftGenres.add(genre);
                                        }),
                                      ))
                                  .toList(),
                            )
                        else if (_book.genres.isEmpty)
                          Text(l10n.pageDash, style: TextStyle(color: tokens.muted, fontSize: 13))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _book.genres.map((genre) => _ReadOnlyChip(tokens: tokens, label: genre)).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.cardPaddingHorizontal,
                      vertical: AppSpacing.cardPaddingVertical,
                    ),
                    decoration: BoxDecoration(color: tokens.dark, borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.readingStatusLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l10n.readingOwnedNote, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                        const SizedBox(height: AppSpacing.cardRowGap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.statusLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              _book.reading?.status?.notionName ?? l10n.statusNotStarted,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.currentPageLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              _book.reading?.currentPage?.round().toString() ?? l10n.pageDash,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _MetaRow extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final Widget child;

  const _MetaRow({required this.tokens, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: AppTypography.sectionLabel(tokens.muted)),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );
  }
}

class _ReadOnlyChip extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;

  const _ReadOnlyChip({required this.tokens, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: tokens.accent),
      ),
      child: Text(label, style: TextStyle(color: tokens.accent, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
