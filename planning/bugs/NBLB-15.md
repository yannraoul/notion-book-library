# NBLB-15 — barcode detection was never broken; it's the keyless Google Books quota + misleading messaging

Yann's debug-panel report broke this whole investigation open: "Detections:
xx • last: ean13 "9781473217423" (len 13)" — a valid EAN-13 (checksum
verified), the *correct* ISBN for the book being scanned. Vision has been
detecting barcodes correctly all along; every fix from NBLB-3 through
NBLB-14 aimed at the wrong layer.

Traced what happens after a correct detection: `BookLookupService.lookupIsbn`
queries Google Books first, then Open Library. Checked both APIs directly
for that exact ISBN:

- Google Books (`googleapis.com/books/v1/volumes`, no key — the app's
  documented no-key design, `docs/Backlog shelf.md`): **HTTP 429**,
  `"quota_limit_value": 0` for the anonymous consumer bucket. Tried three
  more unrelated ISBNs — same 429 every time. This isn't a per-IP
  exhaustion from heavy testing; Google's anonymous/keyless quota for this
  API is shared globally across every app that skips an API key (confirmed
  via web search — a known, common failure mode for other keyless
  integrations too), and it's apparently sitting at zero right now. So
  Google Books lookups are almost certainly failing 100% of the time, for
  every Shelf user, until this changes.
- Open Library (`openlibrary.org/api/books?bibkeys=ISBN:...`): **HTTP
  404** for this specific ISBN — a genuine "not in Open Library" case (a
  UK/small-press edition), not a bug.

So this particular scan was always going to come up empty — both sources
genuinely have nothing for that ISBN right now — and that's a real,
expected outcome the identification pipeline should have surfaced clearly.
Instead `_lookupIsbn` returned silently on a `null` result, leaving only
the generic, timer-driven `scanHint` ("No barcode found — try Cover photo
above") on screen — actively misleading, since a barcode plainly *was*
found. This is most likely what's been driving this entire bug chain: the
William Gibson trilogy titles that "used to scan fine" probably matched
one of the two APIs; whichever ones don't are hitting this exact
null-result path, with no barcode/scanner regression involved at all.

Fix, in `lib/screens/scan_screen.dart`'s `_lookupIsbn`:

- A `null` lookup result now shows a specific `SnackBar`
  (`scanIsbnNotFound`) naming the ISBN and pointing at "Cover photo" or
  manual search, instead of silently falling through to the generic hint.
- Wrapped the whole lookup in try/catch — previously an exception here
  (network error, malformed API response) would leave `_busy` stuck
  `true` forever, silently blocking all further detections for the rest
  of the screen session with zero feedback. Now shows
  `scanIsbnLookupError` and always resets `_busy` via `finally`.

New l10n keys `scanIsbnNotFound`/`scanIsbnLookupError` (en/fr).

**Not fixed here, needs Yann's input**: the Google Books anonymous-quota
problem itself. `docs/Backlog shelf.md` deliberately chose no-key usage;
that assumption may not hold up anymore given quota is at zero right now.
Getting a free Google API key (Google Cloud Console → enable the Books
API → API key, no billing needed for this quota tier) and having the app
send it as `&key=...` would fix this properly. Until then, Shelf is
effectively running on Open Library coverage alone for most ISBNs, which
is real but incomplete (especially non-US editions, per its own doc
comment). The on-screen barcode diagnostics from NBLB-13 stay in place —
still useful for confirming detection independent of the lookup step.

`flutter analyze`/`flutter test` clean.
