//
//  LocalImageAttachmentService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import UIKit

actor LocalImageAttachmentService: ImageAttachmentService {
  nonisolated let baseDirectory: URL
  private let fileManager: FileManager
  private let now: () -> Date

  init(
    fileManager: FileManager = .default,
    baseDirectory: URL? = nil,
    now: @escaping () -> Date = Date.init
  ) {
    self.fileManager = fileManager
    self.baseDirectory =
      baseDirectory
      ?? fileManager
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?
      .appendingPathComponent("Drift/ImageAttachments", isDirectory: true)
      ?? fileManager.temporaryDirectory.appendingPathComponent(
        "Drift/ImageAttachments",
        isDirectory: true
      )
    self.now = now
  }

  func saveImageAttachment(_ input: ImageAttachmentInput) async throws -> JournalImageAttachment {
    let id = UUID()
    let fileName = "\(id.uuidString).jpg"
    let thumbnailFileName = "\(id.uuidString)-thumb.jpg"

    do {
      try ensureDirectoryExists()
      let processedImage = try await Task.detached(priority: .utility) {
        try Self.processImageData(input.data)
      }.value

      try processedImage.imageData.write(to: imageURL(fileName: fileName), options: .atomic)
      try processedImage.thumbnailData.write(
        to: imageURL(fileName: thumbnailFileName),
        options: .atomic
      )

      return JournalImageAttachment(
        id: id,
        localFileName: fileName,
        createdAt: now(),
        originalFileName: input.originalFileName,
        width: processedImage.width,
        height: processedImage.height,
        fileSize: processedImage.imageData.count,
        thumbnailFileName: thumbnailFileName
      )
    } catch let error as ImageAttachmentServiceError {
      throw error
    } catch {
      throw ImageAttachmentServiceError.writeFailed
    }
  }

  func deleteAttachment(_ attachment: JournalImageAttachment) async {
    await deleteAttachments([attachment])
  }

  func deleteAttachments(_ attachments: [JournalImageAttachment]) async {
    for attachment in attachments {
      removeFileIfNeeded(fileName: attachment.localFileName)

      if let thumbnailFileName = attachment.thumbnailFileName {
        removeFileIfNeeded(fileName: thumbnailFileName)
      }
    }
  }

  nonisolated func imageURL(for attachment: JournalImageAttachment) -> URL {
    imageURL(fileName: attachment.localFileName)
  }

  nonisolated func thumbnailURL(for attachment: JournalImageAttachment) -> URL? {
    guard let thumbnailFileName = attachment.thumbnailFileName else { return nil }
    return imageURL(fileName: thumbnailFileName)
  }

  nonisolated private func imageURL(fileName: String) -> URL {
    baseDirectory.appendingPathComponent(fileName, isDirectory: false)
  }

  private func ensureDirectoryExists() throws {
    try fileManager.createDirectory(
      at: baseDirectory,
      withIntermediateDirectories: true
    )
  }

  private func removeFileIfNeeded(fileName: String) {
    let url = imageURL(fileName: fileName)
    guard fileManager.fileExists(atPath: url.path) else { return }
    try? fileManager.removeItem(at: url)
  }

  private nonisolated static func processImageData(_ data: Data) throws -> ProcessedImage {
    guard let image = UIImage(data: data) else {
      throw ImageAttachmentServiceError.unsupportedImage
    }

    let imageData = try jpegData(
      for: image,
      maxDimension: 1_800,
      compressionQuality: 0.82
    )
    let thumbnailData = try jpegData(
      for: image,
      maxDimension: 480,
      compressionQuality: 0.72
    )
    let size = scaledSize(for: image.size, maxDimension: 1_800)

    return ProcessedImage(
      imageData: imageData,
      thumbnailData: thumbnailData,
      width: Int(size.width.rounded()),
      height: Int(size.height.rounded())
    )
  }

  private nonisolated static func jpegData(
    for image: UIImage,
    maxDimension: CGFloat,
    compressionQuality: CGFloat
  ) throws -> Data {
    let size = scaledSize(for: image.size, maxDimension: maxDimension)
    let rendererFormat = UIGraphicsImageRendererFormat.default()
    rendererFormat.scale = 1

    let renderer = UIGraphicsImageRenderer(size: size, format: rendererFormat)
    let normalizedImage = renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }

    guard let data = normalizedImage.jpegData(compressionQuality: compressionQuality) else {
      throw ImageAttachmentServiceError.writeFailed
    }

    return data
  }

  private nonisolated static func scaledSize(
    for size: CGSize,
    maxDimension: CGFloat
  ) -> CGSize {
    guard size.width > 0, size.height > 0 else {
      return CGSize(width: maxDimension, height: maxDimension)
    }

    let longestSide = max(size.width, size.height)
    guard longestSide > maxDimension else { return size }

    let scale = maxDimension / longestSide
    return CGSize(width: size.width * scale, height: size.height * scale)
  }
}

private struct ProcessedImage: Sendable {
  let imageData: Data
  let thumbnailData: Data
  let width: Int
  let height: Int
}
