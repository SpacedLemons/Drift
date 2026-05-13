//
//  ReminderSettingsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReminderSettingsViewModel {
  @ObservationIgnored
  private let reminderService: any ReminderService
  @ObservationIgnored
  private let calendar: Calendar

  private(set) var configuration: ReminderConfiguration = .default
  private(set) var permissionStatus: PermissionStatus = .unknown
  private(set) var isSaving = false
  private(set) var errorMessage: String?

  init(
    reminderService: any ReminderService,
    calendar: Calendar = .current
  ) {
    self.reminderService = reminderService
    self.calendar = calendar
  }

  var reminderTime: Date {
    calendar.date(from: configuration.time) ?? Date()
  }

  var permissionStatusText: String {
    switch permissionStatus {
    case .unknown: "Not requested"
    case .granted: "Allowed"
    case .denied: "Off"
    case .restricted: "Restricted"
    }
  }

  var permissionStatusMessage: String {
    switch permissionStatus {
    case .unknown:
      "Drift can send local reminders to help you check in. Reminders are optional."
    case .granted:
      "Drift will remind you locally. Your entries stay on this device."
    case .denied:
      "Notifications are off. You can enable them in iOS Settings if you want Drift to remind you."
    case .restricted:
      "Notifications are unavailable right now."
    }
  }

  var shouldShowPermissionRequest: Bool {
    permissionStatus == .unknown
  }

  var shouldShowSettingsLink: Bool {
    permissionStatus == .denied
  }

  var availableFrequencies: [ReminderFrequency] {
    [.daily, .weekdays, .weekends]
  }

  func load() async {
    errorMessage = nil

    do {
      configuration = try await reminderService.loadReminderConfiguration()
      permissionStatus = await reminderService.currentPermissionStatus()
    } catch {
      errorMessage = "We could not load reminder settings."
    }
  }

  func setEnabled(_ isEnabled: Bool) async {
    var updatedConfiguration = configuration
    updatedConfiguration.isEnabled = isEnabled

    if isEnabled {
      configuration.isEnabled = true

      do {
        try await ensureReminderPermission()
      } catch {
        configuration.isEnabled = false
        errorMessage = userFacingErrorMessage(for: error)
        return
      }
    }

    await persist(updatedConfiguration)
  }

  func updateReminderTime(_ date: Date) async {
    let components = calendar.dateComponents([.hour, .minute], from: date)
    var updatedConfiguration = configuration
    updatedConfiguration.time = components
    await persist(updatedConfiguration)
  }

  func setFrequency(_ frequency: ReminderFrequency) async {
    var updatedConfiguration = configuration
    updatedConfiguration.repeatFrequency = frequency
    await persist(updatedConfiguration)
  }

  func updateMessageDraft(_ message: String) {
    configuration.message = message
  }

  func saveMessage() async {
    await persist(configuration)
  }

  func requestPermission() async {
    errorMessage = nil

    do {
      try await reminderService.requestPermission()
      permissionStatus = await reminderService.currentPermissionStatus()
    } catch {
      permissionStatus = await reminderService.currentPermissionStatus()
      errorMessage = userFacingErrorMessage(for: error)
    }
  }

  func clearError() {
    errorMessage = nil
  }

  private func persist(_ updatedConfiguration: ReminderConfiguration) async {
    isSaving = true
    errorMessage = nil

    do {
      if updatedConfiguration.isEnabled {
        try await reminderService.scheduleReminder(configuration: updatedConfiguration)
      } else {
        try await reminderService.saveReminderConfiguration(updatedConfiguration)
        try await reminderService.cancelReminder()
      }

      configuration = try await reminderService.loadReminderConfiguration()
      permissionStatus = await reminderService.currentPermissionStatus()
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
    }

    isSaving = false
  }

  private func ensureReminderPermission() async throws {
    permissionStatus = await reminderService.currentPermissionStatus()

    switch permissionStatus {
    case .granted:
      return
    case .unknown:
      try await reminderService.requestPermission()
      permissionStatus = await reminderService.currentPermissionStatus()

      switch permissionStatus {
      case .granted:
        return
      case .denied:
        throw ReminderServiceError.permissionDenied
      case .restricted:
        throw ReminderServiceError.permissionRestricted
      case .unknown:
        throw ReminderServiceError.permissionDenied
      }
    case .denied:
      throw ReminderServiceError.permissionDenied
    case .restricted:
      throw ReminderServiceError.permissionRestricted
    }
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let reminderError = error as? ReminderServiceError {
      return reminderError.localizedDescription
    }

    return "We could not save this setting. Please try again."
  }
}
