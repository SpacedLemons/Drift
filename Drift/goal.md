Follow the README/project brief and continue from the current Drift MVP.

This prompt is only for **free-plan features**.

Do not implement paid features.
Do not implement StoreKit.
Do not implement paywall.
Do not implement OpenAI.
Do not implement AI summaries.
Do not implement iCloud backup.
Do not add backend/networking.
Do not add cloud sync.
Do not add analytics beyond existing Crashlytics if already configured.

Keep Drift local-first and privacy-first.

Keep the existing architecture and style:

- SwiftUI
- MVVM-C
- SwiftData
- AVFoundation
- Apple Speech
- UserNotifications
- dependency injection
- Swift Testing
- Mockable
- SPM

Keep using compact switch formatting for simple mappings:

    switch value {
    case .one: resultOne
    case .two: resultTwo
    case .three: resultThree
    }

Avoid verbose `Button(action:label:)` style in new or touched code. Prefer:

    Button {
      action()
    } label: {
      Label("Title", systemImage: "star")
    }

---

# Goal For This Chunk

Implement the next free-feature upgrade pass.

Focus on:

1. Full calendar browsing
2. Add images to journal entries
3. Mood graph in Insights
4. Listen back in Review Entry
5. Empty/silent recording handling
6. User-created themes/categories
7. In-app guide annotations

Do not add paid gating in this prompt.

Everything implemented here should be available in the free version.

---

# 1. Full Calendar Browsing

Improve the current recent-days calendar strip.

Current direction:

- Journal Home currently shows recent days.
- The user should be able to tap a chevron / calendar control to expand from the recent 7-day strip into a full month calendar.
- The month calendar should allow browsing months smoothly.
- The user should be able to go back years and find old local entries.
- Everything should be powered by local SwiftData entries.
- Do not fetch from a backend.

## Required Behaviour

On Journal Home:

- Keep the compact recent-days strip by default.
- Add a chevron or calendar button near the recent-days header.
- Tapping it expands into a full month calendar.
- Tapping again collapses back to recent days.

Full calendar state:

- Show a top bar with the current month and year.
- Example: `May 2026`
- Include previous/next controls where appropriate.
- Allow horizontal swiping to change month.
- Show all days in the selected month.
- Show subtle indicators on dates that have journal entries.
- Highlight the selected date.
- Tapping a date filters/shows entries for that date.
- If a date has multiple entries, show all entries for that date below the calendar.
- If a date has no entries, show a calm empty state.

Month navigation:

- Smooth animated transitions.
- Swiping left/right changes month.
- Users should be able to go back years.
- Calendar must remain performant with many local entries.

## Calendar UI Direction

Keep the same Drift style:

- dark mode-first
- minimal
- premium
- calm
- rounded cards
- subtle purple accent
- SFSymbols only
- no imagery
- no heavy decoration

Suggested symbols:

- calendar
- chevron.up
- chevron.down
- chevron.left
- chevron.right
- circle.fill for entry indicators

## Architecture

Create or update clean components:

- CalendarStripView
- MonthCalendarView
- CalendarDayCell
- CalendarMonthHeader
- CalendarEntryListView if helpful

Create or update ViewModel logic:

- selected date
- selected month
- collapsed/expanded calendar state
- entries grouped by day
- month navigation
- date filtering

Do not put calendar business logic directly in SwiftUI views.

---

# 2. Add Images To Journal Entries

Users should be able to add images to a specific journal entry when reviewing or editing.

This is a free feature.

## Required Behaviour

Users should be able to add images from:

- Review Entry screen before saving
- Edit Entry screen after saving
- Entry Detail screen if edit mode exists

Users should be able to:

- pick one or more images
- preview attached images
- remove an attached image
- save image attachments locally
- see image thumbnails on Entry Detail
- optionally see a subtle image indicator on Journal Home cards

Do not upload images.

Do not use cloud storage.

Do not store images in a backend.

## Image Storage

Images must be stored locally.

Preferred approach:

