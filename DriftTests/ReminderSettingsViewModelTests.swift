//
//  ReminderSettingsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable
import Testing
import UserNotifications

@testable import Drift

@MainActor
struct ReminderSettingsViewModelTests {
  @Test
  func loadUsesDefaultReminderConfiguration() async throws {
    let service = MockReminderService()
    given(service)
      .loadReminderConfiguration().willReturn(.default)
      .currentPermissionStatus().willReturn(.granted)
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.load()

    #expect(viewModel.configuration == .default)
    #expect(viewModel.permissionStatus == .granted)
    verify(service)
      .loadReminderConfiguration().called(.once)
      .currentPermissionStatus().called(.once)
  }

  @Test
  func enablingRemindersRequestsPermissionWhenNeededAndSchedulesReminder() async throws {
    var enabledConfiguration = ReminderConfiguration.default
    enabledConfiguration.isEnabled = true

    let service = MockReminderService()
    given(service)
      .currentPermissionStatus().willReturn(.unknown)
      .currentPermissionStatus().willReturn(.granted)
      .currentPermissionStatus().willReturn(.granted)
      .requestPermission().willReturn()
      .scheduleReminder(configuration: .value(enabledConfiguration)).willReturn()
      .loadReminderConfiguration().willReturn(enabledConfiguration)
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.setEnabled(true)

    #expect(viewModel.configuration.isEnabled)
    #expect(viewModel.permissionStatus == .granted)
    verify(service)
      .requestPermission().called(.once)
      .scheduleReminder(configuration: .value(enabledConfiguration)).called(.once)
  }

  @Test
  func changingTimeSchedulesReminderWhenEnabled() async throws {
    var enabledConfiguration = ReminderConfiguration.default
    enabledConfiguration.isEnabled = true
    var updatedConfiguration = enabledConfiguration
    updatedConfiguration.time = DateComponents(hour: 7, minute: 45)
    let newTime = fixtureDate(
      calendar: reminderTestCalendar,
      year: 2026,
      month: 5,
      day: 13,
      hour: 7,
      minute: 45
    )

    let service = MockReminderService()
    given(service)
      .loadReminderConfiguration().willReturn(enabledConfiguration)
      .loadReminderConfiguration().willReturn(updatedConfiguration)
      .currentPermissionStatus().willReturn(.granted)
      .currentPermissionStatus().willReturn(.granted)
      .scheduleReminder(configuration: .value(updatedConfiguration)).willReturn()
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.load()
    await viewModel.updateReminderTime(newTime)

    #expect(viewModel.configuration.time.hour == 7)
    #expect(viewModel.configuration.time.minute == 45)
    verify(service)
      .scheduleReminder(configuration: .value(updatedConfiguration)).called(.once)
  }

  @Test
  func changingFrequencyReschedulesReminderWhenEnabled() async throws {
    var enabledConfiguration = ReminderConfiguration.default
    enabledConfiguration.isEnabled = true
    var updatedConfiguration = enabledConfiguration
    updatedConfiguration.repeatFrequency = .weekdays

    let service = MockReminderService()
    given(service)
      .loadReminderConfiguration().willReturn(enabledConfiguration)
      .loadReminderConfiguration().willReturn(updatedConfiguration)
      .currentPermissionStatus().willReturn(.granted)
      .currentPermissionStatus().willReturn(.granted)
      .scheduleReminder(configuration: .value(updatedConfiguration)).willReturn()
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.load()
    await viewModel.setFrequency(.weekdays)

    #expect(viewModel.configuration.repeatFrequency == .weekdays)
    verify(service)
      .scheduleReminder(configuration: .value(updatedConfiguration)).called(.once)
  }

  @Test
  func savingMessageReschedulesReminderWhenEnabled() async throws {
    var enabledConfiguration = ReminderConfiguration.default
    enabledConfiguration.isEnabled = true
    var updatedConfiguration = enabledConfiguration
    updatedConfiguration.message = "Pause and check in."

    let service = MockReminderService()
    given(service)
      .loadReminderConfiguration().willReturn(enabledConfiguration)
      .loadReminderConfiguration().willReturn(updatedConfiguration)
      .currentPermissionStatus().willReturn(.granted)
      .currentPermissionStatus().willReturn(.granted)
      .scheduleReminder(configuration: .value(updatedConfiguration)).willReturn()
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.load()
    viewModel.updateMessageDraft("Pause and check in.")
    await viewModel.saveMessage()

    #expect(viewModel.configuration.message == "Pause and check in.")
    verify(service)
      .scheduleReminder(configuration: .value(updatedConfiguration)).called(.once)
  }

