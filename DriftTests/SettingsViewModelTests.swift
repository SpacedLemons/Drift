//
//  SettingsViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct SettingsViewModelTests {
  @Test
  func loadUsesDefaultLocalSettings() async throws {
    let viewModel = SettingsViewModel(
      journalRepository: MockJournalRepository(),
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService()
    )

    await viewModel.load()

    #expect(viewModel.voiceRecognitionValue == "On-device available")
    #expect(viewModel.entitlement == .free)
    #expect(!viewModel.isGuideDismissed)
    #expect(!viewModel.shouldShowSpeechSettingsLink)
  }

  @Test
  func loadReflectsDismissedGuideState() async throws {
    let guideService = PreviewGuideService(dismissed: true)
    let viewModel = SettingsViewModel(
      journalRepository: MockJournalRepository(),
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService(),
      guideService: guideService
    )

    await viewModel.load()

    #expect(viewModel.isGuideDismissed)
  }

  @Test
  func loadShowsSpeechPermissionAndFallbackState() async throws {
    let viewModel = SettingsViewModel(
      journalRepository: MockJournalRepository(),
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: false,
        permissionStatus: .denied
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService()
    )

    await viewModel.load()

    #expect(viewModel.voiceRecognitionValue == "Apple Speech fallback")
    #expect(viewModel.speechPermissionStatus == .denied)
    #expect(viewModel.speechPermissionStatusText == "Off")
    #expect(viewModel.shouldShowSpeechSettingsLink)
  }

  @Test
  func deleteAllEntriesRemovesEntriesFromRepository() async throws {
    let repository = PreviewJournalRepository(entries: PreviewData.journalEntries)
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService()
    )

    let didDelete = await viewModel.deleteAllEntries()
    let entries = try await repository.fetchEntries()

    #expect(didDelete)
    #expect(entries.isEmpty)
  }

  @Test
  func deleteAllEntriesFailureShowsUserFriendlyError() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries().willReturn([])
      .deleteAllEntries().willThrow(JournalRepositoryError.deleteFailed)
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService()
    )

    let didDelete = await viewModel.deleteAllEntries()

    #expect(!didDelete)
    #expect(viewModel.errorMessage == "We could not delete your entries. Please try again.")
    #expect(!viewModel.isDeletingAllEntries)
  }

  @Test
  func deleteAllEntriesIgnoresDuplicateCallsWhileDeleting() async throws {
    let repository = ControlledDeleteJournalRepository()
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: MockExportService()
    )

    let firstDeleteTask = Task { await viewModel.deleteAllEntries() }
    await repository.waitUntilDeleteStarted()
    let duplicateDelete = await viewModel.deleteAllEntries()
    await repository.finishDelete()
    let didDelete = await firstDeleteTask.value

    #expect(didDelete)
    #expect(!duplicateDelete)
    #expect(!viewModel.isDeletingAllEntries)
  }

  @Test
  func exportAllEntriesCreatesShareItem() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries().willReturn(PreviewData.journalEntries)
    let exportService = MockExportService()
    let exportURL = URL(fileURLWithPath: "/tmp/drift-export.md")
    let exportedAt = Date(timeIntervalSince1970: 1_778_600_000)
    given(exportService)
      .export(entries: .any, exportedAt: .any).willReturn(exportURL)
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: exportService,
      now: { exportedAt }
    )

    let fileURL = await viewModel.exportAllEntries()

    #expect(fileURL == exportURL)
    #expect(viewModel.exportShareItem?.url == exportURL)
    #expect(!viewModel.isExportingEntries)
    #expect(viewModel.errorMessage == nil)
    verify(repository)
      .fetchEntries().called(.once)
    verify(exportService)
      .export(entries: .any, exportedAt: .value(exportedAt)).called(.once)
  }

  @Test
  func exportAllEntriesFailureShowsUserFriendlyError() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries().willReturn(PreviewData.journalEntries)
    let exportService = MockExportService()
    given(exportService)
      .export(entries: .any, exportedAt: .any).willThrow(ExportServiceError.writeFailed)
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: exportService
    )

    let fileURL = await viewModel.exportAllEntries()

    #expect(fileURL == nil)
    #expect(viewModel.exportShareItem == nil)
    #expect(viewModel.errorMessage == "We could not create your export. Please try again.")
    #expect(!viewModel.isExportingEntries)
  }

  @Test
  func exportAllEntriesShowsEmptyMessageWhenThereAreNoEntries() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntries().willReturn([])
    let exportService = MockExportService()
    let viewModel = SettingsViewModel(
      journalRepository: repository,
      transcriptionService: SettingsTranscriptionServiceStub(
        supportsOnDeviceTranscription: true,
        permissionStatus: .unknown
      ),
      subscriptionService: DisabledSubscriptionService(),
      exportService: exportService
    )

    let fileURL = await viewModel.exportAllEntries()

    #expect(fileURL == nil)
    #expect(viewModel.exportShareItem == nil)
    #expect(viewModel.errorMessage == "There are no entries to export yet.")
    #expect(!viewModel.isExportingEntries)
    verify(exportService)
      .export(entries: .any, exportedAt: .any).called(.never)
  }
}

private struct SettingsTranscriptionServiceStub: TranscriptionService, Sendable {
  let supportsOnDeviceTranscription: Bool
  let permissionStatus: PermissionStatus

  func currentPermissionStatus() async -> PermissionStatus {
    permissionStatus
  }

  func requestPermission() async throws {}

  func transcribe(audioURL: URL) async throws -> String {
    throw TranscriptionError.transcriptionFailed
  }
}

private actor ControlledDeleteJournalRepository: JournalRepository {
  private var didStartDelete = false
  private var startedContinuation: CheckedContinuation<Void, Never>?
  private var finishContinuation: CheckedContinuation<Void, Never>?

  func waitUntilDeleteStarted() async {
    guard !didStartDelete else { return }

    await withCheckedContinuation { continuation in
      startedContinuation = continuation
    }
  }

  func finishDelete() {
    finishContinuation?.resume()
    finishContinuation = nil
  }

  func fetchEntries() async throws -> [JournalEntry] {
    []
  }

  func fetchEntry(id: UUID) async throws -> JournalEntry? {
    nil
  }

  func saveEntry(_ entry: JournalEntry) async throws {}

  func updateEntry(_ entry: JournalEntry) async throws {}

  func deleteEntry(id: UUID) async throws {}

  func deleteAllEntries() async throws {
    didStartDelete = true
    startedContinuation?.resume()
    startedContinuation = nil

    await withCheckedContinuation { continuation in
      finishContinuation = continuation
    }
  }

  func searchEntries(query: String) async throws -> [JournalEntry] {
    []
  }
}
