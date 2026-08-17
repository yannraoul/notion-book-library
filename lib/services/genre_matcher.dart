/// Deterministic keyword matching from raw API category/subject text to
/// Shelf's fixed `Genres*` list — deliberately no LLM (see `docs/Backlog
/// shelf.md`'s pipeline section). Only ever a *suggestion*: the caller
/// still routes through the genre-confirm screen, never auto-writes.
const Map<String, List<String>> _genreKeywords = {
  'Fantasy': ['fantasy'],
  'Science-Fiction': ['science fiction', 'sci-fi', 'scifi'],
  'LitRPG': ['litrpg', 'gamelit'],
  'Finances': ['finance', 'financial', 'investing', 'personal finance'],
  'Personal Development': ['personal development', 'self-help', 'self help'],
  'Productivity': ['productivity', 'time management'],
  'Business': ['business', 'management', 'economics'],
};

/// Returns the first fixed genre whose keywords appear in [rawText]
/// (case-insensitive substring match), or `null` if nothing matches.
String? suggestGenre(String? rawText) {
  if (rawText == null || rawText.isEmpty) return null;
  final lower = rawText.toLowerCase();
  for (final entry in _genreKeywords.entries) {
    for (final keyword in entry.value) {
      if (lower.contains(keyword)) return entry.key;
    }
  }
  return null;
}