  @Test
  func disablingRemindersCancelsReminder() async throws {
    var enabledConfiguration = ReminderConfiguration.default
    enabledConfiguration.isEnabled = true
    var disabledConfiguration = enabledConfiguration
    disabledConfiguration.isEnabled = false

    let service = MockReminderService()
    given(service)
      .loadReminderConfiguration().willReturn(enabledConfiguration)
      .loadReminderConfiguration().willReturn(disabledConfiguration)
      .currentPermissionStatus().willReturn(.granted)
      .currentPermissionStatus().willReturn(.granted)
      .saveReminderConfiguration(.value(disabledConfiguration)).willReturn()
      .cancelReminder().willReturn()
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.load()
    await viewModel.setEnabled(false)

    #expect(!viewModel.configuration.isEnabled)
    verify(service)
      .saveReminderConfiguration(.value(disabledConfiguration)).called(.once)
      .cancelReminder().called(.once)
  }

  @Test
  func permissionDeniedShowsClearStateAndDoesNotSchedule() async throws {
    let service = MockReminderService()
    given(service)
      .currentPermissionStatus().willReturn(.denied)
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.setEnabled(true)

    #expect(!viewModel.configuration.isEnabled)
    #expect(viewModel.permissionStatus == .denied)
    #expect(viewModel.errorMessage == ReminderServiceError.permissionDenied.localizedDescription)
    #expect(viewModel.shouldShowSettingsLink)
    verify(service)
      .requestPermission().called(.never)
      .scheduleReminder(configuration: .any).called(.never)
  }

  @Test
  func permissionDeniedAfterRequestDoesNotSchedule() async throws {
    let service = MockReminderService()
    given(service)
      .currentPermissionStatus().willReturn(.unknown)
      .currentPermissionStatus().willReturn(.denied)
      .requestPermission().willReturn()
    let viewModel = ReminderSettingsViewModel(
      reminderService: service,
      calendar: reminderTestCalendar
    )

    await viewModel.setEnabled(true)

    #expect(!viewModel.configuration.isEnabled)
    #expect(viewModel.permissionStatus == .denied)
    #expect(viewModel.errorMessage == ReminderServiceError.permissionDenied.localizedDescription)
    #expect(viewModel.shouldShowSettingsLink)
    verify(service)
      .requestPermission().called(.once)
      .scheduleReminder(configuration: .any).called(.never)
  }

  @Test
  func noteJournalEntryActionRoutesCoordinatorToRecording() async throws {
    let service = PreviewReminderService()
    let result = try await service.handleNotificationAction(
      identifier: NotificationActionIdentifier.noteJournalEntry
    )
    let actionStore = AppLaunchActionStore()
    let coordinator = AppCoordinator()

    if result == .startJournalEntry {
      actionStore.enqueue(.startJournalEntry)
    }

    let action = actionStore.consumePendingAction()
    #expect(action == .startJournalEntry)
    #expect(coordinator.startCaptureFromReminder())
    #expect(coordinator.path == [.capture(.recording)])
  }

  @Test
  func defaultNotificationActionRoutesCoordinatorToRecording() async throws {
    let service = PreviewReminderService()
    let result = try await service.handleNotificationAction(
      identifier: UNNotificationDefaultActionIdentifier
    )
    let coordinator = AppCoordinator()

    #expect(result == .startJournalEntry)
    #expect(coordinator.startCaptureFromReminder())
    #expect(coordinator.path == [.capture(.recording)])
  }

  @Test
  func remindLaterActionSchedulesSnooze() async throws {
    let service = PreviewReminderService()

    let result = try await service.handleNotificationAction(
      identifier: NotificationActionIdentifier.remindLater
    )

    #expect(result == .snoozed)
    #expect(await service.didScheduleRemindLater)
  }

  @Test
  func dismissActionDoesNothing() async throws {
    let service = PreviewReminderService()
    let coordinator = AppCoordinator()

    let result = try await service.handleNotificationAction(
      identifier: NotificationActionIdentifier.dismiss
    )

    #expect(result == .dismissed)
    #expect(coordinator.path.isEmpty)
    #expect(await service.didScheduleRemindLater == false)
  }

  @Test
  func systemDismissActionDoesNothing() async throws {
    let service = PreviewReminderService()
    let coordinator = AppCoordinator()

    let result = try await service.handleNotificationAction(
      identifier: UNNotificationDismissActionIdentifier
    )

    #expect(result == .dismissed)
    #expect(coordinator.path.isEmpty)
    #expect(await service.didScheduleRemindLater == false)
  }
}

private let reminderTestCalendar: Calendar = {
  var calendar = Calendar(identifier: .gregorian)
  calendar.timeZone = fixtureTimeZone(secondsFromGMT: 0)
  return calendar
}()
