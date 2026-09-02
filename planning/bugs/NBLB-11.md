# NBLB-11 — SideStore/iloader install fails: invalid App ID name (underscores in CFBundleName)

Installing the sideloaded IPA via SideStore (iloader / `isideload`) failed
at the developer-account step:

```
Failed to add developer app ID
Developer error 35: An invalid value 'notion_book_library' was provided
for the parameter 'appIdName'.
```

`isideload` derives the Apple Developer Portal **App ID name** from the
IPA's `CFBundleName`, and Apple's `appIdName` parameter only accepts ASCII
letters, digits, and spaces — no underscores. `ios/Runner/Info.plist` had
`CFBundleName = notion_book_library` (the Dart package identifier, left
as-is in NBLB-2 on the assumption it was non-user-facing and therefore
harmless — which held for Sideloadly, which never registers an App ID).

Fix: `CFBundleName` → `Shelf` (matches `CFBundleDisplayName`; letters only,
so it's a valid `appIdName`). The bundle identifier
(`com.yannraoul.notionBookLibrary`) is unchanged, so it's the same app.

Not locally verified — no Mac/iOS build available in this environment.
Verification is the next Codemagic `ios-unsigned` build → SideStore
install (see `docs/ios-sideload.md`).

Note: the sister Habits app has the same latent issue
(`CFBundleName = notion_habit_tracker`) and will hit the identical error
the first time it's installed via SideStore — apply the same one-line fix
there.