- store image files in the app’s local documents/application support directory
- store lightweight image metadata/path references in SwiftData
- avoid storing large image blobs directly in SwiftData unless there is a strong reason

Create a clean model such as:

    JournalImageAttachment

Possible fields:

- id
- entryId
- localFileName
- createdAt
- originalFileName if available
- width
- height
- fileSize
- thumbnailFileName if generated

If simpler for this chunk, store:

- id
- localFileName
- createdAt

Keep it clean and expandable.

## Image Picker

Use Apple-native APIs.

Prefer:

- PhotosPicker / PhotosUI

Do not add third-party image picker packages.

## Image Compression

Implement sensible local image handling:

- downscale large images before saving if needed
- compress to reasonable JPEG/HEIC quality
- avoid huge storage usage
- generate thumbnails if practical
- do not block the main thread during image processing

Keep image processing local.

## Privacy

Add or keep privacy copy accurate:

    Images are stored on this device with your journal entry.

Do not claim encryption unless actually implemented.

## Deletion

When an image is removed from an entry:

- remove the metadata reference
- delete the local image file where practical

When an entry is deleted:

- delete associated local images where practical

When all entries are deleted:

- delete associated local images where practical

---

# 3. Mood Graph In Insights

Add a graph to track mood over time in Insights.

This is a free local insight.

Do not use AI.

Do not use networking.

## Required Behaviour

Insights should include a mood-over-time graph.

The graph should:

- use local saved entries only
- plot mood over time
- support at least a recent range, such as:
  - last 7 days
  - last 30 days
  - this month
- show empty state if not enough data exists
- be visually calm and minimal

## Mood Scoring

Create a simple local mapping from Mood to numeric value.

Example:

- positive: 5
- reflective: 4
- neutral: 3
- anxious: 2
- stressed: 2
- low: 1
- unknown: ignored or neutral

Keep the mapping simple and documented.

Do not present this as medical accuracy.

Use wording like:

    Mood trend

Avoid wording like:

    Mental health score

## UI Direction

The graph should match Drift:

- dark card
- subtle line
- purple/accent highlights
- simple labels
- no clutter
- no medical framing

Use Swift Charts if available and appropriate.

If Swift Charts adds complexity, implement a simple lightweight custom line chart.

Prefer Apple-native APIs.

## Insights Updates

Insights should include:

- mood trend graph
- most common mood
- most common theme
- entries this week
- writing streak
- empty states

Keep everything local.

---

# 4. Listen Back In Review Entry

Users should be able to listen back to the temporary recording before saving an entry.

This is free.

## Required Behaviour

In Review Entry, when a temporary audio file exists:

- show playback controls
- allow play/pause
- show duration if available
- show progress if simple
- allow scrubbing if easy, but not required

After saving:

- keep current MVP behaviour of discarding temporary audio unless the app explicitly supports permanent audio storage
- do not permanently store audio by default
- do not upload audio

If audio is unavailable:

- hide playback controls gracefully

## Architecture

Use or create:

- AudioPlaybackService
- AVAudioPlaybackService
- PreviewAudioPlaybackService

Keep AVFoundation playback code out of SwiftUI views.

---

# 5. Empty / Silent Recording Handling

Improve recording so Drift avoids empty entries.

## Required Behaviour

During recording:

- monitor local audio level
- detect sustained silence
- after around 10 seconds of no meaningful voice activity, show a gentle prompt:

    Still there?

Prompt actions:

- Keep recording
- Stop recording
- Discard

If silence continues for longer:

- auto-pause rather than auto-delete

Do not save empty transcripts without confirmation.

If transcription returns empty text:

- show a calm error
- allow retry
- allow manual entry
- allow discard

Suggested copy:

    We couldn’t hear anything clearly. You can try again or write the entry manually.

Do not upload audio for silence detection.

Do not use external services.

---

# 6. User-Created Themes / Categories

Users should be able to add custom journal themes/categories similar to tags.

This is free.

## Required Behaviour

Keep existing built-in themes.

Add support for user-created themes.

Users should be able to:

