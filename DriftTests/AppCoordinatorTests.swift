//
//  AppCoordinatorTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Testing

@testable import Drift

@MainActor
struct AppCoordinatorTests {
  @Test
  func editEntryRouteReturnsToEntryDetail() {
    let entryID = UUID()
    let coordinator = AppCoordinator()

    coordinator.showJournalEntry(entryID)
    coordinator.editJournalEntry(entryID)

    #expect(coordinator.path == [.journalEntry(entryID), .editJournalEntry(entryID)])

    coordinator.backToEntryDetail(entryID)

    #expect(coordinator.path == [.journalEntry(entryID)])
  }

  @Test
  func deleteEntryRouteReturnsToJournal() {
    let coordinator = AppCoordinator()

    coordinator.showJournalEntry(UUID())
    coordinator.backToJournal()

    #expect(coordinator.path.isEmpty)
  }

  @Test
  func recordingFlowRoutesThroughProcessingReviewAndSaved() {
    let coordinator = AppCoordinator()
    let recordingResult = RecordingResult(
      audioURL: URL(fileURLWithPath: "/tmp/drift-navigation-test.m4a"),
      duration: 12,
      finishedAt: Date(timeIntervalSince1970: 1_778_600_000)
    )
    let draft = ReviewEntryDraft(
      id: fixtureUUID("D0000000-0000-0000-0000-000000000001"),
      audioURL: recordingResult.audioURL,
      duration: recordingResult.duration,
      createdAt: recordingResult.finishedAt,
      transcript: "Navigation test transcript.",
      suggestedMood: .neutral,
      suggestedThemes: [],
      tags: []
    )
    let entry = JournalEntry(
      id: draft.id,
      createdAt: draft.createdAt,
      transcript: draft.transcript
    )

    coordinator.startCapture()
    #expect(coordinator.path == [.capture(.recording)])

    coordinator.showProcessing(recordingResult)
    #expect(coordinator.path == [.capture(.recording), .capture(.processing(recordingResult))])

    coordinator.showReview(draft)
    #expect(
      coordinator.path == [
        .capture(.recording),
        .capture(.processing(recordingResult)),
        .capture(.review(draft)),
      ]
    )

    coordinator.showSaved(entry)
    #expect(coordinator.path == [.capture(.saved(entry))])

    coordinator.viewSavedEntry(entry)
    #expect(coordinator.path == [.journalEntry(entry.id)])
  }

  @Test
  func cancelRecordingReturnsToJournal() {
    let coordinator = AppCoordinator()

    coordinator.startCapture()
    coordinator.backToJournal()

    #expect(coordinator.path.isEmpty)
  }

  @Test
  func notificationActionStartsRecordingFlow() {
    let coordinator = AppCoordinator()

    #expect(coordinator.startCaptureFromReminder())
    #expect(coordinator.path == [.capture(.recording)])
  }

  @Test
  func fullScreenPaywallRouteAppearsForLimitUpgradePrompt() {
    let coordinator = AppCoordinator()
    let message =
      "You've used today's 10 free entries. Come back tomorrow or upgrade for more daily entries."

    coordinator.showDriftPlusPaywall(reasonMessage: message)

    #expect(coordinator.fullScreenRoute == .driftPlus)
    #expect(coordinator.paywallReasonMessage == message)
  }
}

@MainActor
struct SettingsCoordinatorTests {
  @Test
  func settingsRoutesArePushed() {
    let coordinator = SettingsCoordinator()

    coordinator.showReminders()
    coordinator.showAppearance()

    #expect(coordinator.path == [.reminders, .appearance])
  }
}
