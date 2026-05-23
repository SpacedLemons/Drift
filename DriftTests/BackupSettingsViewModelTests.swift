//
//  BackupSettingsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct BackupSettingsViewModelTests {
  @Test
  func loadUsesDefaultBackupStatus() async throws {
    let service = BackupServiceSpy(status: .default)
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()

    #expect(viewModel.status == .default)
    #expect(viewModel.iCloudBackupValue == "Unavailable")
    #expect(viewModel.lastBackupText == "Last backup: Never")
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func backupToggleUpdatesState() async throws {
    let service = BackupServiceSpy(
      status: BackupStatus(
        isICloudBackupEnabled: false,
        iCloudAvailability: .available,
        lastBackupDate: nil
      )
    )
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()
    await viewModel.setICloudBackupEnabled(true)

    #expect(viewModel.status.isICloudBackupEnabled)
    #expect(viewModel.iCloudBackupValue == "On")
    #expect(viewModel.successMessage == "iCloud Backup is on.")
    #expect(await service.setICloudBackupEnabledValues() == [true])
  }

  @Test
  func backUpNowCallsBackupService() async throws {
    let backupDate = Date(timeIntervalSince1970: 1_779_000_000)
    let service = BackupServiceSpy(
      status: BackupStatus(
        isICloudBackupEnabled: true,
        iCloudAvailability: .available,
        lastBackupDate: nil
      ),
      backupDate: backupDate
    )
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()
    await viewModel.backUpNow()

    #expect(viewModel.status.lastBackupDate == backupDate)
    #expect(viewModel.successMessage == "Backup complete.")
    #expect(await service.backUpNowCallCount() == 1)
  }

  @Test
  func restoreCallsBackupService() async throws {
    let backupDate = Date(timeIntervalSince1970: 1_779_000_000)
    let service = BackupServiceSpy(
      status: BackupStatus(
        isICloudBackupEnabled: true,
        iCloudAvailability: .available,
        lastBackupDate: backupDate
      )
    )
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()
    await viewModel.restoreJournal()

    #expect(viewModel.successMessage == "Restore complete. Existing entries stayed on this device.")
    #expect(await service.restoreCallCount() == 1)
  }

  @Test
  func restoreShowsNoBackupFoundCleanly() async throws {
    let service = BackupServiceSpy(
      status: BackupStatus(
        isICloudBackupEnabled: false,
        iCloudAvailability: .available,
        lastBackupDate: nil
      ),
      restoreError: .noBackupFound
    )
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()
    await viewModel.restoreJournal()

    #expect(viewModel.errorMessage == "No Drift backup was found in iCloud.")
    #expect(await service.restoreCallCount() == 1)
  }

  @Test
  func iCloudUnavailableStateDisplaysCleanly() async throws {
    let service = BackupServiceSpy(status: .default)
    let viewModel = BackupSettingsViewModel(backupService: service)

    await viewModel.load()
    await viewModel.backUpNow()

    #expect(viewModel.iCloudAvailabilityMessage == "iCloud is not available on this device.")
    #expect(viewModel.errorMessage == "iCloud is not available on this device.")
    #expect(await service.backUpNowCallCount() == 0)
  }
}

private actor BackupServiceSpy: BackupService {
  private var status: BackupStatus
  private let backupDate: Date
  private let restoreError: BackupServiceError?
  private var recordedSetICloudBackupEnabledValues: [Bool] = []
  private var recordedBackUpNowCallCount = 0
  private var recordedRestoreCallCount = 0

  init(
    status: BackupStatus,
    backupDate: Date = Date(timeIntervalSince1970: 1_779_000_000),
    restoreError: BackupServiceError? = nil
  ) {
    self.status = status
    self.backupDate = backupDate
    self.restoreError = restoreError
  }

  func loadStatus() async throws -> BackupStatus {
    status
  }

  func setICloudBackupEnabled(_ isEnabled: Bool) async throws -> BackupStatus {
    try ensureICloudAvailable()
    recordedSetICloudBackupEnabledValues.append(isEnabled)
    status.isICloudBackupEnabled = isEnabled
    return status
  }

  func backUpNow() async throws -> BackupStatus {
    try ensureICloudAvailable()
    recordedBackUpNowCallCount += 1
    status.lastBackupDate = backupDate
    return status
  }

  func restoreJournal() async throws -> BackupStatus {
    try ensureICloudAvailable()
    recordedRestoreCallCount += 1

    if let restoreError {
      throw restoreError
    }

    return status
  }

  func setICloudBackupEnabledValues() -> [Bool] {
    recordedSetICloudBackupEnabledValues
  }

  func backUpNowCallCount() -> Int {
    recordedBackUpNowCallCount
  }

  func restoreCallCount() -> Int {
    recordedRestoreCallCount
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
