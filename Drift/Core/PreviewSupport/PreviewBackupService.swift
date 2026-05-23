//
//  PreviewBackupService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation

actor PreviewBackupService: BackupService {
  private var status: BackupStatus
  private let now: @Sendable () -> Date

  init(
    status: BackupStatus = BackupStatus(
      isICloudBackupEnabled: false,
      iCloudAvailability: .available,
      lastBackupDate: nil
    ),
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.status = status
    self.now = now
  }

  func loadStatus() async throws -> BackupStatus {
    status
  }

  func setICloudBackupEnabled(_ isEnabled: Bool) async throws -> BackupStatus {
    try ensureICloudAvailable()
    status.isICloudBackupEnabled = isEnabled
    return status
  }

  func backUpNow() async throws -> BackupStatus {
    try ensureICloudAvailable()
    status.lastBackupDate = now()
    return status
  }

  func restoreJournal() async throws -> BackupStatus {
    try ensureICloudAvailable()
    guard status.lastBackupDate != nil else { throw BackupServiceError.noBackupFound }
    return status
  }

  private func ensureICloudAvailable() throws {
    switch status.iCloudAvailability {
    case .available:
      return
    case .unavailable:
      throw BackupServiceError.iCloudUnavailable
    case .notSignedIn:
      throw BackupServiceError.notSignedIn
    case .notReady:
      throw BackupServiceError.notImplemented
    }
  }
}
