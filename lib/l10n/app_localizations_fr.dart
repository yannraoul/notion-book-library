// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navSettings => 'Réglages';

  @override
  String get shelfTitle => 'Shelf';

  @override
  String get tabAll => 'Tout';

  @override
  String get tabGenre => 'Par genre';

  @override
  String get tabRecent => 'Récents';

  @override
  String get homeNotConnected =>
      'Connectez-vous à Notion dans les réglages pour voir votre étagère.';

  @override
  String homeLoadError(String message) {
    return 'Impossible de charger vos livres : $message';
  }

  @override
  String get filterByGenre => 'Filtrer par genre';

  @override
  String get filterGenreEmpty => 'Aucun genre pour l’instant.';

  @override
  String get apply => 'Appliquer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get shelfSearchHint => 'Titre, auteur, sous-titre…';

  @override
  String get shelfNoResults => 'Aucun livre ne correspond.';

  @override
  String get emptyTitle => 'Votre étagère est vide';

  @override
  String get emptyMessage =>
      'Scannez un code-barres ou une couverture pour cataloguer votre premier livre.';

  @override
  String get emptyCta => 'Scanner votre premier livre';

  @override
  String get emptyManual => 'ou ajouter manuellement';

  @override
  String get addSheetScan => 'Scanner un livre';

  @override
  String get addSheetSearch => 'Rechercher un livre';

  @override
  String get addSheetManual => 'Ajouter manuellement';

  @override
  String get scanCancel => 'Annuler';

  @override
  String get modeBarcode => 'Code-barres';

  @override
  String get modeCover => 'Photo de couverture';

  @override
  String get scanHint =>
      'Aucun code-barres trouvé — essayez « Photo de couverture »';

  @override
  String get tapToScan => 'Touchez pour simuler un scan';

  @override
  String scanCameraError(String message) {
    return 'Erreur caméra : $message';
  }

  @override
  String scanCoverCaptureFailed(String message) {
    return 'Impossible de capturer la couverture : $message';
  }

  @override
  String get scanCoverNoText =>
      'Aucun texte lisible sur cette couverture — réessayez ou recherchez manuellement.';

  @override
  String scannedCount(int count) {
    return '$count scannés';
  }

  @override
  String reviewQueue(int count) {
    return 'Vérifier la file ($count)';
  }

  @override
  String queueTitle(int count) {
    return '$count livres scannés';
  }

  @override
  String addReadyNow(int count) {
    return 'Ajouter $count maintenant';
  }

  @override
  String get statusReady => 'prêt';

  @override
  String get statusDuplicate => 'doublon';

  @override
  String get statusNeedsGenre => 'genre ?';

  @override
  String get statusNeedsAuthor => 'auteur ?';

  @override
  String get ocrTitle => 'Quel livre avez-vous scanné ?';

  @override
  String get ocrReadLabel => 'Texte lu sur la couverture :';

  @override
  String get ocrNoMatches => 'Aucune correspondance trouvée pour ce texte.';

  @override
  String get ocrNone => 'Aucun de ceux-ci — recherche manuelle';

  @override
  String get manualSearchLabel => 'Lecture OCR (modifiez si erronée) :';

  @override
  String get dedupeTitle => 'Correspondance par titre + auteur';

  @override
  String get dedupeSubtitle => '(pas d’ISBN au dossier)';

  @override
  String get onShelf => 'Sur votre étagère';

  @override
  String get thisScan => 'Ce scan';

  @override
  String get missing => 'manquant';

  @override
  String get fillMissing => 'Compléter les détails manquants';

  @override
  String get addSeparate => 'Ajouter comme livre séparé';

  @override
  String get genreConfirmTitle => 'Genre';

  @override
  String get genreNewHint => 'Ou tapez un nouveau genre';

  @override
  String get fromApi => 'depuis l’API :';

  @override
  String get manualEntryTitle => 'Ajouter un livre';

  @override
  String get fieldTitle => 'Titre';

  @override
  String get fieldSubtitle => 'Sous-titre';

  @override
  String get fieldIsbn => 'ISBN';

  @override
  String get fieldPages => 'Pages';

  @override
  String get fieldDatePublished => 'Date de publication';

  @override
  String get fieldCover => 'Couverture';

  @override
  String get fieldAuthors => 'Auteurs';

  @override
  String get fieldGenres => 'Genres';

  @override
  String get fieldCoverUrlHint => 'URL de l’image de couverture (facultatif)';

  @override
  String get saveBook => 'Enregistrer';

  @override
  String get manualEntrySaving => 'Enregistrement…';

  @override
  String manualEntryError(String message) {
    return 'Impossible d’enregistrer : $message';
  }

  @override
  String get detailBack => '‹ Retour';

  @override
  String get detailEdit => 'Modifier';

  @override
  String get detailIsbn => 'ISBN';

  @override
  String get detailPages => 'Pages';

  @override
  String get detailPublished => 'Publié';

  @override
  String get detailGenres => 'Genres';

  @override
  String get authorChipHint => 'Ajouter un auteur';

  @override
  String authorAddNew(String name) {
    return 'Ajouter « $name » comme nouvel auteur';
  }

  @override
  String get authorConfirmTitle => 'Confirmer l’auteur';

  @override
  String authorConfirmKeepNew(String name) {
    return 'Garder « $name » comme nouvel auteur';
  }

  @override
  String get readingStatusLabel => 'Statut de lecture (lecture seule)';

  @override
  String get readingOwnedNote => 'Géré par Habits — jamais modifié ici';

  @override
  String get statusLabel => 'Statut';

  @override
  String get currentPageLabel => 'Page';

  @override
  String get statusNotStarted => 'Pas commencé';

  @override
  String get pageDash => '—';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get ob1Title => 'Découvrez Shelf';

  @override
  String get ob1Body =>
      'Shelf catalogue vos livres physiques — titre, auteur, ISBN, pages, genres. L’app ne suit pas votre progression de lecture ; cela se passe dans Habits.';

  @override
  String get ob2Title => 'Trois façons d’ajouter un livre';

  @override
  String get ob2BodyScan =>
      'Scannez un code-barres pour une identification instantanée';

  @override
  String get ob2BodyPhoto =>
      'Prenez la couverture en photo et laissez l’OCR la lire';

  @override
  String get ob2BodyManual => 'Ou saisissez les détails vous-même';

  @override
  String get ob3Title => 'Les doublons sont détectés automatiquement';

  @override
  String get ob3Body =>
      'Si un scan correspond à un livre déjà sur votre étagère, Shelf le signale pour fusionner les détails au lieu de créer une copie.';

  @override
  String get obScanCta => 'Scanner votre premier livre';

  @override
  String get obSkipToShelf => 'Passer à l’étagère';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsNotion => 'Connexion Notion';

  @override
  String get settingsConnected => 'Connecté à Notion';

  @override
  String get settingsWorkspace => 'Espace Notion';

  @override
  String get settingsReconnect => 'Se reconnecter';

  @override
  String get settingsDisconnect => 'Se déconnecter';

  @override
  String get settingsNotionTokenHint => 'Jeton d’intégration Notion';

  @override
  String get settingsConnect => 'Connecter';

  @override
  String get settingsConnecting => 'Connexion…';

  @override
  String get settingsAccessibleDatabases => 'Bases de données accessibles';

  @override
  String get settingsNoDatabasesFound =>
      'Aucune base de données partagée avec cette intégration.';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsLight => 'Clair';

  @override
  String get settingsDark => 'Sombre';

  @override
  String get settingsSystem => 'Système';

  @override
  String get settingsAccent => 'Thème d’accent';

  @override
  String get settingsAbout => 'À propos de Shelf';

  @override
  String get settingsAboutBody =>
      'Shelf gère votre catalogue : titre, auteur, ISBN, pages, date de publication et genres. Le statut de lecture, la page actuelle et les notes appartiennent à Habits — Shelf les affiche sans jamais les modifier.';

  @override
  String get settingsViewOnboarding => 'Revoir l’introduction';

  @override
  String get themeTerracotta => 'Terracotta';

  @override
  String get themeVertRouge => 'Vert & rouge';

  @override
  String get themeAmbreArdoise => 'Ambre & ardoise';

  @override
  String get themeSarcelleRouille => 'Sarcelle & rouille';
}
