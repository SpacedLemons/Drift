//
//  BackupSettingsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 17/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class BackupSettingsViewModel {
  @ObservationIgnored
  private let backupService: any BackupService
  @ObservationIgnored
  private let calendar: Calendar
  @ObservationIgnored
  private let locale: Locale
  @ObservationIgnored
  private let timeZone: TimeZone

  private(set) var status: BackupStatus = .default
  private(set) var isLoading = false
  private(set) var isSavingToggle = false
  private(set) var isBackingUp = false
  private(set) var isRestoring = false
  private(set) var errorMessage: String?
  private(set) var successMessage: String?

  init(
    backupService: any BackupService,
    calendar: Calendar = .current,
    locale: Locale = .current,
    timeZone: TimeZone = .current
  ) {
    self.backupService = backupService
    self.calendar = calendar
    self.locale = locale
    self.timeZone = timeZone
  }

  var iCloudBackupValue: String {
    switch status.iCloudAvailability {
    case .available: status.isICloudBackupEnabled ? "On" : "Off"
    case .unavailable: "Unavailable"
    case .notSignedIn: "Sign in"
    case .notReady: "Unavailable"
    }
  }

  var iCloudAvailabilityMessage: String {
    switch status.iCloudAvailability {
    case .available:
      "iCloud Backup stores a copy of your Drifts in your private iCloud account."
    case .unavailable:
      "iCloud is not available on this device."
    case .notSignedIn:
      "Sign in to iCloud on this device to use Drift backup."
    case .notReady:
      "iCloud backup is not ready in this build yet."
    }
  }

  var canToggleICloudBackup: Bool {
    status.iCloudAvailability == .available && !isSavingToggle
  }

  var canBackUpNow: Bool {
    status.iCloudAvailability == .available && !isBackingUp
  }

  var canRestore: Bool {
    status.iCloudAvailability == .available && !isRestoring
  }

  var lastBackupText: String {
    guard let lastBackupDate = status.lastBackupDate else {
      return "Last backup: Never"
    }

    if calendar.isDateInToday(lastBackupDate) {
      return "Last backup: Today at \(timeString(for: lastBackupDate))"
    }

    return "Last backup: \(dateTimeString(for: lastBackupDate))"
  }

  func load() async {
    isLoading = true
    errorMessage = nil
    successMessage = nil
    defer { isLoading = false }

    do {
      status = try await backupService.loadStatus()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
    }
  }

  func setICloudBackupEnabled(_ isEnabled: Bool) async {
    guard canToggleICloudBackup else {
      errorMessage = iCloudAvailabilityMessage
      return
    }

    isSavingToggle = true
    errorMessage = nil
    successMessage = nil
    defer { isSavingToggle = false }

    do {
      status = try await backupService.setICloudBackupEnabled(isEnabled)
      successMessage = isEnabled ? "iCloud Backup is on." : "iCloud Backup is off."
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
    }
  }

  func backUpNow() async {
    guard canBackUpNow else {
      errorMessage = iCloudAvailabilityMessage
      return
    }

    isBackingUp = true
    errorMessage = nil
    successMessage = nil
    defer { isBackingUp = false }

    do {
      status = try await backupService.backUpNow()
      successMessage = "Backup complete."
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
    }
  }

  func restoreJournal() async {
    guard canRestore else {
      errorMessage = iCloudAvailabilityMessage
      return
    }

    isRestoring = true
    errorMessage = nil
    successMessage = nil
    defer { isRestoring = false }

    do {
      status = try await backupService.restoreJournal()
      successMessage = "Restore complete. Existing Drifts stayed on this device."
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
    }
  }

  func clearMessages() {
    errorMessage = nil
    successMessage = nil
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let backupError = error as? BackupServiceError {
      return backupError.localizedDescription
    }

    return "We could not update Backup & Restore. Please try again."
  }

  private func timeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = locale
    formatter.timeZone = timeZone
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
  }

  private func dateTimeString(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = locale
    formatter.timeZone = timeZone
    formatter.dateFormat = "d MMM yyyy HH:mm"
    return formatter.string(from: date)
  }
}
