/// Name-vs-name similarity for the `Authors*` duplicate-prevention system —
/// deliberately separate from `genre_matcher.dart`, which is a different
/// problem shape (raw-category-text-to-fixed-list keyword matching, not
/// name-to-name similarity against live data). No LLM, same spirit as
/// `genre_matcher.dart` — a plain, explainable heuristic, not a fuzzy-match
/// dependency.
///
/// Exact matches (after normalization) stay the silent auto-link path,
/// identical to `BooksRepository.resolveAuthorIds`'s existing
/// `trim().toLowerCase()` equality, plus "Last, First" reordering folded in
/// as a pure formatting difference. Everything else is scored continuously;
/// only the "ambiguous" middle band should ever interrupt a user with a
/// confirm step — a clearly new name (no similar existing author) stays
/// silent and unchanged, same as today.
library;

enum AuthorMatchBand { exact, ambiguous, none }

class AuthorMatch {
  final String existingName;
  final double confidence;
  final AuthorMatchBand band;

  const AuthorMatch({required this.existingName, required this.confidence, required this.band});
}

sealed class AuthorMatchDecision {
  const AuthorMatchDecision();
}

class AuthorMatchExact extends AuthorMatchDecision {
  final String existingName;
  const AuthorMatchExact(this.existingName);
}

class AuthorMatchAmbiguous extends AuthorMatchDecision {
  final List<AuthorMatch> candidates;
  const AuthorMatchAmbiguous(this.candidates);
}

class AuthorMatchNew extends AuthorMatchDecision {
  const AuthorMatchNew();
}

const double _ambiguousThreshold = 0.55;
const double _surnameGate = 0.7;

String _normalizeKey(String name) {
  var s = name.trim();
  final commaParts = s.split(',');
  if (commaParts.length == 2 && commaParts[0].trim().isNotEmpty && commaParts[1].trim().isNotEmpty) {
    s = '${commaParts[1].trim()} ${commaParts[0].trim()}';
  }
  return s.replaceAll('.', '').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

List<String> _tokens(String name) => _normalizeKey(name).split(' ').where((t) => t.isNotEmpty).toList();

/// True when [a]/[b] are the same string once punctuation/whitespace/
/// "Last, First" ordering are normalized away — the only case that stays a
/// silent auto-link, matching `resolveAuthorIds`'s existing behavior.
bool isExactMatch(String a, String b) => _normalizeKey(a) == _normalizeKey(b);

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      current[j + 1] = [current[j] + 1, previous[j + 1] + 1, previous[j] + cost].reduce((x, y) => x < y ? x : y);
    }
    previous = current;
  }
  return previous[b.length];
}

double _levenshteinRatio(String a, String b) {
  if (a == b) return 1.0;
  final maxLen = a.length > b.length ? a.length : b.length;
  if (maxLen == 0) return 1.0;
  return 1 - _levenshtein(a, b) / maxLen;
}

/// Continuous similarity between two author-name strings, `0.0`-`1.0`.
/// Surname-anchored: a low surname similarity forces the whole score down
/// regardless of given-name agreement, since two different last names are
/// almost certainly two different people. Given-name comparison gives an
/// initial (single letter, with or without a period) credit for matching
/// the first letter of a spelled-out given name on the other side — the
/// "F." vs "Fonda" case — rather than penalizing it as a mismatch.
double nameSimilarity(String a, String b) {
  if (isExactMatch(a, b)) return 1.0;
  final ta = _tokens(a);
  final tb = _tokens(b);
  if (ta.isEmpty || tb.isEmpty) return 0;

  final surnameSim = _levenshteinRatio(ta.last, tb.last);
  if (surnameSim < _surnameGate) return surnameSim * 0.5;

  final givenA = ta.sublist(0, ta.length - 1);
  final givenB = tb.sublist(0, tb.length - 1);
  double givenScore;
  if (givenA.isEmpty || givenB.isEmpty) {
    givenScore = 0.5;
  } else {
    final n = givenA.length < givenB.length ? givenA.length : givenB.length;
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final x = givenA[i];
      final y = givenB[i];
      if (x == y) {
        sum += 1.0;
      } else if (x.length == 1 && y.startsWith(x)) {
        sum += 0.85;
      } else if (y.length == 1 && x.startsWith(y)) {
        sum += 0.85;
      } else {
        sum += _levenshteinRatio(x, y);
      }
    }
    givenScore = sum / n;
  }
  return 0.5 * surnameSim + 0.5 * givenScore;
}

AuthorMatchBand bandFor(double score) {
  if (score >= 1.0) return AuthorMatchBand.exact;
  if (score >= _ambiguousThreshold) return AuthorMatchBand.ambiguous;
  return AuthorMatchBand.none;
}

/// Ranked, descending by confidence, against every name in [existingNames]
/// — entries scoring [AuthorMatchBand.none] are excluded. Capped to the
/// top 5 (dropdown/confirm-screen candidate list size).
List<AuthorMatch> rankAuthorMatches(String input, Iterable<String> existingNames) {
  final matches = <AuthorMatch>[];
  for (final existing in existingNames) {
    final score = nameSimilarity(input, existing);
    final band = bandFor(score);
    if (band == AuthorMatchBand.none) continue;
    matches.add(AuthorMatch(existingName: existing, confidence: score, band: band));
  }
  matches.sort((x, y) => y.confidence.compareTo(x.confidence));
  return matches.take(5).toList();
}

/// The single entry point import-gating and the chip-input widget both use:
/// an exact match resolves silently, an ambiguous top match needs
/// confirmation, and no match at all means "new author" — also silent.
AuthorMatchDecision resolveAuthorMatch(String input, Iterable<String> existingNames) {
  final ranked = rankAuthorMatches(input, existingNames);
  if (ranked.isEmpty) return const AuthorMatchNew();
  if (ranked.first.band == AuthorMatchBand.exact) return AuthorMatchExact(ranked.first.existingName);
  return AuthorMatchAmbiguous(ranked);
}
