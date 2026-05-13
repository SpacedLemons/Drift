# Drift TestFlight Notes

## Current MVP Build Status

Drift is preparing for internal TestFlight dogfooding. The MVP is local-first and includes journal recording, Apple Speech transcription, review/save, SwiftData persistence, entry detail/edit/delete, local insights, local reminders, appearance settings, privacy/about screens, and local Markdown export.

Static project checks have been reviewed for formatting, app identity, generated Info.plist usage descriptions, local-only reminder capability, unfinished-feature copy, and internal documentation. Debug and Release simulator builds pass, generic iOS Release compilation passes with signing disabled, a signed archive succeeds, and simulator plus connected-device test-suite runs pass with no warnings or errors. A TestFlight upload and real-device manual audio/notification QA pass still need to be completed before inviting dogfooders.

## Static Readiness Audit

- App identity uses Drift across visible app copy, export copy, notification title, README, and dogfooding notes.
- Generated Info.plist settings include microphone and speech recognition usage descriptions.
- Generated Info.plist settings lock Drift to portrait orientation and require full screen on iPad.
- No entitlements file is present, and the project does not declare iCloud, CloudKit, remote push notification, background mode, HealthKit, analytics, crash SDK, or Sign in with Apple capabilities.
- App Shortcuts flexible matching is disabled because Drift does not ship AppIntents in the MVP.
- Live dependency wiring uses SwiftData, AVFoundation recording, Apple Speech transcription, local reminders, local customisation, disabled AI, disabled subscription, and local Markdown export services.
- Preview fixture factories live under `Core/PreviewSupport`; no demo mode or demo toggle is present in the app shell.
- Reminder notification copy defaults to `Take a moment to drift.` and notification actions remain `Note journal entry`, `Remind me later`, and `Not now`.
- Empty-state and permission copy are calm, privacy-friendly, and aligned with the current MVP scope.
- Export is local-only, uses native sharing, and writes readable Markdown with `drift-export-YYYY-MM-DD-HHMMSS.md` filenames.
- Destructive entry, recording, review, edit, and delete-all flows have confirmation states or duplicate-action guards.
- Static source scans have removed fatal-error calls, forced-try patterns, forced casts, obvious force unwraps, old app names, demo-mode wiring, and shorthand SwiftUI `Button` call sites.

## Static Checks Run

```sh
xcrun swift-format lint $(find Drift DriftTests DriftUITests -type f -name '*.swift' | sort)
plutil -lint Drift.xcodeproj/project.pbxproj
xcodebuild -list -project Drift.xcodeproj
```

## Build And Test Verification

Validated on the configured `iPhone 17 Pro Max` simulator:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO test
xcodebuild -project Drift.xcodeproj -scheme Drift -configuration Release -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Drift.xcodeproj -scheme Drift -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS,id=00008110-00141C19147A801E' -allowProvisioningUpdates test
```

Result: Debug and Release simulator builds passed with no warnings or errors; generic iOS Release compilation passed with signing disabled; simulator tests passed with 100 passed, 0 failed, and 0 skipped; connected-device tests passed with 100 passed, 0 failed, and 0 skipped on Lucas' iPhone 13 Pro Max.

## Simulator Smoke Check

- Fresh simulator install launches to Journal Home.
- First-run privacy copy is visible.
- Empty journal state is visible with the microphone action available.

Signed archive check:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/Drift-archive-check-20260513.xcarchive archive
```

Result: signed archive passed.

## Real-Device Smoke Check

- Debug build signed successfully for `Lucas' iPhone 13 Pro Max`.
- `LWR.Drift` installed successfully on the connected device.
- `LWR.Drift` launched successfully on the connected device.
- Connected-device test suite passed on `Lucas' iPhone 13 Pro Max`.

## Signing Notes

- Personal-device testing can use Xcode automatic signing with a Personal Team. This creates development signing assets only, not distribution signing assets.
- Avoid selecting a work/company Apple Developer team unless Drift should create App ID, device, and provisioning records in that organisation account.
- TestFlight requires a paid Apple Developer Program team, a signed archive, and App Store Connect upload. It cannot use free Personal Team signing.

## What To Test

1. Fresh install
2. First launch onboarding
3. Permission grant path
4. Permission denial path
5. Record entry
6. Cancel recording
7. Finish recording
8. Transcribe entry
9. Transcription failure/manual fallback if available
10. Save entry
11. Relaunch app and confirm persistence
12. Edit entry
13. Delete entry
14. Delete all entries
15. Search entries
16. Check insights
17. Enable reminder
18. Receive reminder notification
19. Notification action: Note journal entry
20. Notification action: Remind me later
21. Export entries
22. Change appearance setting
23. Verify privacy/about copy
24. Test Dynamic Type briefly
25. Test on a real device

## Known Limitations

- AI reflections are not active in this MVP.
- Paywall and subscription behaviour are not active yet.
- Cloud sync and account sign-in are not implemented.
- Transcription depends on Apple Speech availability and may vary by device, language, and iOS support.
- Drift prefers on-device transcription where available, but some system transcription features may require network access.
- Reminder notifications are local only.
- Alternate app icons, additional typography controls, and advanced theme options are future customisation work.

## Known Issues / QA Remaining

- Real-device manual recording, Apple Speech transcription, notification delivery, and notification action routing still need device verification.
- TestFlight upload has not been completed yet.
- Apple Speech availability may differ by locale, network conditions, and device support.

## Owner-Run Validation Commands

Simulator checks:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO test
```

Connected-device checks:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS,id=00008110-00141C19147A801E' -allowProvisioningUpdates build
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS,id=00008110-00141C19147A801E' -allowProvisioningUpdates test
```

Archive check:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -configuration Release -destination 'generic/platform=iOS' -archivePath /tmp/Drift-archive-check-20260513.xcarchive archive
```

Use `-allowProvisioningUpdates` only when you intentionally want Xcode to create or fetch development signing assets for the selected Apple team.

## Privacy Notes

- Journal entries are stored on this device with SwiftData.
- No account is required.
- Exports are created locally and shared only when the user chooses.
- Drift does not add iCloud, CloudKit, remote push notifications, analytics, or crash SDK capabilities for the MVP.
- Reminders use local notifications.

## Not Yet Built

- Backend sync
- Cloud backup
- AI-generated reflections
- Paywall or paid subscription flows
- Remote config
- Analytics
- App Store submission metadata
