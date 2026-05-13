//
//  PreviewImageAttachmentService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

actor PreviewImageAttachmentService: ImageAttachmentService {
  nonisolated let baseDirectory: URL
  private var attachments: [JournalImageAttachment] = []

  init(baseDirectory: URL = FileManager.default.temporaryDirectory) {
    self.baseDirectory = baseDirectory.appendingPathComponent(
      "DriftPreviewImages",
      isDirectory: true
    )
  }

  func saveImageAttachment(_ input: ImageAttachmentInput) async throws -> JournalImageAttachment {
    let attachment = JournalImageAttachment(
      localFileName: "\(UUID().uuidString).jpg",
      originalFileName: input.originalFileName,
      fileSize: input.data.count
    )
    attachments.append(attachment)
    return attachment
  }

  func deleteAttachment(_ attachment: JournalImageAttachment) async {
    attachments.removeAll { $0.id == attachment.id }
  }

  func deleteAttachments(_ attachments: [JournalImageAttachment]) async {
    let ids = Set(attachments.map(\.id))
    self.attachments.removeAll { ids.contains($0.id) }
  }

  nonisolated func imageURL(for attachment: JournalImageAttachment) -> URL {
    baseDirectory.appendingPathComponent(attachment.localFileName, isDirectory: false)
  }

  nonisolated func thumbnailURL(for attachment: JournalImageAttachment) -> URL? {
    guard let thumbnailFileName = attachment.thumbnailFileName else { return nil }
    return baseDirectory.appendingPathComponent(thumbnailFileName, isDirectory: false)
  }
}
