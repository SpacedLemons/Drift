//
//  PlaceholderBackupService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

actor PlaceholderBackupService: BackupService {
  private let placeholderStatus = BackupStatus(
    isICloudBackupEnabled: false,
    iCloudAvailability: .notReady,
    lastBackupDate: nil
  )

  func loadStatus() async throws -> BackupStatus {
    placeholderStatus
  }

  func setICloudBackupEnabled(_ isEnabled: Bool) async throws -> BackupStatus {
    guard !isEnabled else { throw BackupServiceError.notImplemented }
    return placeholderStatus
  }

  func backUpNow() async throws -> BackupStatus {
    throw BackupServiceError.notImplemented
  }

  func restoreJournal() async throws -> BackupStatus {
    throw BackupServiceError.notImplemented
  }
}
