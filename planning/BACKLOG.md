# Backlog: ideas not yet scoped into a milestone

Raw ideas that are worth keeping around but haven't been committed to as a
concrete unit of work. Once one of these is actually scoped and started, it
graduates into `ROADMAP.md` with its own **NBLM-x** identifier and moves out
of this file. See `../instructions.md` for how the three planning docs
(`ROADMAP.md` / `CHANGELOG.md` / `BACKLOG.md`) relate.

## Explicitly out of scope for v1

From `docs/Backlog shelf.md`'s original spec — deliberately deferred, not
forgotten:

- **LLM-based cover recognition/guessing.** Skipped on purpose to avoid
  overlapping Art Explorer's key usage — the scan pipeline is barcode + Google
  Books/Open Library + on-device OCR only, no LLM calls.
- **Author bio/photo.** Neither Google Books nor Open Library exposes this
  well; would need a third data source.
- **Rating import from external sources.** Ratings stay owned by Habits
  (read-only in Shelf) — no external rating API integration planned.

## SideStore Source for one-tap app updates

**Problem.** Shipping a new build currently means: Codemagic → download
`Shelf.ipa` on the PC → USB file-share it into the SideStore app via
iTunes → SideStore **"+" → Browse → select**. Same for Habits. A SideStore
**Source** (an AltStore-format JSON manifest at a public URL) collapses
that to: SideStore → **My Apps → Update**, no PC.

Independent of the 7-day cert refresh — this only targets the *new build*
path. Cert refresh stays an on-device tap either way (see
`docs/ios-sideload.md`).

### How a Source works

- One public JSON file, added once in SideStore (**Sources → + → paste
  URL**). SideStore polls it, matches each listed app to what's installed
  by `bundleIdentifier`, compares `buildVersion`, and shows an **Update**
  button in My Apps. Tapping it re-signs + installs over the top (keeps
  data) and refreshes the 7-day cert in the same step.
- Still needs what every install/refresh needs: **LocalDevVPN connected**,
  anisette reachable, valid pairing file. No cable.
- SideStore does **not** reliably background-download updates (iOS
  throttling). The win is the manual step dropping from ~6 actions +PC to
  one tap.

### What needs to exist

1. **Public host for the IPAs + the JSON.** `downloadURL` must be HTTPS and
   unauthenticated; Codemagic artifact URLs are auth-gated and expire
   (~30 days) — unusable. Use **GitHub Releases on
   `yannraoul/notion-book-library`** (confirmed public), stable asset URL
   shape `https://github.com/yannraoul/notion-book-library/releases/download/<tag>/Shelf-<version>.ipa`.
   - Shelf and Habits are separate repos. Preferred: one shared
     `source.json` listing both apps (nicer UX), hosted in this repo, with
     each pipeline updating **only its own app entry** via a merge-not-
     overwrite script. If the Habits repo is private, host its IPA in this
     repo's Releases too, or give it a second Source.

2. **`source.json` (AltStore v2 format).** Shape:

   ```json
   {
     "name": "Yann — Shelf & Habits",
     "identifier": "com.yannraoul.apps",
     "apps": [{
       "name": "Shelf",
       "bundleIdentifier": "com.yannraoul.notionBookLibrary",
       "developerName": "Yann Raoul",
       "localizedDescription": "Personal book-cataloging companion.",
       "iconURL": "https://.../shelf-icon.png",
       "tintColor": "6C4CE0",
       "category": "productivity",
       "versions": [{
         "version": "0.2.0",
         "buildVersion": "3",
         "date": "2026-09-10",
         "localizedDescription": "Pull-to-refresh + delete book.",
         "downloadURL": "https://github.com/yannraoul/notion-book-library/releases/download/shelf-v0.2.0%2B3/Shelf-0.2.0.ipa",
         "size": 12345678,
         "minOSVersion": "15.5"
       }]
     }]
   }
   ```
   - `versions` newest-first; keep ~5.
   - **`size` must be the exact IPA byte count** — the #1 source-authoring
     bug; a wrong value makes SideStore's download hang/fail. Compute at
     publish time, never hand-write or carry forward (re-zipping changes
     it).
   - `bundleIdentifier` `com.yannraoul.notionBookLibrary` (from
     `ios/Runner.xcodeproj/project.pbxproj`); `minOSVersion` `15.5` (from
     `IPHONEOS_DEPLOYMENT_TARGET`); `version`/`buildVersion` split from
     `pubspec.yaml` `X.Y.Z+N`.
   - `iconURL`: 512px+ PNG from the NBLM-8 icon art, committed to the repo.
     `tintColor` = brand accent hex, no `#`.

3. **Codemagic publish step** in `codemagic.yaml` `ios-unsigned`, gated to
   tag builds or a manual trigger (not every WIP push):
   - `IPA_SIZE=$(stat -f%z Shelf.ipa)` — verify the `stat` flag on the
     actual (macOS) runner.
   - Rename to `Shelf-<version>.ipa`; `gh release create/upload` against
     this repo with an encrypted fine-grained `GH_TOKEN`
     (contents:write, this repo only).
   - Small committed script (`tool/update_source_json.dart` or `.py`):
     fetch current `source.json`, prepend the new version entry to the
     Shelf app's `versions`, trim to 5, write back, commit + push —
     leaving any Habits entry untouched.

4. **Habits repo**: mirror step 3, writing only its own app entry.

5. **One-time phone setup** (also add to `docs/ios-sideload.md`): SideStore
   → **Sources → + →** paste the raw `source.json` URL
   (`raw.githubusercontent.com/...` or GitHub Pages). Then delete the
   current "+"-installed Shelf/Habits and reinstall **from the source** so
   SideStore tracks them against it (bundle-ID matching *should* adopt the
   existing installs, but a clean install removes doubt).

### Gotchas

- All URLs HTTPS; `identifier` unique + stable forever.
- SideStore caches sources — pull-to-refresh the Sources tab after a
  release to force a re-poll.
- `+` in a version needs URL-encoding (`%2B`) inside `downloadURL`, not in
  the `gh` tag arg.
- Does not remove the LocalDevVPN / anisette / pairing requirements, and
  the cert still expires at 7 days — Source updates and cert refresh are
  independent.

### Effort

~half a day: icon/`tintColor` assets + hand-written first `source.json` +
`gh` publish step + updater script + one end-to-end release test on device.
Habits mirror ~1h. Graduates to an **NBLM** milestone when started
(touches `codemagic.yaml`, a new `tool/` script, and the sideload doc).

## Resolved: genre list mismatch

Was: `docs/Backlog shelf.md`'s Notion `Genres` db list didn't match the
design prototype's 8-genre color list baked into `color_tokens.dart`.
Resolved by NBLM-4 — checked the real `Genres*` database live, it matches
`docs/Backlog shelf.md`'s original list exactly (LitRPG, Fantasy,
Science-Fiction, Finances, Personal Development, Productivity, Business).
`genreHues` now keys off these real names.
