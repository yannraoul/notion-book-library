import '../l10n/app_localizations.dart';

/// Localized label for a genre id (same ids as
/// `lib/theme/color_tokens.dart`'s `genreHues`). Single lookup point so no
/// screen needs its own switch statement.
String genreLabel(AppLocalizations l10n, String genreId) {
  switch (genreId) {
    case 'fiction':
      return l10n.genreFiction;
    case 'scifi':
      return l10n.genreScifi;
    case 'fantasy':
      return l10n.genreFantasy;
    case 'business':
      return l10n.genreBusiness;
    case 'selfhelp':
      return l10n.genreSelfhelp;
    case 'nonfiction':
      return l10n.genreNonfiction;
    case 'biography':
      return l10n.genreBiography;
    case 'history':
      return l10n.genreHistory;
    default:
      return genreId;
  }
}
