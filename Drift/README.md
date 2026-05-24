# Drift

Drift is a private voice-first personal context board for iOS. It lets you capture a Drift by voice, transcribe it with Apple Speech, review the text, choose a Drift type, save it locally, browse and filter past Drifts in Timeline, view local mood history, set local reminders, and export local Markdown.

## Product Principles

- Private by default: Drifts are stored on this device.
- Offline-first: core Drift browsing, storage, settings, reminders, and export are local.
- No account: Drift does not require sign-in for the MVP.
- Local storage: Drifts are persisted through the existing SwiftData journal store with safe compatibility defaults.
- User-controlled export: exports are created locally and shared only when the user chooses.
- User-controlled context: Context Packs are local and can be copied or shared manually.

## Tech Stack

- SwiftUI
- MVVM-C
- SwiftData
- AVFoundation
- Speech framework
- UserNotifications
- StoreKit 2 subscription support
- Swift Testing
- Mockable
- Swift Package Manager

## Running The App

Open `Drift.xcodeproj` in Xcode, select the `Drift` scheme, choose a simulator or physical device, then run from Xcode.

Real-device testing is recommended for microphone recording, Apple Speech transcription, notification permission, and reminder actions.

The `Drift` scheme uses the local StoreKit configuration at `Drift/Configuration/DriftPlus.storekit` for development subscription testing. DEBUG builds include Settings developer controls for forcing Free/Plus and daily-limit states locally; those controls are not compiled into Release builds.

## Running Tests

Run the Swift Testing suite from Xcode, or use:

```sh
xcodebuild -project Drift.xcodeproj -scheme Drift -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' CODE_SIGNING_ALLOWED=NO test
```

## Current MVP Limitations

- AI integrations are not active yet.
- MCP, backend sync, and ChatGPT API integration are not implemented.
- Drift Plus paid-feature foundations are present, but the actual future paid features are not active yet.
- Cloud sync is not implemented.
- Transcription depends on Apple Speech availability and may vary by device, language, and iOS support.
- Audio and notification flows should be verified on a real device before TestFlight dogfooding.

## Internal Dogfooding

Use `../Docs/TestFlightNotes.md` for the current dogfooding checklist, known limitations, and privacy notes.

Use `../Docs/StoreKitTesting.md` for local StoreKit and entitlement override testing notes.