- create a custom theme
- select custom themes on Review Entry
- select custom themes when editing an entry
- see custom themes on Entry Detail
- see custom themes on Journal Home cards where appropriate
- search by custom theme where practical
- delete a custom theme if safe

Keep it local-only.

Do not add backend sync.

## Model Guidance

Do not remove the existing built-in `JournalTheme` enum unless there is a clean migration path.

If needed, introduce a new model that can represent both built-in and custom themes.

For example:

    EntryTheme {
      case builtIn(JournalTheme)
      case custom(CustomJournalTheme)
    }

Or use a domain model with:

- id
- name
- kind: builtIn/custom
- builtInRawValue
- createdAt

Choose the cleanest approach for the current codebase.

## Storage

Custom themes should persist locally.

Use SwiftData or existing settings/local storage depending on what best fits the current architecture.

---

# 7. In-App Guide Annotations

Add a non-blocking guide that helps users understand Drift.

This is not onboarding.

## Required Behaviour

The guide should:

- be available from Settings
- optionally appear subtly for first-time users if appropriate
- be dismissible
- remember dismissed state locally
- use smooth, fluid UI
- feel like annotations/coach marks/tooltips, not a heavy slideshow

The guide should explain:

- tap mic to record
- review before saving
- use tags and themes
- browse by calendar
- reminders are local
- entries stay on device
- add images to entries if implemented

## UI Direction

Keep it beautiful and lightweight.

Use:

- SFSymbols
- small annotation cards
- subtle arrows/anchors if practical
- smooth transitions
- no imagery
- no heavy tutorial screens

Do not block core usage.

---

# Data / Persistence Updates

Update local persistence as needed for:

- calendar grouping
- image attachments
- custom themes
- guide dismissed state
- mood graph calculations

Do not add backend/networking.

Do not add cloud sync.

Keep SwiftData migrations simple and safe.

If model changes require migration notes, add TODOs or a lightweight migration approach.

---

# Privacy Requirements

Keep privacy copy accurate.

Safe claims:

    Your entries are stored on this device.
    Images are stored on this device with your journal entry.
    Audio playback uses the temporary recording before saving.
    Drift works offline.
    No account is required.

Do not claim:

    End-to-end encrypted

unless actually implemented.

Do not claim:

    Audio is stored forever

because temporary audio should be discarded unless intentionally saved.

---

# Testing

Add or update Swift Testing tests where practical for:

## Calendar

- groups entries by day
- selected date filters entries
- month navigation changes selected month
- dates with entries are marked
- empty day state works

## Images

- image attachment metadata is saved
- image attachment metadata is removed
- deleting an entry cleans associated image references where practical
- JournalEntry mapping supports image attachments

## Mood Graph

- mood values map correctly
- unknown mood is handled safely
- mood trend produces expected points
- empty state when no entries exist

## Listen Back

- playback ViewModel state
- play/pause state transitions
- unavailable audio hides controls

## Silence Handling

- silence prompt triggers after threshold
- keep recording dismisses prompt
- stop recording finishes correctly
- discard cancels correctly
- empty transcript fallback works

## Custom Themes

- create custom theme
- select custom theme
- save entry with custom theme
- search by custom theme where practical

## Guide

- guide can be dismissed
- dismissed state persists
- guide can be reopened from Settings

Use Mockable-generated mocks where appropriate.

Avoid brittle UI tests.

---

# Keep Compiling

Keep the app compiling after this chunk.

Do not break:

- Journal Home
- live audio recording
- audio-level animation
- Apple Speech transcription
- notification routing
- SwiftData persistence
- review/save flow
- Entry Detail
- edit/delete entry behaviour
- Insights
- Settings
- Reminder Settings
- Appearance Settings
- Export
- Preview/demo mode
- test suite

After implementation, summarise:

- files changed
- calendar implementation
- image attachment implementation
- mood graph implementation
- listen-back implementation
- silence handling behaviour
- custom theme model/storage
- guide annotation behaviour
- tests added/updated
- any TODOs left
