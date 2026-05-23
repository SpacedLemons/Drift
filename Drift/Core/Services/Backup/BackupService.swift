//
//  BackupService.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Mockable

@Mockable
protocol BackupService {
  func loadStatus() async throws -> BackupStatus
  func setICloudBackupEnabled(_ isEnabled: Bool) async throws -> BackupStatus
  func backUpNow() async throws -> BackupStatus
  func restoreJournal() async throws -> BackupStatus
}
