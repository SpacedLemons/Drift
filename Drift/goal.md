# Drift GPT Connection + Auto Drift Proposal Goal

Follow the updated Drift product direction.

Drift is a voice-first personal context board for AI.

This goal is to connect the current Drift app architecture with the future GPT/MCP experience in a practical way.

The goal is **not** to build the production backend/MCP server yet.

The goal is to build the full app-side architecture, UI, local proposal system, and mock GPT flow so the product behaves like GPT can suggest and create Drifts from conversations.

This should prepare Drift for the real MCP/App SDK backend later.

---

# Product Behaviour

When Drift is connected to GPT in the future, the user should be able to talk naturally in ChatGPT.

GPT should be able to recognise useful context and say:

> I should save this as a Drift.

Then Drift should receive a proposed Drift or update.

The user should be able to review, accept, edit, or reject it.

Eventually, users may enable an auto-save mode, but for now the default must be:

> GPT suggests. User reviews before saving.

---

# Important Constraints

Do not build the real backend.
Do not build the real MCP server.
Do not add OpenAI API calls.
Do not add Claude/Gemini.
Do not add networking unless already required by existing app code.
Do not upload private Drifts.
Do not silently save GPT-created Drifts without review.
Do not break the existing local app.

Everything in this goal should work locally with mock/prototype data.

---

# Verification Requirement

After making changes:

1. Build the project if practical.
2. Run the relevant SwiftUI previews or simulator screens if practical.
3. Take screenshots of the simulator or SwiftUI previews for changed screens.
4. Include screenshot paths/locations in the final summary.
5. Show the important code changes made, especially new/updated files and key snippets.
6. Summarise what changed and how to manually test it.

If screenshots cannot be captured, explain why and still provide the key code changes.

---

# Core UX

The GPT tab should become the main place where users manage the GPT connection.

The tab should support these states:

1. Not connected
2. Connect to GPT
3. Connected
4. GPT activity
5. Pending GPT updates
6. Manage connection

The tab should not show markdown starter prompts anymore.

The tab should not show confusing context selection/review screens as the main experience.

The product should feel simple:

- Connect to GPT
- GPT can create Drifts
- GPT can update ongoing topics
- GPT suggests Spaces
- User reviews before saving
- Recent GPT activity appears here

---

# GPT Tab — Not Connected State

When not connected, the GPT tab should show:

Title:

    GPT

Subtitle:

    Connect Drift to GPT for seamless thought capture and updates.

Main card:

    GPT can create Drifts, continue ongoing topics, and keep your thoughts organised.

Primary button:

    Connect to GPT

Status cards:

    Private by default
    Drift only shares what you allow.

    Connection
    Not connected

    Local Drift identity
    Ready

Do not mention markdown.

Do not mention starter prompts.

Do not imply the real MCP connection is live yet.

If the connection is still local/mock-only, label it clearly in DEBUG or internal copy where appropriate.

---

# Connect To GPT Flow

When the user taps Connect to GPT, show a full-screen/native flow.

This flow should support future authentication but remain local/mock for now.

Screen title:

    Connect to GPT

Copy:

    Use a secure native sign-in to connect Drift.

Options:

    Continue with Passkey
    Continue with Apple

For now, these can be local/mock actions that transition the app into a connected mock state.

Do not implement real passkeys yet.
Do not implement Sign in with Apple yet.
Do not add backend auth yet.

Add clear TODOs:

- passkey registration
- Apple sign-in fallback
- OAuth for future MCP
- backend token exchange

Also include reassurance:

    No email or password is needed for local Drift use.

    You can disconnect at any time.

---

# GPT Tab — Connected State

When connected, the GPT tab should show:

Title:

    GPT

Subtitle:

    Connected and ready to help.

Connected status card:

    Connected to GPT
    Secure connection active

Capabilities section:

    What GPT can do

Rows:

- Create Drifts
- Update ongoing topics
- Suggest Spaces
- Review before saving

Each should show an enabled/check state.

Recent activity section:

    Recent activity

Example rows:

- Created Drift · Product idea
- Updated Drift · OpenAI Career
- Suggested Space · Drift App

Actions:

- Manage connection
- Disconnect

Disconnect should use destructive styling and confirmation.

Disconnecting should not delete local Drifts.

---

# GPT Activity Model

Add a local model for GPT activity.

Suggested model:

    GPTActivityItem

Fields:

- id
- createdAt
- kind
- title
- subtitle
- relatedDriftId
- relatedSpaceId
- status

Kinds:

- createdDrift
- updatedDrift
- suggestedSpace
- createdProposal
- acceptedProposal
- rejectedProposal

This is local/mock for now.

Later it can be backed by MCP/backend events.

---

# Drift Proposal System

Add or complete a proposal system.

This is the key architecture for future MCP.

GPT should not directly mutate private data by default.

It should create proposals.

Add models:

    DriftProposal

    DriftProposalAction

    DriftProposalStatus

Possible actions:

- createNewDrift
- updateExistingDrift
- appendToSpace
- suggestSpace
- createContextPack

Possible status:

- pending
- accepted
- rejected
- edited
- saved

Proposal fields:

- id
- createdAt
- updatedAt
- source
- action
- status
- title
- body
- suggestedDriftType
- suggestedSpaceIds
- suggestedTags
- suggestedMood
- targetDriftId
- targetSpaceId
- confidence
- summary

Source should include:

    gpt

The default state should be:

    pending

---

# Pending GPT Updates

Add a section in the GPT tab:

    Pending GPT Updates

