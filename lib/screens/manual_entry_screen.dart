import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/books_provider.dart';
import '../providers/notion_connection_provider.dart';
import '../providers/theme_provider.dart';
import '../repositories/books_repository.dart';
import '../services/notion_api.dart';
import '../theme/color_tokens.dart';
import '../theme/spacing.dart';

/// Manual book entry (design screen 10) — the scan pipeline's last-resort
/// identification method, and the first screen to exercise the write path
/// added in NBLM-6. Bypasses the queue/dedupe/genre-confirm flow entirely,
/// same as the design spec: genres are picked directly here, not suggested.
class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _pagesController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _authorsController = TextEditingController();

  DateTime? _publishedDate;
  final Set<String> _selectedGenres = {};
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _isbnController.dispose();
    _pagesController.dispose();
    _coverUrlController.dispose();
    _authorsController.dispose();
    super.dispose();
  }

  bool get _canSave => _titleController.text.trim().isNotEmpty && !_saving;

  Future<void> _save(AppLocalizations l10n) async {
    final connection = ref.read(notionConnectionProvider);
    if (connection is! NotionConnected ||
        connection.booksDatabaseId == null ||
        connection.authorsDatabaseId == null ||
        connection.genresDatabaseId == null) {
      return;
    }
    setState(() => _saving = true);
    final authorNames = _authorsController.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();
    try {
      await BooksRepository(NotionApi()).createBook(
        token: connection.token,
        booksDbId: connection.booksDatabaseId!,
        authorsDbId: connection.authorsDatabaseId!,
        genresDbId: connection.genresDatabaseId!,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty ? null : _subtitleController.text.trim(),
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        pages: int.tryParse(_pagesController.text.trim()),
        publishedDate: _publishedDate,
        coverUrl: _coverUrlController.text.trim().isEmpty ? null : _coverUrlController.text.trim(),
        authorNames: authorNames,
        genreNames: _selectedGenres.toList(),
      );
      ref.invalidate(booksProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.manualEntryError('$e'))));
      }
    }
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
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text(l10n.cancel, style: TextStyle(color: tokens.text)),
                      ),
                    ),
                  ),
                  Text(
                    l10n.manualEntryTitle,
                    style: TextStyle(color: tokens.text, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _canSave ? () => _save(l10n) : null,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: Text(
                          _saving ? l10n.manualEntrySaving : l10n.save,
                          style: TextStyle(color: _canSave ? tokens.accent : tokens.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
                children: [
          _Field(tokens: tokens, label: l10n.fieldTitle, controller: _titleController, onChanged: () => setState(() {})),
          const SizedBox(height: 14),
          _Field(tokens: tokens, label: l10n.fieldSubtitle, controller: _subtitleController),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Field(tokens: tokens, label: l10n.fieldIsbn, controller: _isbnController)),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  tokens: tokens,
                  label: l10n.fieldPages,
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _DateField(tokens: tokens, label: l10n.fieldDatePublished, value: _publishedDate, onPick: _pickDate)),
              const SizedBox(width: 12),
              Expanded(
                child: _Field(
                  tokens: tokens,
                  label: l10n.fieldCover,
                  hint: l10n.fieldCoverUrlHint,
                  controller: _coverUrlController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Field(tokens: tokens, label: l10n.fieldAuthors, controller: _authorsController),
          const SizedBox(height: 14),
          Text(l10n.fieldGenres, style: TextStyle(color: tokens.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genreHues.keys
                .map((genre) => _GenreChip(
                      tokens: tokens,
                      label: genre,
                      selected: _selectedGenres.contains(genre),
                      onTap: () => setState(() {
                        if (!_selectedGenres.remove(genre)) _selectedGenres.add(genre);
                      }),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave ? () => _save(l10n) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: tokens.accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: tokens.track,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius)),
              ),
              child: Text(
                _saving ? l10n.manualEntrySaving : l10n.saveBook,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedDate ?? DateTime.now(),
      firstDate: DateTime(1400),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _publishedDate = picked);
  }
}

class _Field extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final VoidCallback? onChanged;

  const _Field({
    required this.tokens,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tokens.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged == null ? null : (_) => onChanged!(),
          style: TextStyle(color: tokens.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
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
    );
  }
}

class _DateField extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final DateTime? value;
  final VoidCallback onPick;

  const _DateField({required this.tokens, required this.label, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: tokens.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(AppSpacing.stepperButtonRadius),
              border: Border.all(color: tokens.border),
            ),
            child: Text(
              value == null ? '—' : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}',
              style: TextStyle(color: value == null ? tokens.muted : tokens.text, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenreChip extends StatelessWidget {
  final AppColorTokens tokens;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip({required this.tokens, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.accentSoft : tokens.surface,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(color: selected ? tokens.accent : tokens.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? tokens.accent : tokens.text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
