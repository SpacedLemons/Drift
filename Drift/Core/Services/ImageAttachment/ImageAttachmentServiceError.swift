//
//  ImageAttachmentServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation

enum ImageAttachmentServiceError: LocalizedError, Equatable {
  case unsupportedImage
  case writeFailed

  var errorDescription: String? {
    switch self {
    case .unsupportedImage:
      "We could not read that image. Please choose another one."
    case .writeFailed:
      "We could not save that image on this device. Please try again."
    }
  }
}
