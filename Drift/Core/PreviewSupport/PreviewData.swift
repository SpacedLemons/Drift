//
//  PreviewData.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum PreviewData {
  static let baseDate = Date(timeIntervalSinceReferenceDate: 800_000_000)

  static let customThemes: [CustomJournalTheme] = [
    CustomJournalTheme(
      id: uuid("A0E6637B-B7B3-4745-96FD-D04230694767"),
      name: "Home",
      createdAt: baseDate.addingTimeInterval(-60 * 60 * 24 * 6)
    ),
    CustomJournalTheme(
      id: uuid("0A3317C4-7D49-4A77-B714-0C9E071BB437"),
      name: "Side project",
      createdAt: baseDate.addingTimeInterval(-60 * 60 * 24 * 3)
    ),
  ]

  static let journalEntries: [JournalEntry] = [
    JournalEntry(
      id: uuid("E391A44C-A7BB-4C02-8E98-1626C1DB5A11"),
      createdAt: baseDate.addingTimeInterval(-60 * 35),
      transcript:
        "I felt focused today after clearing my inbox. The quiet morning helped me settle into the work without rushing.",
      title: "Focused morning",
      mood: .positive,
      moodConfidence: 0.72,
      themes: [.productivity, .work],
      customThemes: [customThemes[1]],
      tags: ["focus", "inbox"],
      duration: 84,
      source: .voice,
      isFavorite: true,
      imageAttachments: [
        JournalImageAttachment(
          id: uuid("B0DF2AB8-5176-49B5-B494-5E213DB97FC3"),
          localFileName: "preview-focus.jpg",
          createdAt: baseDate.addingTimeInterval(-60 * 35),
          originalFileName: "focus.jpg",
          width: 1200,
          height: 900,
          fileSize: 140_000,
          thumbnailFileName: "preview-focus-thumb.jpg"
        )
      ]
    ),
    JournalEntry(
      id: uuid("9C16029B-C3E7-4E92-8D43-52E5A77B8799"),
      createdAt: baseDate.addingTimeInterval(-60 * 60 * 20),
      transcript:
        "I am a bit stressed about work this week. There are a few deadlines stacked together, so I need to keep the plan small and realistic.",
      title: "Keeping work realistic",
      mood: .stressed,
      moodConfidence: 0.68,
      themes: [.work, .challenge],
      customThemes: [customThemes[1]],
      tags: ["deadline", "planning"],
      duration: 126,
      source: .voice
    ),
    JournalEntry(
      id: uuid("B6C4D164-8262-4D0B-8B17-95B123966A55"),
      createdAt: baseDate.addingTimeInterval(-60 * 60 * 46),
      transcript:
        "Had a quiet evening and felt grateful for the walk home. Nothing big happened, but the day ended gently.",
      title: "Quiet evening",
      mood: .reflective,
      moodConfidence: 0.61,
      themes: [.gratitude, .health],
      customThemes: [customThemes[0]],
      tags: ["walk", "evening"],
      duration: 72,
      source: .voice
    ),
    JournalEntry(
      id: uuid("56F5FBF2-E4F6-4507-8981-A7C325E6F901"),
      createdAt: baseDate.addingTimeInterval(-60 * 60 * 72),
      transcript:
        "I noticed I was anxious before the call, then calmer afterwards. Preparing a few notes helped more than I expected.",
      title: "Before the call",
      mood: .anxious,
      moodConfidence: 0.65,
      themes: [.relationships, .growth],
      tags: ["call", "notes"],
      duration: 98,
      source: .voice
    ),
  ]

  private static func uuid(_ rawValue: String) -> UUID {
    UUID(uuidString: rawValue) ?? UUID()
  }
}
