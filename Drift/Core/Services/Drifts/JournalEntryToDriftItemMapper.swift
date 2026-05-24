//
//  JournalEntryToDriftItemMapper.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum JournalEntryToDriftItemMapper {
  static func driftItem(from entry: JournalEntry) -> DriftItem {
    DriftItem(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      title: entry.title,
      body: entry.transcript,
      type: entry.driftType,
      mood: entry.mood,
      tags: entry.tags,
      spaces: entry.spaceIds,
      attachments: entry.imageAttachments,
      source: DriftSource(entrySource: entry.source),
      aiVisibility: entry.aiVisibility,
      status: entry.driftStatus
    )
  }

  static func driftItems(from entries: [JournalEntry]) -> [DriftItem] {
    entries.map { driftItem(from: $0) }
  }
}
