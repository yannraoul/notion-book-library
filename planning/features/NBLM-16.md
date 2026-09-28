# NBLM-16 — Optional Google Books API key

Follow-up to NBLB-15's diagnosis: Google Books' free/keyless quota is
shared globally across every app that skips a key and was found sitting
at zero, breaking most ISBN lookups regardless of Shelf's own usage.
Rather than force a required key (against `docs/Backlog shelf.md`'s
original no-key design, and Open Library alone still covers plenty of
titles), Settings now has a new "Google Books API key" section — paste a
free key from Google Cloud Console (enable the Books API) and Shelf sends
it with every request from then on; leave it blank and behavior is
unchanged from before.

- `lib/services/google_books_api_key_storage.dart` — new, mirrors
  `NotionTokenStorage`: platform keychain/keystore via
  `flutter_secure_storage`, never plain prefs.
- `lib/services/google_books_api.dart` — reads the stored key fresh on
  every request (no restructuring needed at any of the three call sites
  that construct `GoogleBooksApi`/`BookLookupService`) and appends
  `&key=...` when one is set.
- `lib/screens/settings_screen.dart` — new `_GoogleBooksKeyCard`, styled
  like the existing Notion connection card: a masked `TextField` + Save
  when no key is set, "API key saved" + Change/Remove once one is. The
  raw key is never shown back after saving, matching the Notion token's
  own privacy convention.
- New l10n keys: `settingsGoogleBooksKey`, `settingsGoogleBooksKeyBody`,
  `settingsGoogleBooksKeyHint`, `settingsGoogleBooksKeySave`,
  `settingsGoogleBooksKeySaved`, `settingsGoogleBooksKeyChange`,
  `settingsGoogleBooksKeyRemove` (en/fr).

`flutter analyze`/`flutter test` clean. Settings UI not device-verified
(no camera dependency here, but not yet run even on `flutter run -d
windows` this round) — needs a quick manual pass: paste a key, confirm it
persists across app restart, confirm barcode-scan lookups actually send
`&key=...` (can be confirmed via the Google Cloud Console's own API
usage dashboard rather than intercepting traffic).
