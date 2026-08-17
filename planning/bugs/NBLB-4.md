# NBLB-4 — search confidence ranked author-name-in-title above the real title

`BookLookupService.searchText` (used by both the OCR-candidates screen and
manual search — neither has separate title/author inputs, both feed a
single free-text string) scored each candidate by a Jaccard token-overlap
ratio between the *whole* query and the candidate's **title only**;
`authors` was never consulted. Already flagged as a known limitation in
`planning/features/NBLM-7.md`: a mixed query like `"Sapiens Yuval Noah
Harari"` scored 3-of-4 overlapping tokens against any candidate whose
*title* happened to contain the author's name, beating the real "Sapiens"
title (1-of-4 tokens overlap) — author-name tokens out-voted the actual
title match.

Fix, in `lib/services/book_lookup_service.dart`'s `confidence()` (renamed
from the former private `_similarity`, now public so it's directly unit
testable without mocking the HTTP APIs — scoring is pure): attribute each
query token to whichever field it actually matches before scoring, instead
of comparing the whole query only against title.

- Query tokens that overlap the candidate's author-name tokens are claimed
  by the author field and set aside; the title score is computed on the
  residual (falling back to the full query if nothing was claimed).
- The author score is the fraction of the author's own name tokens found
  in the query (not a Jaccard ratio against the full query) — and is only
  factored in at all when the query references the author, so a title-only
  query (the common case) isn't penalized for "missing" author info it was
  never expected to contain.
- Combined via a weighted sum, title-weighted (`0.65`/`0.35`) since title
  is the primary identifying field.

Worked example (`"Sapiens Yuval Noah Harari"`): correct book ("Sapiens" /
"Yuval Noah Harari") now scores 1.0 (author fully claimed, leaving a
perfect title match on the residual); an unrelated book titled "Yuval Noah
Harari: Seti" by a different author scores 0.6. The correct book now
clearly outranks the unrelated one, where the old scheme ranked them the
other way around.

New test file `test/services/book_lookup_service_test.dart` covers the
NBLM-7 regression case above, a plain title-only query, and a query with
no author-field overlap — all pass (`flutter test`), and `flutter analyze`
is clean.
