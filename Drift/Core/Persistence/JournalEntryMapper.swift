//
//  JournalEntryMapper.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation

enum JournalEntryMapper {
  static func entity(from entry: JournalEntry) throws -> JournalEntryEntity {
    JournalEntryEntity(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      transcript: entry.transcript,
      title: entry.title,
      moodRawValue: entry.mood?.rawValue,
      moodConfidence: entry.moodConfidence,
      themesData: try encodeStrings(entry.themes.map(\.rawValue)),
      customThemesData: try encode(entry.customThemes),
      tagsData: try encodeStrings(entry.tags),
      imageAttachmentsData: try encode(entry.imageAttachments),
      duration: entry.duration,
      sourceRawValue: entry.source.rawValue,
      isFavorite: entry.isFavorite,
      driftTypeRawValue: entry.driftType.rawValue,
      aiVisibilityRawValue: entry.aiVisibility.rawValue,
      driftStatusRawValue: entry.driftStatus.rawValue
    )
  }

  static func update(_ entity: JournalEntryEntity, with entry: JournalEntry) throws {
    entity.createdAt = entry.createdAt
    entity.updatedAt = entry.updatedAt
    entity.transcript = entry.transcript
    entity.title = entry.title
    entity.moodRawValue = entry.mood?.rawValue
    entity.moodConfidence = entry.moodConfidence
    entity.themesData = try encodeStrings(entry.themes.map(\.rawValue))
    entity.customThemesData = try encode(entry.customThemes)
    entity.tagsData = try encodeStrings(entry.tags)
    entity.imageAttachmentsData = try encode(entry.imageAttachments)
    entity.duration = entry.duration
    entity.sourceRawValue = entry.source.rawValue
    entity.isFavorite = entry.isFavorite
    entity.driftTypeRawValue = entry.driftType.rawValue
    entity.aiVisibilityRawValue = entry.aiVisibility.rawValue
    entity.driftStatusRawValue = entry.driftStatus.rawValue
  }

  static func model(from entity: JournalEntryEntity) -> JournalEntry {
    let themeRawValues = decodeStrings(entity.themesData)
    let tags = decodeStrings(entity.tagsData)

    return JournalEntry(
      id: entity.id,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      transcript: entity.transcript,
      title: entity.title,
      mood: mood(from: entity.moodRawValue),
      moodConfidence: entity.moodConfidence,
      themes: themeRawValues.map { JournalTheme(rawValue: $0) ?? .other },
      customThemes: decode([CustomJournalTheme].self, from: entity.customThemesData),
      tags: tags,
      duration: entity.duration,
      source: EntrySource(rawValue: entity.sourceRawValue) ?? .voice,
      isFavorite: entity.isFavorite,
      imageAttachments: decode([JournalImageAttachment].self, from: entity.imageAttachmentsData),
      driftType: driftType(from: entity.driftTypeRawValue),
      aiVisibility: aiVisibility(from: entity.aiVisibilityRawValue),
      driftStatus: driftStatus(from: entity.driftStatusRawValue)
    )
  }

  private static func encode<Value: Encodable>(_ value: Value) throws -> Data {
    try JSONEncoder().encode(value)
  }

  private static func encodeStrings(_ values: [String]) throws -> Data {
    try JSONEncoder().encode(values)
  }

  private static func decodeStrings(_ data: Data) -> [String] {
    (try? JSONDecoder().decode([String].self, from: data)) ?? []
  }

  private static func decode<Value: Decodable>(_ type: [Value].Type, from data: Data) -> [Value] {
    (try? JSONDecoder().decode(type, from: data)) ?? []
  }

  private static func mood(from rawValue: String?) -> Mood? {
    guard let rawValue else { return nil }
    return Mood(rawValue: rawValue) ?? .unknown
  }

  private static func driftType(from rawValue: String?) -> DriftType {
    guard let rawValue else { return .reflection }
    return DriftType(rawValue: rawValue) ?? .reflection
  }

  private static func aiVisibility(from rawValue: String?) -> AIVisibility {
    guard let rawValue else { return .privateLocalOnly }
    return AIVisibility(rawValue: rawValue) ?? .privateLocalOnly
  }

  private static func driftStatus(from rawValue: String?) -> DriftStatus {
    guard let rawValue else { return .active }
    return DriftStatus(rawValue: rawValue) ?? .active
  }
}
