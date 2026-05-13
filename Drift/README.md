# Drift

Drift is a private voice journal for iOS. It lets you record a short entry, transcribe it with Apple Speech, review the text, save it locally, search past entries, view simple local insights, set local reminders, and export entries as Markdown.

## Product Principles

- Private by default: journal entries are stored on this device.
- Offline-first: core journal browsing, storage, settings, reminders, and export are local.
- No account: Drift does not require sign-in for the MVP.
- Local journal storage: entries are persisted with SwiftData.
- User-controlled export: exports are created locally and shared only when the user chooses.

## Tech Stack

- SwiftUI
- MVVM-C
- SwiftData
- AVFoundation
- Speech framework
- UserNotifications
- StoreKit 2 placeholders
- Swift Testing
- Mockable
- Swift Package Manager

## Running The App

Open `Drift.xcodeproj` in Xcode, select the `Drift` scheme, choose a simulator or physical device, then run from Xcode.

Real-device testing is recommended for microphone recording, Apple Speech transcription, notification permission, and reminder actions.

## Running Tests

Run the Swift Testing suite from Xcode, or use:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO test
```

## Current MVP Limitations

- AI reflections are not active yet.
- Paywall and subscription behaviour are placeholders only.
- Cloud sync is not implemented.
- Transcription depends on Apple Speech availability and may vary by device, language, and iOS support.
- Audio and notification flows should be verified on a real device before TestFlight dogfooding.

## Internal Dogfooding

Use `../Docs/TestFlightNotes.md` for the current dogfooding checklist, known limitations, and privacy notes.
