//
//  JournalEntryEntity.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import SwiftData

@Model
final class JournalEntryEntity {
  @Attribute(.unique) var id: UUID
  var createdAt: Date
  var updatedAt: Date
  var transcript: String
  var title: String?
  var moodRawValue: String?
  var moodConfidence: Double?
  var themesData: Data
  var customThemesData: Data
  var tagsData: Data
  var imageAttachmentsData: Data
  var duration: TimeInterval?
  var sourceRawValue: String
  var isFavorite: Bool
  var driftTypeRawValue: String?
  var aiVisibilityRawValue: String?
  var driftStatusRawValue: String?

  init(
    id: UUID,
    createdAt: Date,
    updatedAt: Date,
    transcript: String,
    title: String?,
    moodRawValue: String?,
    moodConfidence: Double?,
    themesData: Data,
    customThemesData: Data = Data(),
    tagsData: Data,
    imageAttachmentsData: Data = Data(),
    duration: TimeInterval?,
    sourceRawValue: String,
    isFavorite: Bool,
    driftTypeRawValue: String? = nil,
    aiVisibilityRawValue: String? = nil,
    driftStatusRawValue: String? = nil
  ) {
    self.id = id
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.transcript = transcript
    self.title = title
    self.moodRawValue = moodRawValue
    self.moodConfidence = moodConfidence
    self.themesData = themesData
    self.customThemesData = customThemesData
    self.tagsData = tagsData
    self.imageAttachmentsData = imageAttachmentsData
    self.duration = duration
    self.sourceRawValue = sourceRawValue
    self.isFavorite = isFavorite
    self.driftTypeRawValue = driftTypeRawValue
    self.aiVisibilityRawValue = aiVisibilityRawValue
    self.driftStatusRawValue = driftStatusRawValue
  }
}
