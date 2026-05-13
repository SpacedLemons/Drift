//
//  JournalImageAttachment.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

struct JournalImageAttachment: Identifiable, Hashable, Codable, Sendable {
  var id: UUID
  var localFileName: String
  var createdAt: Date
  var originalFileName: String?
  var width: Int?
  var height: Int?
  var fileSize: Int?
  var thumbnailFileName: String?

  init(
    id: UUID = UUID(),
    localFileName: String,
    createdAt: Date = Date(),
    originalFileName: String? = nil,
    width: Int? = nil,
    height: Int? = nil,
    fileSize: Int? = nil,
    thumbnailFileName: String? = nil
  ) {
    self.id = id
    self.localFileName = localFileName
    self.createdAt = createdAt
    self.originalFileName = originalFileName
    self.width = width
    self.height = height
    self.fileSize = fileSize
    self.thumbnailFileName = thumbnailFileName
  }
}
