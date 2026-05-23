//
//  BackupServiceError.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation

enum BackupServiceError: LocalizedError, Equatable {
  case iCloudUnavailable
  case notSignedIn
  case backupFailed
  case restoreFailed
  case noBackupFound
  case notImplemented

  var errorDescription: String? {
    switch self {
    case .iCloudUnavailable:
      "iCloud is not available on this device."
    case .notSignedIn:
      "Sign in to iCloud on this device to use Drift backup."
    case .backupFailed:
      "We could not complete the backup. Please try again."
    case .restoreFailed:
      "We could not restore your journal. Please try again."
    case .noBackupFound:
      "No Drift backup was found in iCloud."
    case .notImplemented:
      "iCloud backup is not ready in this build yet."
    }
  }
}
