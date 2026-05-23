//
//  SettingsViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
  @ObservationIgnored
  private let journalRepository: any JournalRepository & Sendable
  @ObservationIgnored
  private let subscriptionService: any SubscriptionService & Sendable
  @ObservationIgnored
  private let exportService: any ExportService & Sendable
  @ObservationIgnored
  private let imageAttachmentService: any ImageAttachmentService & Sendable
  #if DEBUG
    @ObservationIgnored
    private let debugEntitlementOverrideStore = DebugEntitlementOverrideStore()
  #endif
  @ObservationIgnored
  private let now: () -> Date

  let exportPrivacyMessage =
    "Exports are created locally. You choose where to save or share them."
  let emptyExportMessage = "There are no entries to export yet."

  private(set) var entitlement: SubscriptionEntitlement = .free
  #if DEBUG
    private(set) var debugEntitlementSettings: DebugEntitlementOverrideSettings = .default
  #endif
  private(set) var isDeletingAllEntries = false
  private(set) var isExportingEntries = false
  private(set) var errorMessage: String?
  var exportShareItem: ExportShareItem?

  var navigationRows: [SettingsNavigationRowDescriptor] {
    [
      SettingsNavigationRowDescriptor(
        route: .reminders,
        icon: AppIcons.bell,
        title: "Reminder Settings",
        subtitle: "Local journal nudges",
        trailingValue: "Local"
      ),
      SettingsNavigationRowDescriptor(
        route: .voiceTranscription,
        icon: AppIcons.waveform,
        title: "Voice & Transcription",
        subtitle: "Recording, transcription, and audio options",
        trailingValue: nil
      ),
      SettingsNavigationRowDescriptor(
        route: .appearance,
        icon: AppIcons.paintPalette,
        title: "Appearance",
        subtitle: "Mode, accent colour, and layout density",
        trailingValue: nil
      ),
      SettingsNavigationRowDescriptor(
        route: .backupRestore,
        icon: AppIcons.externalDrive,
        title: "Backup & Restore",
        subtitle: "iCloud backup, restore, and transfer options",
        trailingValue: nil
      ),
      SettingsNavigationRowDescriptor(
        route: .privacy,
        icon: AppIcons.lockShield,
        title: "Privacy",
        subtitle: "Device storage, transcription, and future AI",
        trailingValue: nil
      ),
      SettingsNavigationRowDescriptor(
        route: .about,
        icon: AppIcons.info,
        title: "About Drift",
        subtitle: "Version, privacy notes, and support",
        trailingValue: nil
      ),
    ]
  }

  func navigationRow(for route: SettingsRoute) -> SettingsNavigationRowDescriptor {
    navigationRows.first { $0.route == route }
      ?? SettingsNavigationRowDescriptor(
        route: route,
        icon: AppIcons.settings,
        title: "Settings",
        subtitle: nil,
        trailingValue: nil
      )
  }

  init(
    journalRepository: any JournalRepository & Sendable,
    subscriptionService: any SubscriptionService & Sendable,
    exportService: any ExportService & Sendable,
    imageAttachmentService: any ImageAttachmentService & Sendable = PreviewImageAttachmentService(),
    now: @escaping () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.subscriptionService = subscriptionService
    self.exportService = exportService
    self.imageAttachmentService = imageAttachmentService
    self.now = now
  }

  func load() async {
    #if DEBUG
      debugEntitlementSettings = await debugEntitlementOverrideStore.loadSettings()
    #endif

    do {
      entitlement = try await subscriptionService.currentEntitlement()
    } catch {
      entitlement = .free
    }
  }

  func deleteAllEntries() async -> Bool {
    guard !isDeletingAllEntries else { return false }

    isDeletingAllEntries = true
    errorMessage = nil
    defer { isDeletingAllEntries = false }

    do {
      let entries = try await journalRepository.fetchEntries()
      try await journalRepository.deleteAllEntries()
      await imageAttachmentService.deleteAttachments(entries.flatMap(\.imageAttachments))
      return true
    } catch {
      errorMessage = "We could not delete your entries. Please try again."
      return false
    }
  }

  func exportAllEntries() async -> URL? {
    guard !isExportingEntries else { return nil }

    isExportingEntries = true
    errorMessage = nil
    exportShareItem = nil
    defer { isExportingEntries = false }

    do {
      let entries = try await journalRepository.fetchEntries()
      guard !entries.isEmpty else {
        errorMessage = emptyExportMessage
        return nil
      }

      let fileURL = try await exportService.export(
        entries: entries,
        exportedAt: now()
      )
      exportShareItem = ExportShareItem(url: fileURL)
      return fileURL
    } catch let error as ExportServiceError {
      errorMessage = error.localizedDescription
      return nil
    } catch {
      errorMessage = "We could not create your export. Please try again."
      return nil
    }
  }

  func clearError() {
    errorMessage = nil
  }

  #if DEBUG
    func setDebugEntitlementMode(_ mode: DebugEntitlementMode) async {
      await debugEntitlementOverrideStore.saveMode(mode)
      await load()
    }

    func setSimulateFreeEntryLimitReached(_ isEnabled: Bool) async {
      await debugEntitlementOverrideStore.saveSimulateFreeEntryLimitReached(isEnabled)
      await load()
    }

    func setSimulatePlusEntryLimitReached(_ isEnabled: Bool) async {
      await debugEntitlementOverrideStore.saveSimulatePlusEntryLimitReached(isEnabled)
      await load()
    }
  #endif
}

struct SettingsNavigationRowDescriptor: Identifiable, Equatable, Sendable {
  let route: SettingsRoute
  let icon: String
  let title: String
  let subtitle: String?
  let trailingValue: String?

  var id: SettingsRoute { route }
}
