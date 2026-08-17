import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @shelfTitle.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get shelfTitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabGenre.
  ///
  /// In en, this message translates to:
  /// **'By genre'**
  String get tabGenre;

  /// No description provided for @tabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// No description provided for @homeNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Connect to Notion in Settings to see your shelf.'**
  String get homeNotConnected;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your books: {message}'**
  String homeLoadError(String message);

  /// No description provided for @filterByGenre.
  ///
  /// In en, this message translates to:
  /// **'Filter by genre'**
  String get filterByGenre;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your shelf is empty'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode or cover to catalog your first book.'**
  String get emptyMessage;

  /// No description provided for @emptyCta.
  ///
  /// In en, this message translates to:
  /// **'Scan your first book'**
  String get emptyCta;

  /// No description provided for @emptyManual.
  ///
  /// In en, this message translates to:
  /// **'or add manually'**
  String get emptyManual;

  /// No description provided for @addSheetScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a book'**
  String get addSheetScan;

  /// No description provided for @addSheetManual.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addSheetManual;

  /// No description provided for @scanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scanCancel;

  /// No description provided for @modeBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get modeBarcode;

  /// No description provided for @modeCover.
  ///
  /// In en, this message translates to:
  /// **'Cover photo'**
  String get modeCover;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'No barcode found — try \"Cover photo\" above'**
  String get scanHint;

  /// No description provided for @tapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap to simulate a scan'**
  String get tapToScan;

  /// No description provided for @scanCameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {message}'**
  String scanCameraError(String message);

  /// No description provided for @scanCoverCaptureFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t capture the cover photo — try again.'**
  String get scanCoverCaptureFailed;

  /// No description provided for @scanCoverNoText.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read any text on that cover — try again or search manually.'**
  String get scanCoverNoText;

  /// No description provided for @scannedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} scanned'**
  String scannedCount(int count);

  /// No description provided for @reviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Review queue ({count})'**
  String reviewQueue(int count);

  /// No description provided for @queueTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} books scanned'**
  String queueTitle(int count);

  /// No description provided for @addReadyNow.
  ///
  /// In en, this message translates to:
  /// **'Add {count} ready now'**
  String addReadyNow(int count);

  /// No description provided for @statusReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get statusReady;

  /// No description provided for @statusDuplicate.
  ///
  /// In en, this message translates to:
  /// **'duplicate'**
  String get statusDuplicate;

  /// No description provided for @statusNeedsGenre.
  ///
  /// In en, this message translates to:
  /// **'genre?'**
  String get statusNeedsGenre;

  /// No description provided for @ocrTitle.
  ///
  /// In en, this message translates to:
  /// **'Which book did you scan?'**
  String get ocrTitle;

  /// No description provided for @ocrReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Text read from the cover:'**
  String get ocrReadLabel;

  /// No description provided for @ocrNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found for that text.'**
  String get ocrNoMatches;

  /// No description provided for @ocrNone.
  ///
  /// In en, this message translates to:
  /// **'None of these — search manually'**
  String get ocrNone;

  /// No description provided for @manualSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'OCR read (edit if wrong):'**
  String get manualSearchLabel;

  /// No description provided for @dedupeTitle.
  ///
  /// In en, this message translates to:
  /// **'Matched by title + author'**
  String get dedupeTitle;

  /// No description provided for @dedupeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'(no ISBN on file to compare)'**
  String get dedupeSubtitle;

  /// No description provided for @onShelf.
  ///
  /// In en, this message translates to:
  /// **'On your shelf'**
  String get onShelf;

  /// No description provided for @thisScan.
  ///
  /// In en, this message translates to:
  /// **'This scan'**
  String get thisScan;

  /// No description provided for @missing.
  ///
  /// In en, this message translates to:
  /// **'missing'**
  String get missing;

  /// No description provided for @fillMissing.
  ///
  /// In en, this message translates to:
  /// **'Fill in missing details'**
  String get fillMissing;

  /// No description provided for @addSeparate.
  ///
  /// In en, this message translates to:
  /// **'Add as separate book'**
  String get addSeparate;

  /// No description provided for @genreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genreConfirmTitle;

  /// No description provided for @fromApi.
  ///
  /// In en, this message translates to:
  /// **'from API:'**
  String get fromApi;

  /// No description provided for @manualEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add book manually'**
  String get manualEntryTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get fieldSubtitle;

  /// No description provided for @fieldIsbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get fieldIsbn;

  /// No description provided for @fieldPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get fieldPages;

  /// No description provided for @fieldDatePublished.
  ///
  /// In en, this message translates to:
  /// **'Date published'**
  String get fieldDatePublished;

  /// No description provided for @fieldCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get fieldCover;

  /// No description provided for @fieldAuthors.
  ///
  /// In en, this message translates to:
  /// **'Authors'**
  String get fieldAuthors;

  /// No description provided for @fieldGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get fieldGenres;

  /// No description provided for @fieldCoverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL (optional)'**
  String get fieldCoverUrlHint;

  /// No description provided for @saveBook.
  ///
  /// In en, this message translates to:
  /// **'Save book'**
  String get saveBook;

  /// No description provided for @manualEntrySaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get manualEntrySaving;

  /// No description provided for @manualEntryError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {message}'**
  String manualEntryError(String message);

  /// No description provided for @detailBack.
  ///
  /// In en, this message translates to:
  /// **'‹ Back'**
  String get detailBack;

  /// No description provided for @detailIsbn.
  ///
  /// In en, this message translates to:
  /// **'ISBN'**
  String get detailIsbn;

  /// No description provided for @detailPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get detailPages;

  /// No description provided for @detailPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get detailPublished;

  /// No description provided for @detailGenres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get detailGenres;

  /// No description provided for @readingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Reading status (read-only)'**
  String get readingStatusLabel;

  /// No description provided for @readingOwnedNote.
  ///
  /// In en, this message translates to:
  /// **'Owned by Habits — Shelf never edits these'**
  String get readingOwnedNote;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @currentPageLabel.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get currentPageLabel;

  /// No description provided for @statusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statusNotStarted;

  /// No description provided for @pageDash.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get pageDash;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @ob1Title.
  ///
  /// In en, this message translates to:
  /// **'Meet Shelf'**
  String get ob1Title;

  /// No description provided for @ob1Body.
  ///
  /// In en, this message translates to:
  /// **'Shelf catalogs your physical books — title, author, ISBN, pages, genres. It does not track your reading progress; that lives in Habits.'**
  String get ob1Body;

  /// No description provided for @ob2Title.
  ///
  /// In en, this message translates to:
  /// **'Three ways to add a book'**
  String get ob2Title;

  /// No description provided for @ob2BodyScan.
  ///
  /// In en, this message translates to:
  /// **'Scan a barcode for instant lookup'**
  String get ob2BodyScan;

  /// No description provided for @ob2BodyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Snap a cover photo and let OCR read it'**
  String get ob2BodyPhoto;

  /// No description provided for @ob2BodyManual.
  ///
  /// In en, this message translates to:
  /// **'Or type in the details yourself'**
  String get ob2BodyManual;

  /// No description provided for @ob3Title.
  ///
  /// In en, this message translates to:
  /// **'Duplicates get caught automatically'**
  String get ob3Title;

  /// No description provided for @ob3Body.
  ///
  /// In en, this message translates to:
  /// **'If a scan matches a book already on your shelf, Shelf flags it so you can merge details instead of creating a copy.'**
  String get ob3Body;

  /// No description provided for @obScanCta.
  ///
  /// In en, this message translates to:
  /// **'Scan your first book'**
  String get obScanCta;

  /// No description provided for @obSkipToShelf.
  ///
  /// In en, this message translates to:
  /// **'Skip to shelf'**
  String get obSkipToShelf;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsNotion.
  ///
  /// In en, this message translates to:
  /// **'Notion connection'**
  String get settingsNotion;

  /// No description provided for @settingsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Notion'**
  String get settingsConnected;

  /// No description provided for @settingsWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Notion workspace'**
  String get settingsWorkspace;

  /// No description provided for @settingsReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get settingsReconnect;

  /// No description provided for @settingsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// No description provided for @settingsNotionTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Notion integration token'**
  String get settingsNotionTokenHint;

  /// No description provided for @settingsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get settingsConnect;

  /// No description provided for @settingsConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get settingsConnecting;

  /// No description provided for @settingsAccessibleDatabases.
  ///
  /// In en, this message translates to:
  /// **'Accessible databases'**
  String get settingsAccessibleDatabases;

  /// No description provided for @settingsNoDatabasesFound.
  ///
  /// In en, this message translates to:
  /// **'No databases shared with this integration yet.'**
  String get settingsNoDatabasesFound;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent theme'**
  String get settingsAccent;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About Shelf'**
  String get settingsAbout;

  /// No description provided for @settingsAboutBody.
  ///
  /// In en, this message translates to:
  /// **'Shelf owns your catalog: title, author, ISBN, pages, publication date, and genres. Reading status, current page, and ratings belong to Habits — Shelf shows them but never edits them.'**
  String get settingsAboutBody;

  /// No description provided for @settingsViewOnboarding.
  ///
  /// In en, this message translates to:
  /// **'View onboarding again'**
  String get settingsViewOnboarding;

  /// No description provided for @themeTerracotta.
  ///
  /// In en, this message translates to:
  /// **'Terracotta'**
  String get themeTerracotta;

  /// No description provided for @themeVertRouge.
  ///
  /// In en, this message translates to:
  /// **'Green & red'**
  String get themeVertRouge;

  /// No description provided for @themeAmbreArdoise.
  ///
  /// In en, this message translates to:
  /// **'Amber & slate'**
  String get themeAmbreArdoise;

  /// No description provided for @themeSarcelleRouille.
  ///
  /// In en, this message translates to:
  /// **'Teal & rust'**
  String get themeSarcelleRouille;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Not built yet'**
  String get comingSoon;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
