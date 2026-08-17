# NBLB-1 — iOS CocoaPods build failure (deployment target too low for google_mlkit_commons)

The Codemagic `ios-unsigned` build failed at `pod install`:
`google_mlkit_commons` requires a higher minimum iOS deployment target than
the app was targeting. CocoaPods' own error pointed at the actual number:
"increase your application's deployment target to at least 15.5".

Root cause was two-fold:

- `ios/Runner.xcodeproj/project.pbxproj` had `IPHONEOS_DEPLOYMENT_TARGET =
  13.0` in all three build configs (Debug/Release/Profile) — a leftover
  from `flutter create`'s default template, never bumped when
  `google_mlkit_text_recognition`/`google_mlkit_commons` were added in
  NBLM-1's scaffold.
- There was no `ios/Podfile` committed at all — this repo's iOS folder was
  scaffolded on Windows, where `flutter create` writes the Podfile but
  nothing ever ran `pod install` against it (no local Mac, per
  `CLAUDE.md`'s Applied Learning notes), so it was apparently never
  generated/tracked. Codemagic's `flutter build ios` auto-creates a Podfile
  from Flutter's template when one is missing, but that template's
  `platform :ios, 'X.X'` line ships commented out — leaving CocoaPods to
  auto-assign a version on its own (the build log shows it picked 15.0),
  which was still below the 15.5 google_mlkit_commons needs.

Fix: bumped `IPHONEOS_DEPLOYMENT_TARGET` to `15.5` in all three
`project.pbxproj` build configs, and committed a real `ios/Podfile` (the
standard Flutter-generated template) with `platform :ios, '15.5'`
explicitly uncommented, so the target no longer depends on CocoaPods'
auto-detection.

Not locally verified — no Mac/CocoaPods available in this environment (see
`CLAUDE.md`'s Applied Learning notes); verification is another Codemagic
build.