If none:

    No pending updates.
    When GPT suggests a new Drift or update, it will appear here for review.

If there are pending proposals, show cards.

Each card should show:

- proposed title
- action type
- suggested Space
- short summary
- created date/time
- status

Actions:

- Review
- Accept
- Reject

Accept should create/update the local Drift using existing repositories/services.

Reject should mark the proposal as rejected.

Review should open a Review Proposal screen.

---

# Review GPT Proposal Screen

Add a screen for reviewing GPT-created proposals.

The user should be able to:

- edit title
- edit body/summary
- change Drift Type
- change Space
- change tags
- accept/save
- reject/discard

If proposal action is `createNewDrift`:

- accepting creates a new Drift

If proposal action is `updateExistingDrift`:

- accepting updates/appends to the existing Drift

If updating existing Drifts is risky or not fully implemented yet:

- support createNewDrift fully
- scaffold updateExistingDrift with TODOs
- do not break app state

Use copy:

    Review before saving

Do not silently save unless the user has explicitly enabled auto-save later.

---

# Mock GPT Flow

Add a local mock/prototype flow so the product can be tested without backend.

In DEBUG or local mode, allow generating sample GPT proposals.

Possible debug/internal action:

    Simulate GPT Drift

This should create sample proposals such as:

1. Create Drift:
   Title: Drift as AI context board
   Type: Idea
   Space: Drift App

2. Update Drift:
   Title: OpenAI Career
   Suggested update: MCPKit could become a standout project.

3. Suggest Space:
   Title: Backend Architecture
   Space: Drift App

This lets the UI be tested before MCP exists.

Keep this clearly local/mock.

Do not expose confusing debug controls in release if inappropriate.

---

# Auto Drift Mode Placeholder

Add a future-facing setting in Manage Connection:

    Auto Drift conversations

Default:

    Off

Copy:

    When enabled in the future, GPT will be able to save useful conversation moments as Drift proposals automatically.

For now:

- keep it disabled or local-only
- do not make it actually call GPT/backend
- do not silently save anything

This setting prepares the product for the future behaviour where GPT can decide:

    I should log this as a Drift.

---

# Manage Connection Screen

Add or improve a Manage GPT Connection screen.

It should include:

- connection status
- capabilities
- Auto Drift conversations placeholder
- require review before saving toggle
- selected Spaces GPT can suggest/use, if already supported
- disconnect action

Important default:

    Require review before saving: ON

Copy:

    GPT-created Drifts stay pending until you approve them.

---

# Local Identity

Use the existing anonymous local Drift identity if already implemented.

Do not treat the UUID as authentication.

Add clear comments if needed:

    Local Drift identity is not backend authentication.
    Future GPT connection requires passkeys/OAuth.

The GPT connection UI may show:

    Local Drift identity: Ready

but should not show the raw UUID.

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

Add or update:

- GPTConnectionView
- GPTConnectionViewModel
- ConnectGPTView
- ManageGPTConnectionView
- GPTActivityItem
- DriftProposal
- DriftProposalAction
- DriftProposalStatus
- DriftProposalRepository or service
- LocalGPTConnectionService
- GPTProposalService
- ReviewGPTProposalView
- ReviewGPTProposalViewModel

Views should not contain business logic.

Proposal creation, accepting, rejecting, and saving should live in services/ViewModels.

---

# Persistence

Persist locally:

- GPT connection mock/local state
- GPT activity items
- Drift proposals
- proposal status
- manage connection preferences

If persistence is too much for this goal, use a clean local repository/service and add TODOs for SwiftData persistence.

But proposals should survive basic navigation where practical.

Do not upload proposals anywhere.

---

# Privacy

Use clear copy:

    Drifts are private by default.

    GPT-created Drifts stay pending until you approve them.

    Disconnecting GPT does not delete local Drifts.

Avoid claiming:

- real GPT connection is live
- MCP is implemented
- ChatGPT can access private data
- skill installation is complete
- automatic GPT saving is live

---

# UI Style

Use the latest GPT tab mockup as visual reference.

Keep Drift style:

- dark navy/black background
- purple accent
- teal success/privacy accent
- rounded cards
- soft borders
- SFSymbols only
- no photography
- no illustrations
- calm spacing
- Apple-native minimalism

The GPT tab should feel simple, not like a settings dump.

---

# Tests

Add or update Swift Testing tests for:

- default GPT connection state is not connected
- connecting in mock mode changes state to connected
- disconnecting returns to not connected
- disconnecting does not delete local Drifts
- creating a GPT proposal adds pending proposal
- accepting createNewDrift proposal creates a Drift
- rejecting proposal marks rejected
- pending proposals appear in GPT tab state
- require review before saving defaults to true
- local Drift identity is not exposed as auth
- Auto Drift mode defaults to off

Use Mockable where practical.

---

# Keep Compiling

Keep the app compiling.

Do not break:

- Capture
- Spaces
- Context Packs
- Timeline
- voice capture
- transcription
- local persistence
- images
- backup/restore
- paywall foundation
- settings
- export
- test suite

---

# Final Summary

After implementation, summarise:

- GPT tab changes
- Connect to GPT flow
- connected state UI
- GPT activity implementation
- Drift proposal models/services
- pending updates UI
- Review GPT Proposal screen
- mock GPT proposal flow
- persistence approach
- screenshots captured and paths
- key code changes/snippets
- tests added/updated
- manual testing steps
- remaining future work for real passkeys/OAuth/MCP/backend
