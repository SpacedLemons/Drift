# Drift Product Reframe Goal

Follow the updated README/project brief.

We are beginning the product migration from:

    voice journal

to:

    voice-first personal context board for AI

This goal is the first implementation step of the reframe.

Do not rebuild the whole app.

Do not add MCP.
Do not add ChatGPT integration.
Do not add backend/networking.
Do not add OpenAI.
Do not remove existing journal data.
Do not break the current MVP.

The goal is to carefully introduce the new product architecture and terminology while keeping the app functional.

---

# Core Direction

Drift should become:

> A voice-first personal context board for AI.

Slogan:

> Let your thoughts Drift.

A Drift can be:

- thought
- reflection
- goal
- idea
- memory
- mood
- decision
- task
- visual
- context

The current journal entry should become a Reflection Drift.

---

# Implementation Strategy

Do this incrementally.

Do not perform a massive unsafe rename across the entire project.

Prefer compatibility layers, type aliases, adapters, and staged migration.

Existing app behaviour must continue to work.

Existing persisted data must remain accessible.

---

# Step 1: Add New Domain Models

Add new domain models while keeping existing models working.

Create:

- DriftItem
- DriftType
- DriftSpace
- ContextPack
- AIVisibility
- DriftSource
- DriftStatus
- DriftCaptureProposal
- DriftAction

If similar models already exist, extend or adapt them cleanly.

Suggested models:

    DriftItem
    DriftType
    DriftSpace
    ContextPack
    AIVisibility
    DriftCaptureProposal

Keep models Codable, Hashable, Identifiable where appropriate.

Use stable raw values.

---

# DriftItem

A DriftItem should support:

- id
- createdAt
- updatedAt
- title
- body/transcript
- type
- mood
- tags
- spaces
- attachments
- source
- aiVisibility
- status
- linkedDriftIds
- linkedGoalIds if useful

Do not remove JournalEntry yet.

Map JournalEntry to DriftItem where practical.

For now, existing journal entries can be represented as:

    DriftType.reflection

---

# DriftType

Add types:

- thought
- reflection
- goal
- idea
- memory
- mood
- decision
- task
- visual
- context

Use compact switch formatting for display names and symbols.

Example:

    switch self {
    case .thought: "Thought"
    case .reflection: "Reflection"
    case .goal: "Goal"
    }

---

# DriftSpace

Add a Space model.

A Space is a board/collection for Drifts.

Fields should include:

- id
- name
- description
- icon
- color/accent if supported
- createdAt
- updatedAt
- isPinned
- aiVisibility

Do not fully replace themes/categories yet.

Instead, prepare a migration path where current custom themes can later become Spaces.

---

# ContextPack

Add a ContextPack model.

A Context Pack is a curated group of Drifts/Spaces that can be copied/shared with AI.

Fields should include:

- id
- name
- description
- driftIds
- spaceIds
- createdAt
- updatedAt
- aiVisibility

Do not add MCP.

Do not add backend.

For now, Context Packs are local-only.

---

# AIVisibility

Add visibility model:

- privateLocalOnly
- availableForInAppAI
- availableForChatGPT

Default should always be:

    privateLocalOnly

No existing data should become AI-visible by default.

---

# Step 2: Add Service Protocols

Add protocol scaffolding for future architecture.

Create:

- DriftRepository
- DriftCapturePipeline
- DriftClassificationService
- DriftSearchService
- ContextPackService
- ContextExportService

Do not fully implement AI-backed services yet.

Use local/placeholder implementations only where needed.

Current JournalRepository can remain the source of truth for now.

Add adapters where useful:

- JournalEntryToDriftItemMapper
- DriftItemToJournalEntryMapper, if needed

Do not duplicate persistence unnecessarily.

---

# Step 3: UI Terminology Prep

Begin replacing user-facing text where safe.

Prefer:

- Drift
- Drifts
- Capture
- Reflection
- Spaces
- Timeline
- Context

Avoid overusing:

- Journal
- Journal Entry

But do not break screens/routes if renaming them would be risky.

Safe UI copy updates:

- “Review Entry” can become “Review Drift”
- “New Entry” can become “New Drift”
- “Journal” tab can remain temporarily if changing it is risky
- “Entries” can become “Drifts” where safe
- “Themes” can remain temporarily until Spaces are implemented

Do not rename files/routes aggressively unless safe.

---

# Step 4: Add Type Selection In Review

In the review flow, add a simple Drift Type selector.

When a user records/captures something, the Review screen should allow selecting:

- Reflection
- Thought
- Goal
- Idea
- Memory
- Mood
- Decision
- Task
- Visual
- Context

Default for existing voice capture:

    Reflection

This is the first user-visible step away from pure journaling.

Do not add AI classification yet.

Manual type selection is enough for now.

Persist selected type if the current persistence model can support it safely.

If persistence cannot support it yet, add the field with a safe migration or store it as metadata.

---

# Step 5: Add Spaces Placeholder

Add a lightweight Spaces screen or placeholder if safe.

Do not fully build Spaces yet.

The screen should explain:

    Spaces help you group related Drifts, like goals, ideas, moodboards, and projects.

If current themes/categories can be shown as early Spaces, do that carefully.

Otherwise create a minimal local placeholder with:

- Inbox
- Goals
- Ideas
- Memories

Keep the UI consistent with Drift.

---

# Step 6: Add Context Pack Placeholder

Add a local-only Context Packs placeholder if safe.

Purpose:

- explain future AI context packs
- prepare architecture
- no MCP
- no backend

Copy:

    Context Packs let you collect Drifts and share them with AI when you choose.

Add a simple placeholder action:

    Copy Context for ChatGPT

If easy, generate a simple Markdown export from selected/recent Drifts.

If not easy, leave as polished placeholder.

Do not add ChatGPT API integration.

---

# Step 7: Navigation Direction

Move gently toward the future navigation:

- Capture
- Spaces
- Timeline
- Settings

Do not fully restructure navigation if risky.

If the current app uses:

- Journal
- Insights
- Settings

Then either:

1. keep current tabs for now and add Spaces/Context gradually, or
2. rename Journal to Capture/Timeline only if safe.

Prioritise stability.

---

# Step 8: Persistence Safety

Do not break existing SwiftData data.

If adding fields to persistence:

- use optional/default values
- default existing entries to reflection
- default AI visibility to privateLocalOnly
- default status to active

Do not perform destructive migrations.

Do not delete or hide old entries.

---

# Step 9: Privacy

Default all new AI/context functionality to private/local only.

Use copy:

    Drifts are private by default. You choose what to share with AI.

Do not imply ChatGPT access exists yet.

Do not say MCP is live.

Do not say AI can reference Drifts until that functionality exists.

---

# Tests

Add or update Swift Testing tests for:

- DriftType display names
- DriftType default for existing entries
- AIVisibility defaults to privateLocalOnly
- JournalEntry to DriftItem mapping
- Review screen saves selected Drift type
- ContextPack model creation
- DriftSpace model creation
- no existing entries are hidden or lost

Use Mockable-generated mocks where practical.

---

# Keep Compiling

Keep the app compiling.

Do not break:

- voice capture
- review/save flow
- local persistence
- calendar
- images
- mood graph
- reminders
- backup/restore
- paywall foundation
- settings
- export
- test suite

---

# Final Summary

After implementation, summarise:

- new models added
- new services/protocols added
- terminology changes made
- Review Drift type selection
- Spaces placeholder
- Context Pack placeholder
- persistence/migration safety
- tests added/updated
- remaining work to complete the full product pivot
