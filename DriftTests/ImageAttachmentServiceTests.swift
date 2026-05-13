//
//  ImageAttachmentServiceTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Testing
import UIKit

@testable import Drift

struct ImageAttachmentServiceTests {
  @Test
  func savesImageAndThumbnailLocally() async throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let service = LocalImageAttachmentService(baseDirectory: directory)

    let attachment = try await service.saveImageAttachment(
      ImageAttachmentInput(data: makeImageData(), originalFileName: "source.png")
    )

    #expect(attachment.originalFileName == "source.png")
    #expect(attachment.fileSize ?? 0 > 0)
    #expect(FileManager.default.fileExists(atPath: service.imageURL(for: attachment).path))
    #expect(
      FileManager.default.fileExists(atPath: service.thumbnailURL(for: attachment)?.path ?? ""))
  }

  @Test
  func deletingAttachmentRemovesLocalFiles() async throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let service = LocalImageAttachmentService(baseDirectory: directory)
    let attachment = try await service.saveImageAttachment(
      ImageAttachmentInput(data: makeImageData())
    )

    await service.deleteAttachment(attachment)

    #expect(!FileManager.default.fileExists(atPath: service.imageURL(for: attachment).path))
    #expect(
      !FileManager.default.fileExists(atPath: service.thumbnailURL(for: attachment)?.path ?? ""))
  }

  @Test
  func rejectsUnsupportedImageData() async throws {
    let directory = temporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let service = LocalImageAttachmentService(baseDirectory: directory)

    await #expect(throws: ImageAttachmentServiceError.unsupportedImage) {
      try await service.saveImageAttachment(ImageAttachmentInput(data: Data("not image".utf8)))
    }
  }

  private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("drift-image-tests-\(UUID().uuidString)", isDirectory: true)
  }

  private func makeImageData() -> Data {
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 24))
    let image = renderer.image { context in
      UIColor.systemPurple.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 24, height: 24))
    }
    return image.pngData() ?? Data()
  }
}
