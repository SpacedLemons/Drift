//
//  ImageAttachmentService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable

struct ImageAttachmentInput: Sendable {
  let data: Data
  let originalFileName: String?

  init(data: Data, originalFileName: String? = nil) {
    self.data = data
    self.originalFileName = originalFileName
  }
}

@Mockable
protocol ImageAttachmentService {
  func saveImageAttachment(_ input: ImageAttachmentInput) async throws -> JournalImageAttachment
  func deleteAttachment(_ attachment: JournalImageAttachment) async
  func deleteAttachments(_ attachments: [JournalImageAttachment]) async
  func imageURL(for attachment: JournalImageAttachment) -> URL
  func thumbnailURL(for attachment: JournalImageAttachment) -> URL?
}
