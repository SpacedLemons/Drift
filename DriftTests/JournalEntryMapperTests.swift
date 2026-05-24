//
//  JournalEntryMapperTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Testing

@testable import Drift

struct JournalEntryMapperTests {
  @Test
  func mapsDomainToEntity() throws {
    let entry = makeEntry()

    let entity = try JournalEntryMapper.entity(from: entry)
    let themes = try JSONDecoder().decode([String].self, from: entity.themesData)
    let customThemes = try JSONDecoder().decode(
      [CustomJournalTheme].self,
      from: entity.customThemesData
    )
    let tags = try JSONDecoder().decode([String].self, from: entity.tagsData)
    let imageAttachments = try JSONDecoder().decode(
      [JournalImageAttachment].self,
      from: entity.imageAttachmentsData
    )
    let spaceIds = try JSONDecoder().decode(
      [UUID].self,
      from: try #require(entity.spaceIdsData)
    )

    #expect(entity.id == entry.id)
    #expect(entity.createdAt == entry.createdAt)
    #expect(entity.updatedAt == entry.updatedAt)
    #expect(entity.transcript == entry.transcript)
    #expect(entity.title == entry.title)
    #expect(entity.moodRawValue == Mood.positive.rawValue)
    #expect(entity.moodConfidence == entry.moodConfidence)
    #expect(themes == [JournalTheme.work.rawValue, JournalTheme.growth.rawValue])
    #expect(customThemes == entry.customThemes)
    #expect(tags == ["focus", "planning"])
    #expect(imageAttachments == entry.imageAttachments)
    #expect(entity.duration == entry.duration)
    #expect(entity.sourceRawValue == EntrySource.typed.rawValue)
    #expect(entity.isFavorite == true)
    #expect(entity.driftTypeRawValue == DriftType.task.rawValue)
    #expect(spaceIds == entry.spaceIds)
    #expect(entity.aiVisibilityRawValue == AIVisibility.privateLocalOnly.rawValue)
    #expect(entity.driftStatusRawValue == DriftStatus.active.rawValue)
  }

  @Test
  func mapsEntityToDomain() throws {
    let entry = makeEntry()
    let entity = makeEntity(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      transcript: entry.transcript,
      title: entry.title,
      moodRawValue: Mood.positive.rawValue,
      moodConfidence: entry.moodConfidence,
      themeRawValues: [JournalTheme.work.rawValue, JournalTheme.growth.rawValue],
      customThemes: entry.customThemes,
      tags: entry.tags,
      imageAttachments: entry.imageAttachments,
      duration: entry.duration,
      sourceRawValue: EntrySource.typed.rawValue,
      isFavorite: entry.isFavorite,
      driftTypeRawValue: DriftType.task.rawValue,
      spaceIds: entry.spaceIds,
      aiVisibilityRawValue: AIVisibility.privateLocalOnly.rawValue,
      driftStatusRawValue: DriftStatus.active.rawValue
    )

    let mappedEntry = JournalEntryMapper.model(from: entity)

    #expect(mappedEntry == entry)
  }

  @Test
  func unknownMoodMapsToUnknown() throws {
    let entity = makeEntity(moodRawValue: "legacyMood")

    let entry = JournalEntryMapper.model(from: entity)

    #expect(entry.mood == .unknown)
  }

  @Test
  func unknownThemeMapsToOther() throws {
    let entity = makeEntity(themeRawValues: [JournalTheme.work.rawValue, "legacyTheme"])

    let entry = JournalEntryMapper.model(from: entity)

    #expect(entry.themes == [.work, .other])
  }

  @Test
  func unknownSourceMapsToVoice() throws {
    let entity = makeEntity(sourceRawValue: "legacySource")

    let entry = JournalEntryMapper.model(from: entity)

    #expect(entry.source == .voice)
  }

  @Test
  func legacyDriftMetadataDefaultsSafely() throws {
    let entity = makeEntity(
      driftTypeRawValue: nil,
      aiVisibilityRawValue: nil,
      driftStatusRawValue: nil
    )

    let entry = JournalEntryMapper.model(from: entity)

    #expect(entry.driftType == .reflection)
    #expect(entry.aiVisibility == .privateLocalOnly)
    #expect(entry.driftStatus == .active)
  }

  @Test
  func optionalFieldsMapSafely() throws {
    let entity = makeEntity(
      title: nil,
      moodRawValue: nil,
      moodConfidence: nil,
      themeRawValues: [],
      tags: [],
      duration: nil,
      isFavorite: false
    )

    let entry = JournalEntryMapper.model(from: entity)

    #expect(entry.title == nil)
    #expect(entry.mood == nil)
    #expect(entry.moodConfidence == nil)
    #expect(entry.themes.isEmpty)
    #expect(entry.customThemes.isEmpty)
    #expect(entry.tags.isEmpty)
    #expect(entry.imageAttachments.isEmpty)
    #expect(entry.duration == nil)
    #expect(!entry.isFavorite)
  }

