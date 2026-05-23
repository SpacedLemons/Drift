//
//  BackupStatus.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation

struct BackupStatus: Equatable, Sendable {
  var isICloudBackupEnabled: Bool
  var iCloudAvailability: BackupAvailability
  var lastBackupDate: Date?

  static let `default` = BackupStatus(
    isICloudBackupEnabled: false,
    iCloudAvailability: .unavailable,
    lastBackupDate: nil
  )
}

enum BackupAvailability: Hashable, Sendable {
  case available
  case unavailable
  case notSignedIn
  case notReady
}
