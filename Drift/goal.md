Use this as the next Codex prompt:

```markdown
Follow the updated Drift product direction.

The app has now moved toward the Drift/Spaces/Timeline model. This prompt is focused on polishing the Capture/Home and Timeline calendar experience.

Do not add backend/networking.
Do not add MCP.
Do not add OpenAI.
Do not add new paid features.
Do not rebuild the whole app.

Keep Drift local-first and private.

---

# Verification Requirement

After making changes:

1. Build the project if practical.
2. Run the relevant SwiftUI preview or simulator screen if practical.
3. Take a screenshot of the simulator or SwiftUI preview.
4. Include the screenshot path/location in the final summary.
5. Show the important code changes made, especially new/updated files and key snippets.
6. Summarise what was changed and how to manually test it.

If a screenshot cannot be captured, explain why and still provide the key code changes.

---

# Goal

Polish the Drift Capture/Home screen and Timeline calendar interactions so the app feels smooth, native, and intentional.

Focus on:

1. Native inline navigation title behaviour for “Drift”
2. Drift-styled global search on Capture/Home
3. Better Drift type filtering
4. Smooth calendar chevron animation
5. Seamless month transition animation in Timeline/calendar
6. General Capture/Home polish

---

# 1. Native Inline / Large Title Behaviour

The Capture/Home screen should use standard SwiftUI navigation title behaviour.

Use the standard SwiftUI navigation title system so:

- “Drift” appears as the large title when at the top
- it collapses into the small inline title at the top when scrolling
- behaviour feels native to iOS
- avoid custom title hacks if the native navigation system can do this cleanly

Use something like the standard navigation title approach rather than manually animating a fake title.

Expected feel:

- at top: large “Drift”
- when scrolling: small inline “Drift” in navigation bar

Keep the subtitle below the title area:

    Let your thoughts Drift.

The subtitle should remain part of the page content.

---

# 2. Capture/Home Search Bar

Add a Drift-styled search bar underneath:

    Let your thoughts Drift.

The search bar should search across the user’s local Drifts.

Search should include:

- title
- body/description/transcript
- tags
- Drift Type
- Space name if available
- mood if useful

Search ranking should be sensible:

1. Strongest match: title
2. Next: tags/spaces/type
3. Then: body/description/transcript

This means title matches should rank higher than body-only matches.

Example:

If the query is “OpenAI”:

- title containing “OpenAI” should appear above a Drift where OpenAI is only mentioned once in the body.

Search should feel reasonably good without requiring backend/AI.

Do not add semantic search yet.

This should be local-only.

No backend.

No OpenAI.

No MCP.

---

# Search UI Requirements

The search bar should match Drift’s style:

- dark rounded capsule/card
- subtle border
- SFSymbol `magnifyingglass`
- placeholder copy such as:

    Search your Drifts

- clear button if text is entered
- smooth animation when results update
- no generic white iOS search field if it clashes with the Drift design

If the app already has a reusable SearchBar component, update/reuse it.

---

# Search Behaviour

When search text is empty:

- show normal recent Drifts list

When search text is non-empty:

- show matching Drifts
- show a clear no-results state if nothing matches

Suggested no-results copy:

    No matching Drifts.
    Try another word or phrase.

Search should be case-insensitive and trim whitespace.

Debounce only if needed.

Do not over-engineer.

---

# 3. Drift Type Filters

Keep/refine quick type filter chips.

Suggested filters:

- All
- Thought
- Reflection
- Goal
- Idea
- Memory
- Task

Filters should work together with search.

Example:

- selected filter: Goal
- search: “OpenAI”
- result: only Goal Drifts matching OpenAI

Keep the filter UI compact and smooth.

---

# 4. Calendar Chevron Animation

In Timeline/calendar, animate the chevron when expanding/collapsing the calendar.

Expected behaviour:

- collapsed state: chevron points down or appropriate collapsed direction
- expanded state: chevron rotates smoothly
- animation should feel native and subtle
- no jumpy layout

Use a simple rotation animation.

Do not rewrite the whole calendar component if only the chevron animation is needed.

---

# 5. Smooth Month Transition Animation

Improve Timeline/calendar month switching.

When the user changes month:

- current month should slide out
- new month should slide in
- direction should match navigation:
  - next month slides from right
  - previous month slides from left
- transition should feel seamless and smooth
- avoid flickering/reloading jank
- keep selected date behaviour correct

This applies to:

- swipe month navigation
- previous/next month controls if present

Keep the existing calendar model/data logic intact.

Do not remove Timeline calendar functionality.

---

# 6. Capture/Home Recent Drifts

Recent Drift cards should remain clean and easy to scan.

Cards should show where available:

- title
- short body preview
- Drift Type
- time/date
- Space
- mood
- image indicator

Existing old journal/reflection entries should still appear as Reflection Drifts.

---

# 7. Empty States

If there are no Drifts, show:

    No Drifts yet.
    Tap the microphone when you are ready to capture a thought.

If search has no results, show:

    No matching Drifts.
    Try another word or phrase.

Use SFSymbols only.

No illustrations.

---

# 8. UI Style

Keep the current Drift style:

- dark navy/black background
- purple accent
- rounded cards
- soft borders
- SFSymbols only
- no illustrations
- no photography
- smooth animations
- Apple-native minimalism

Avoid making the screen look like a generic AI dashboard.

---

# 9. Architecture

Keep the existing MVVM-C architecture.

Do not put filtering/search ranking/business logic directly in SwiftUI views.

Use ViewModel or service logic for:

- search query
- ranked search results
- type filter
- empty state
- recent Drifts
- month transition direction
- calendar expanded/collapsed state

If useful, create a small local search helper/service such as:

    DriftSearchRankingService

or keep it in the ViewModel if the code remains simple.

Do not add backend search.

Do not add AI search.

---

# 10. Tests

Add or update tests where practical for:

- search trims whitespace
- search is case-insensitive
- title matches rank above body matches
- tag/space matches work if supported
- type filter works
- search and type filter combine correctly
- empty search returns normal recent Drifts
- no-results state works
- calendar chevron state changes correctly
- month navigation direction is calculated correctly

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
- review/save
- Spaces
- Context Packs
- Timeline/calendar
- local persistence
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

- Capture/Home title behaviour changes
- search bar implementation
- search ranking behaviour
- Drift type filter behaviour
- calendar chevron animation
- month transition animation
- screenshot path/location
- key code changes/snippets
- tests added/updated
- manual testing steps
```
