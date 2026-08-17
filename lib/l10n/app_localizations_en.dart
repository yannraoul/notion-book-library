// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navSettings => 'Settings';

  @override
  String get shelfTitle => 'Shelf';

  @override
  String get tabAll => 'All';

  @override
  String get tabGenre => 'By genre';

  @override
  String get tabRecent => 'Recent';

  @override
  String get homeNotConnected =>
      'Connect to Notion in Settings to see your shelf.';

  @override
  String homeLoadError(String message) {
    return 'Couldn\'t load your books: $message';
  }

  @override
  String get filterByGenre => 'Filter by genre';

  @override
  String get apply => 'Apply';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get emptyTitle => 'Your shelf is empty';

  @override
  String get emptyMessage =>
      'Scan a barcode or cover to catalog your first book.';

  @override
  String get emptyCta => 'Scan your first book';

  @override
  String get emptyManual => 'or add manually';

  @override
  String get addSheetScan => 'Scan a book';

  @override
  String get addSheetManual => 'Add manually';

  @override
  String get scanCancel => 'Cancel';

  @override
  String get modeBarcode => 'Barcode';

  @override
  String get modeCover => 'Cover photo';

  @override
  String get scanHint => 'No barcode found — try \"Cover photo\" above';

  @override
  String get tapToScan => 'Tap to simulate a scan';

  @override
  String scannedCount(int count) {
    return '$count scanned';
  }

  @override
  String reviewQueue(int count) {
    return 'Review queue ($count)';
  }

  @override
  String queueTitle(int count) {
    return '$count books scanned';
  }

  @override
  String addReadyNow(int count) {
    return 'Add $count ready now';
  }

  @override
  String get statusReady => 'ready';

  @override
  String get statusDuplicate => 'duplicate';

  @override
  String get statusNeedsGenre => 'genre?';

  @override
  String get ocrTitle => 'Which book did you scan?';

  @override
  String get ocrNone => 'None of these — search manually';

  @override
  String get manualSearchLabel => 'OCR read (edit if wrong):';

  @override
  String get dedupeTitle => 'Matched by title + author';

  @override
  String get dedupeSubtitle => '(no ISBN on file to compare)';

  @override
  String get onShelf => 'On your shelf';

  @override
  String get thisScan => 'This scan';

  @override
  String get missing => 'missing';

  @override
  String get fillMissing => 'Fill in missing details';

  @override
  String get addSeparate => 'Add as separate book';

  @override
  String get genreConfirmTitle => 'Genre';

  @override
  String get fromApi => 'from API:';

  @override
  String get manualEntryTitle => 'Add book manually';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldSubtitle => 'Subtitle';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldPages => 'Pages';

  @override
  String get fieldDatePublished => 'Date published';

  @override
  String get fieldCover => 'Cover';

  @override
  String get fieldAuthors => 'Authors';

  @override
  String get fieldGenres => 'Genres';

  @override
  String get fieldCoverUrlHint => 'Cover image URL (optional)';

  @override
  String get saveBook => 'Save book';

  @override
  String get manualEntrySaving => 'Saving…';

  @override
  String manualEntryError(String message) {
    return 'Couldn\'t save: $message';
  }

  @override
  String get detailBack => '‹ Back';

  @override
  String get detailIsbn => 'ISBN';

  @override
  String get detailPages => 'Pages';

  @override
  String get detailPublished => 'Published';

  @override
  String get detailGenres => 'Genres';

  @override
  String get readingStatusLabel => 'Reading status (read-only)';

  @override
  String get readingOwnedNote => 'Owned by Habits — Shelf never edits these';

  @override
  String get statusLabel => 'Status';

  @override
  String get currentPageLabel => 'Page';

  @override
  String get statusNotStarted => 'Not started';

  @override
  String get pageDash => '—';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get ob1Title => 'Meet Shelf';

  @override
  String get ob1Body =>
      'Shelf catalogs your physical books — title, author, ISBN, pages, genres. It does not track your reading progress; that lives in Habits.';

  @override
  String get ob2Title => 'Three ways to add a book';

  @override
  String get ob2BodyScan => 'Scan a barcode for instant lookup';

  @override
  String get ob2BodyPhoto => 'Snap a cover photo and let OCR read it';

  @override
  String get ob2BodyManual => 'Or type in the details yourself';

  @override
  String get ob3Title => 'Duplicates get caught automatically';

  @override
  String get ob3Body =>
      'If a scan matches a book already on your shelf, Shelf flags it so you can merge details instead of creating a copy.';

  @override
  String get obScanCta => 'Scan your first book';

  @override
  String get obSkipToShelf => 'Skip to shelf';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsNotion => 'Notion connection';

  @override
  String get settingsConnected => 'Connected to Notion';

  @override
  String get settingsWorkspace => 'Notion workspace';

  @override
  String get settingsReconnect => 'Reconnect';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String get settingsNotionTokenHint => 'Notion integration token';

  @override
  String get settingsConnect => 'Connect';

  @override
  String get settingsConnecting => 'Connecting…';

  @override
  String get settingsAccessibleDatabases => 'Accessible databases';

  @override
  String get settingsNoDatabasesFound =>
      'No databases shared with this integration yet.';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsAccent => 'Accent theme';

  @override
  String get settingsAbout => 'About Shelf';

  @override
  String get settingsAboutBody =>
      'Shelf owns your catalog: title, author, ISBN, pages, publication date, and genres. Reading status, current page, and ratings belong to Habits — Shelf shows them but never edits them.';

  @override
  String get settingsViewOnboarding => 'View onboarding again';

  @override
  String get themeTerracotta => 'Terracotta';

  @override
  String get themeVertRouge => 'Green & red';

  @override
  String get themeAmbreArdoise => 'Amber & slate';

  @override
  String get themeSarcelleRouille => 'Teal & rust';

  @override
  String get comingSoon => 'Not built yet';
}
