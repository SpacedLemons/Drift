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
  private let transcriptionService: any TranscriptionService & Sendable
  @ObservationIgnored
  private let subscriptionService: any SubscriptionService & Sendable
  @ObservationIgnored
  private let exportService: any ExportService & Sendable
  @ObservationIgnored
  private let imageAttachmentService: any ImageAttachmentService & Sendable
  @ObservationIgnored
  let guideService: any GuideService & Sendable
  @ObservationIgnored
  private let now: () -> Date

  let exportPrivacyMessage =
    "Exports are created locally. You choose where to save or share them."
  let emptyExportMessage = "There are no entries to export yet."

  private(set) var voiceRecognitionValue = "Checking"
  private(set) var speechPermissionStatus: PermissionStatus = .unknown
  private(set) var entitlement: SubscriptionEntitlement = .free
  private(set) var isDeletingAllEntries = false
  private(set) var isExportingEntries = false
  private(set) var isGuideDismissed = false
  private(set) var errorMessage: String?
  var exportShareItem: ExportShareItem?

  var speechPermissionStatusText: String {
    switch speechPermissionStatus {
    case .unknown: "Not requested"
    case .granted: "Allowed"
    case .denied: "Off"
    case .restricted: "Restricted"
    }
  }

  var shouldShowSpeechSettingsLink: Bool {
    speechPermissionStatus == .denied
  }

  init(
    journalRepository: any JournalRepository & Sendable,
    transcriptionService: any TranscriptionService & Sendable,
    subscriptionService: any SubscriptionService & Sendable,
    exportService: any ExportService & Sendable,
    imageAttachmentService: any ImageAttachmentService & Sendable = PreviewImageAttachmentService(),
    guideService: any GuideService & Sendable = PreviewGuideService(),
    now: @escaping () -> Date = Date.init
  ) {
    self.journalRepository = journalRepository
    self.transcriptionService = transcriptionService
    self.subscriptionService = subscriptionService
    self.exportService = exportService
    self.imageAttachmentService = imageAttachmentService
    self.guideService = guideService
    self.now = now
  }

  func load() async {
    voiceRecognitionValue =
      transcriptionService.supportsOnDeviceTranscription
      ? "On-device available"
      : "Apple Speech fallback"
    speechPermissionStatus = await transcriptionService.currentPermissionStatus()
    isGuideDismissed = await guideService.isGuideDismissed()

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
}