  @Test
  func arraysDurationAndFavoriteMapThroughUpdate() throws {
    let entry = makeEntry()
    let entity = makeEntity(
      themeRawValues: [JournalTheme.health.rawValue],
      tags: ["old"],
      duration: 12,
      isFavorite: false
    )

    try JournalEntryMapper.update(entity, with: entry)
    let mappedEntry = JournalEntryMapper.model(from: entity)

    #expect(mappedEntry.themes == entry.themes)
    #expect(mappedEntry.customThemes == entry.customThemes)
    #expect(mappedEntry.tags == entry.tags)
    #expect(mappedEntry.imageAttachments == entry.imageAttachments)
    #expect(mappedEntry.duration == entry.duration)
    #expect(mappedEntry.isFavorite == entry.isFavorite)
    #expect(mappedEntry.driftType == entry.driftType)
    #expect(mappedEntry.spaceIds == entry.spaceIds)
    #expect(mappedEntry.aiVisibility == entry.aiVisibility)
    #expect(mappedEntry.driftStatus == entry.driftStatus)
  }
}

private func makeEntry() -> JournalEntry {
  JournalEntry(
    id: fixtureUUID("C71E1D20-400C-4D3D-9A5B-111111111111"),
    createdAt: Date(timeIntervalSince1970: 1_778_600_000),
    updatedAt: Date(timeIntervalSince1970: 1_778_603_600),
    transcript: "A focused journal entry.",
    title: "Focused day",
    mood: .positive,
    moodConfidence: 0.82,
    themes: [.work, .growth],
    customThemes: [
      CustomJournalTheme(
        id: fixtureUUID("C71E1D20-400C-4D3D-9A5B-333333333333"),
        name: "Side project",
        createdAt: Date(timeIntervalSince1970: 1_778_600_100)
      )
    ],
    tags: ["focus", "planning"],
    duration: 94,
    source: .typed,
    isFavorite: true,
    imageAttachments: [
      JournalImageAttachment(
        id: fixtureUUID("C71E1D20-400C-4D3D-9A5B-444444444444"),
        localFileName: "image.jpg",
        createdAt: Date(timeIntervalSince1970: 1_778_600_200),
        originalFileName: "original.jpg",
        width: 1200,
        height: 900,
        fileSize: 123_456,
        thumbnailFileName: "image-thumb.jpg"
      )
    ],
    driftType: .task,
    spaceIds: [
      fixtureUUID("C71E1D20-400C-4D3D-9A5B-555555555555")
    ],
    aiVisibility: .privateLocalOnly,
    driftStatus: .active
  )
}

private func makeEntity(
  id: UUID = fixtureUUID("C71E1D20-400C-4D3D-9A5B-222222222222"),
  createdAt: Date = Date(timeIntervalSince1970: 1_778_600_000),
  updatedAt: Date = Date(timeIntervalSince1970: 1_778_603_600),
  transcript: String = "A focused journal entry.",
  title: String? = "Focused day",
  moodRawValue: String? = Mood.neutral.rawValue,
  moodConfidence: Double? = 0.5,
  themeRawValues: [String] = [JournalTheme.work.rawValue],
  customThemes: [CustomJournalTheme] = [],
  tags: [String] = ["focus"],
  imageAttachments: [JournalImageAttachment] = [],
  duration: TimeInterval? = 42,
  sourceRawValue: String = EntrySource.voice.rawValue,
  isFavorite: Bool = false,
  driftTypeRawValue: String? = DriftType.reflection.rawValue,
  spaceIds: [UUID] = [],
  aiVisibilityRawValue: String? = AIVisibility.privateLocalOnly.rawValue,
  driftStatusRawValue: String? = DriftStatus.active.rawValue
) -> JournalEntryEntity {
  JournalEntryEntity(
    id: id,
    createdAt: createdAt,
    updatedAt: updatedAt,
    transcript: transcript,
    title: title,
    moodRawValue: moodRawValue,
    moodConfidence: moodConfidence,
    themesData: (try? JSONEncoder().encode(themeRawValues)) ?? Data(),
    customThemesData: (try? JSONEncoder().encode(customThemes)) ?? Data(),
    tagsData: (try? JSONEncoder().encode(tags)) ?? Data(),
    imageAttachmentsData: (try? JSONEncoder().encode(imageAttachments)) ?? Data(),
    duration: duration,
    sourceRawValue: sourceRawValue,
    isFavorite: isFavorite,
    driftTypeRawValue: driftTypeRawValue,
    spaceIdsData: (try? JSONEncoder().encode(spaceIds)) ?? Data(),
    aiVisibilityRawValue: aiVisibilityRawValue,
    driftStatusRawValue: driftStatusRawValue
  )
}
