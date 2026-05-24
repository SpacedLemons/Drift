# Drift Context Board Completion Goal

Follow the updated Drift README/project direction.

Drift is now a voice-first personal context board for AI.

Slogan:

> Let your thoughts Drift.

The app has already been remodelled away from being only a journal. It now has Drift Types, Spaces, Timeline, Context Packs, Capture/Home, search, and the beginnings of the new product direction.

This goal is to make the new core experience feel complete, coherent, and useful.

Do not add backend/networking.
Do not add MCP.
Do not add OpenAI.
Do not add Claude/Gemini.
Do not add new paid features.
Do not rebuild the whole app from scratch.
Do not remove existing user data.
Do not break existing MVP functionality.

This goal should improve the free/local product experience across the app.

---

# Verification Requirement

After making changes:

1. Build the project if practical.
2. Run the relevant SwiftUI previews or simulator screens if practical.
3. Take screenshots of the simulator or SwiftUI previews for the main changed screens.
4. Include the screenshot paths/locations in the final summary.
5. Show the important code changes made, especially new/updated files and key snippets.
6. Summarise what changed and how to manually test it.

If screenshots cannot be captured, explain why and still provide the key code changes.

---

# Goal In Plain Terms

Make Drift feel like a real personal context board.

A user should be able to:

- capture a thought quickly
- choose what kind of Drift it is
- put it into one or more Spaces
- open a Space and see everything related to that area
- create a Context Pack from important Drifts/Spaces
- copy or share that Context Pack to ChatGPT
- browse everything later in Timeline
- understand that everything is private/local unless they choose to share it

The experience should feel fluid, calm, premium, and useful.

---

# Core Product Concepts

Use these terms consistently in user-facing UI:

- Drift
- Drifts
- Capture
- Space
- Spaces
- Timeline
- Context Pack
- Copy for ChatGPT
- Share Context

Avoid old journal-heavy wording where possible.

Acceptable old wording only if changing it would be risky or if it still makes sense in a specific context.

A Drift can be:

- Thought
- Reflection
- Goal
- Idea
- Memory
- Mood
- Decision
- Task
- Visual
- Context

Existing old journal entries should continue to appear as Reflection Drifts.

---

# Main Areas To Improve

## 1. Capture/Home

Capture should feel like the fast entry point into Drift.

It should include:

- native large/inline title behaviour for “Drift” if already implemented
- subtitle: “Let your thoughts Drift.”
- Drift-styled search
- Drift Type filter chips
- recent Drifts
- clear empty state
- floating purple mic button as the primary action

Improve anything that still feels like old journal UI.

Search should remain local-only.

Search should rank title matches higher than body matches.

Type filters and search should work together.

---

## 2. Review Drift Flow

The review flow should feel complete.

When a user finishes recording or creates a new Drift, Review Drift should allow:

- editing the title
- editing the body/transcript
- selecting Drift Type
- selecting one or more Spaces
- adding/removing tags
- selecting mood where relevant
- adding/removing images if supported
- listen-back if temporary audio exists
- saving as a Drift

Default voice capture type can remain Reflection.

Do not add AI classification yet.

Manual selection is enough.

Make sure the save action uses “Save Drift” language where safe.

---

## 3. Spaces

Spaces should feel like first-class boards, not placeholders.

A user should be able to:

- view all Spaces
- create a Space
- edit a Space
- delete a Space with confirmation
- open a Space Detail screen
- see Drifts inside a Space
- add existing Drifts to a Space
- remove Drifts from a Space without deleting the Drift
- create a new Drift directly into a Space if practical

A Space should support:

- name
- optional description
- SFSymbol icon
- accent colour
- pinned state if already supported
- Drift count

Deleting a Space must not delete the Drifts inside it.

It only removes the grouping.

---

## 4. Space Detail

Space Detail should feel useful.

It should show:

- Space title
- icon/accent
- description if available
- Drift count
- list of Drifts in that Space
- empty state
- actions:
  - Add Drift
  - Create Context Pack
  - Edit Space
  - Remove Drift from Space where practical

If the Space has no Drifts, show calm copy:

    No Drifts in this Space yet.
    Add thoughts, goals, ideas, or memories when they belong here.

---

## 5. Context Packs

Context Packs are extremely important.

They are the bridge between Drift and AI without needing MCP/backend yet.

A user should be able to:

- create a Context Pack
- choose one or more Spaces
- choose individual Drifts
- preview the generated context
- copy it as Markdown
- share it using the native share sheet
- edit/delete the Context Pack

Context Packs should make it obvious that the user chooses what to share.

