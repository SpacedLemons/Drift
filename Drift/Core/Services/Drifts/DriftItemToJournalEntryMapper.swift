//
//  DriftItemToJournalEntryMapper.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum DriftItemToJournalEntryMapper {
  static func journalEntry(
    from drift: DriftItem,
    preserving existingEntry: JournalEntry? = nil
  ) -> JournalEntry {
    JournalEntry(
      id: drift.id,
      createdAt: drift.createdAt,
      updatedAt: drift.updatedAt,
      transcript: drift.body,
      title: drift.title,
      mood: drift.mood,
      moodConfidence: existingEntry?.moodConfidence,
      themes: existingEntry?.themes ?? [],
      customThemes: existingEntry?.customThemes ?? [],
      tags: drift.tags,
      duration: existingEntry?.duration,
      source: drift.source.entrySource,
      isFavorite: existingEntry?.isFavorite ?? false,
      imageAttachments: drift.attachments,
      driftType: drift.type,
      aiVisibility: drift.aiVisibility,
      driftStatus: drift.status
    )
  }
}
