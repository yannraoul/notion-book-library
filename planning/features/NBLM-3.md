# NBLM-3 — Notion connection settings

Built the minimal Notion connection card in Settings: paste a token,
validate it, list accessible databases, disconnect. No database-ID
resolution and no real book data yet — that lands with the milestone that
actually reads/writes the `Books`/`Authors`/`Genres` databases (mirrors
the sister Habits app's own split between its NHTM-4 "minimal Notion
connection settings" and NHTM-5 "real Notion-backed data").

Implementation is a close port of the sister app's actual code (read
directly from `notion-habit-tracker`, not just its design doc):
`notion_token_storage.dart` ported verbatim; `notion_api.dart` trimmed to
just `getMe`/`searchDatabases` plus shared plumbing (habit/book CRUD isn't
needed yet); `notion_connection_provider.dart` ported to the *original*,
simpler shape (token + workspaceName + databases) rather than the sister
app's current evolved one, which has since grown DB-ID resolution and a
cache-fallback mechanism from its own later milestones — intentionally
not carried over here to keep this milestone minimal. `settings_screen.dart`
mirrors the sister app's actual widget structure (`ListView` +
`_NotionConnectionCard`/`_ConnectedBody`/`_ConnectingBody`/`_DisconnectedBody`
split, fixed universal-green connected dot, `ConsumerStatefulWidget`
owning the token `TextEditingController`).

- IN: `notion_token_storage.dart`, `notion_api.dart` (`getMe`,
  `searchDatabases`, `NotionApiException`), `notion_connection_provider.dart`
  (sealed `NotionConnectionState`: Disconnected/Connecting/Connected/
  ConnectionError, auto-reconnect on app start), Settings' real Notion
  connection card, 5 new ARB keys (`settingsNotionTokenHint`,
  `settingsConnect`, `settingsConnecting`, `settingsAccessibleDatabases`,
  `settingsNoDatabasesFound`).
- OUT: database-ID resolution, real book data, the rest of Settings
  (Language/Appearance/Accent/About) — still a placeholder note below the
  card.
- Done: `flutter analyze` clean. Live-tested on `-d windows` against a real
  scoped Notion integration (workspace "Perso", databases `Books*`/
  `Authors*`/`Genres*` — confirmed independently via a raw API call before
  the UI test, then again through the app): connect → workspace name +
  database list render correctly → disconnect reverts to the empty form →
  relaunching the app after a successful connect auto-reconnects without
  re-pasting the token → an invalid token surfaces "Invalid or revoked
  Notion token." instead of crashing. All four connection states verified.
- Open decisions: none new. The real Notion `Books`/`Authors`/`Genres`
  schema (property names/types) still needs to be checked live before the
  next milestone writes any query/parse code against it — don't assume the
  sister app's `NotionBookRecord` shape carries over exactly, Shelf's
  fields differ (no `Status`/`Rating`/etc. ownership).