Use copy like:

    Context Packs let you collect Drifts and share them with AI when you choose.

Do not say ChatGPT is connected yet.

Use:

    Copy for ChatGPT

or:

    Share Context

Do not use:

    Sync with ChatGPT

or:

    Connected to ChatGPT

because MCP/backend is not implemented yet.

---

# Markdown Context Export

Improve or implement Markdown generation for Context Packs.

The Markdown should be useful when pasted into ChatGPT.

It should be structured and readable.

Example format:

    # Context Pack: OpenAI Career

    Curated from Drift.

    ## Spaces Included

    - OpenAI Career
    - Goals
    - Ideas

    ## Goals

    - I want to work at OpenAI.
    - I am building Drift as a voice-first context board for AI.

    ## Ideas

    - MCPKit for Apple apps.
    - Codex usage monitor.

    ## Decisions

    - Drift should remain local-first.
    - iCloud backup should be free.

    ## Recent Drifts

    ...

Do not include Drifts that are not selected or included through a selected Space.

Do not upload anything.

Everything stays local.

---

# Timeline

Timeline should remain the historical browsing layer.

Make sure Timeline still works well after the product reframe.

Timeline should support:

- calendar/month browsing
- smooth month transitions
- historical Drifts
- filtering by Drift Type
- search if already supported
- mood graph/history if already present

Capture is for fast input.

Timeline is for history.

---

# Drift Detail

Drift Detail should reflect the broader model.

It should show:

- title
- type
- body/content
- created/updated date
- Spaces
- tags
- mood if available
- images if attached
- related Context Packs if available
- edit action
- delete action
- share/export action if already supported

Use “Drift” language where possible.

---

# Privacy And AI Visibility

All new AI/context concepts must remain private/local by default.

Default AI visibility:

    privateLocalOnly

Use copy:

    Drifts are private by default. You choose what to share.

Do not imply:

- MCP is live
- ChatGPT has access
- AI can automatically read Drifts
- cloud sync is required

Context Pack copy/share is local and user-controlled.

---

# UI Style

Keep the current Drift style:

- dark navy/black background
- purple accent
- rounded cards
- soft borders
- SFSymbols only
- no photography
- no illustrations
- calm spacing
- smooth animations
- Apple-native minimalism

Avoid making Drift feel like a generic AI dashboard.

Avoid cramped layouts.

Use the latest UI mockups and current app screenshots as visual reference.

---

# Architecture

Keep existing architecture:

- SwiftUI
- MVVM-C
- SwiftData
- dependency injection
- service protocols
- Swift Testing
- Mockable

Do not put business logic in SwiftUI views.

Use ViewModels/services for:

- search/filtering
- Space membership
- Context Pack membership
- Markdown generation
- Timeline filtering
- Drift Type handling

Use adapters/mappers if the codebase still has old JournalEntry naming internally.

Do not perform a risky full rename unless it is clearly safe.

Stability matters more than perfect naming.

---

# Persistence

Persist safely:

- Drift Type
- Spaces
- Drift-to-Space membership
- Context Packs
- Context Pack membership
- AI visibility
- tags/mood/images as already supported

Existing entries must remain accessible.

Existing entries should default to:

- Drift Type: Reflection
- AI Visibility: privateLocalOnly

Do not perform destructive migrations.

Do not delete or hide data.

---

# Tests

Add or update Swift Testing tests where practical for:

- Capture search ranking
- type filtering
- creating a Space
- editing a Space
- deleting a Space does not delete Drifts
- adding a Drift to a Space
- removing a Drift from a Space does not delete it
- creating a Context Pack
- adding Spaces to a Context Pack
- adding Drifts to a Context Pack
- Markdown Context Pack generation
- Context Pack export only includes selected content
- existing entries default to Reflection
- AIVisibility defaults to privateLocalOnly
- Timeline still loads historical Drifts

Avoid brittle UI tests.

---

# Keep Compiling

Keep the app compiling.

Do not break:

- voice capture
- recording
- transcription
- listen-back
- silence handling
- Review Drift
- local persistence
- Timeline/calendar
- images
- mood graph
- reminders
- backup/restore
- paywall foundation
- StoreKit
- settings
- export
- test suite

---

# Final Summary

After implementation, summarise:

- Capture/Home improvements
- Review Drift improvements
- Spaces improvements
- Space Detail improvements
- Context Pack improvements
- Markdown export behaviour
- Timeline changes if any
- screenshots captured and their paths
- key code changes/snippets
- tests added/updated
- manual testing steps
- any remaining TODOs
