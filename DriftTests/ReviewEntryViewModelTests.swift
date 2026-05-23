//
//  ReviewEntryViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct ReviewEntryViewModelTests {
  @Test
  func initialisesFromDraft() {
    let draft = makeDraft()
    let viewModel = ReviewEntryViewModel(
      draft: draft,
      journalRepository: MockJournalRepository()
    )

    #expect(viewModel.transcript == draft.transcript)
    #expect(viewModel.selectedDriftType == .reflection)
    #expect(viewModel.selectedMood == draft.suggestedMood)
    #expect(viewModel.selectedThemes == draft.suggestedThemes)
    #expect(viewModel.tags == draft.tags)
  }

  @Test
  func saveValidatesNonEmptyTranscript() async throws {
    let repository = MockJournalRepository()
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(transcript: "Original"),
      journalRepository: repository
    )

    viewModel.transcript = "   "

    let entry = await viewModel.save()

    #expect(entry == nil)
    #expect(viewModel.errorMessage == "Add a transcript before saving.")
    verify(repository)
      .saveEntry(.any).called(.never)
  }

  @Test
  func updatesMoodThemesAndTagsBeforeSaving() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .saveEntry(.any)
      .willReturn()
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository
    )

    viewModel.transcript = "  Updated transcript for saving.  "
    viewModel.selectMood(.reflective)
    viewModel.toggleTheme(.work)
    viewModel.toggleTheme(.growth)
    viewModel.pendingTag = "updated"
    viewModel.addPendingTag()
    viewModel.removeTag("focus")

    let entry = await viewModel.save()

    #expect(entry?.transcript == "Updated transcript for saving.")
    #expect(entry?.mood == .reflective)
    #expect(entry?.driftType == .reflection)
    #expect(entry?.themes == [.growth])
    #expect(entry?.tags == ["updated"])
    verify(repository)
      .saveEntry(.any).called(.once)
  }

  @Test
  func savesSelectedDriftType() async throws {
    let repository = PreviewJournalRepository(entries: [])
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository
    )

    viewModel.selectDriftType(.goal)
    let entry = await viewModel.save()
    let savedEntry = try await repository.fetchEntry(id: makeDraft().id)

    #expect(entry?.driftType == .goal)
    #expect(savedEntry?.driftType == .goal)
    #expect(savedEntry?.aiVisibility == .privateLocalOnly)
    #expect(savedEntry?.driftStatus == .active)
  }

  @Test
  func addImageInputsSavesAttachmentMetadataOnEntry() async throws {
    let repository = PreviewJournalRepository(entries: [])
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository,
      imageAttachmentService: PreviewImageAttachmentService()
    )

    await viewModel.addImageInputs([
      ImageAttachmentInput(data: Data("image".utf8), originalFileName: "image.jpg")
    ])
    let entry = await viewModel.save()

    #expect(entry?.imageAttachments.count == 1)
    #expect(entry?.imageAttachments.first?.originalFileName == "image.jpg")
  }

  @Test
  func customThemeCanBeCreatedSelectedAndSaved() async throws {
    let repository = PreviewJournalRepository(entries: [])
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository,
      customThemeService: PreviewCustomThemeService(themes: [])
    )

    viewModel.pendingCustomThemeName = "Side project"
    await viewModel.createCustomTheme()
    let entry = await viewModel.save()

    #expect(viewModel.availableCustomThemes.map(\.displayName) == ["Side project"])
    #expect(entry?.customThemes.map(\.displayName) == ["Side project"])
  }

  @Test
  func playbackLoadsAndTogglesTemporaryRecording() async throws {
    let audioURL = try makeTemporaryAudioFile()
    defer { try? FileManager.default.removeItem(at: audioURL) }
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(audioURL: audioURL),
      journalRepository: PreviewJournalRepository(entries: []),
      audioPlaybackService: PreviewAudioPlaybackService(duration: 42)
    )

    await viewModel.loadPlayback()

    #expect(viewModel.shouldShowPlaybackControls)
    #expect(viewModel.playbackDuration == 42)

    await viewModel.togglePlayback()
    #expect(viewModel.isPlayingAudio)

    await viewModel.togglePlayback()
    #expect(!viewModel.isPlayingAudio)
  }

  @Test
  func saveDeletesTemporaryAudioAfterEntryIsSaved() async throws {
    let audioURL = try makeTemporaryAudioFile()
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(audioURL: audioURL),
      journalRepository: PreviewJournalRepository(entries: []),
      audioPlaybackService: PreviewAudioPlaybackService(duration: 42)
    )

    let entry = await viewModel.save()

    #expect(entry != nil)
    #expect(!FileManager.default.fileExists(atPath: audioURL.path))
  }

  @Test
  func saveFailureShowsUserFriendlyError() async throws {
    let repository = MockJournalRepository()
    given(repository)
      .saveEntry(.any)
      .willThrow(JournalRepositoryError.saveFailed)
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository
    )

    let entry = await viewModel.save()

    #expect(entry == nil)
    #expect(viewModel.errorMessage == "We could not save this Drift. Please try again.")
    #expect(!viewModel.isSaving)
  }

  @Test
  func saveBlocksManualFallbackWhenDailyEntryLimitIsReached() async throws {
    let repository = MockJournalRepository()
    let limitService = DailyEntryLimitServiceStub(
      result: .blocked(
        entitlement: .free,
        entriesCreatedToday: SubscriptionTier.free.dailyEntryLimit
      )
    )
    let viewModel = ReviewEntryViewModel(
      draft: makeDraft(),
      journalRepository: repository,
      dailyEntryLimitService: limitService
    )

    let entry = await viewModel.save()

    #expect(entry == nil)
    #expect(
      viewModel.errorMessage
        == "You've used today's 10 free Drifts. Come back tomorrow or upgrade for more daily Drifts."
    )
    verify(repository)
      .saveEntry(.any).called(.never)
  }

  private func makeDraft(
    audioURL: URL = URL(fileURLWithPath: "/tmp/drift-review-test.m4a"),
    transcript: String = "A focused voice entry.",
    suggestedMood: Mood = .positive,
    suggestedThemes: [JournalTheme] = [.work],
    tags: [String] = ["focus"]
  ) -> ReviewEntryDraft {
    ReviewEntryDraft(
      id: fixtureUUID("B0000000-0000-0000-0000-000000000001"),
      audioURL: audioURL,
      duration: 42,
      createdAt: Date(timeIntervalSince1970: 1_778_600_000),
      transcript: transcript,
      suggestedMood: suggestedMood,
      suggestedThemes: suggestedThemes,
      tags: tags
    )
  }

  private func makeTemporaryAudioFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("drift-review-test-\(UUID().uuidString)")
      .appendingPathExtension("m4a")
    try Data("audio".utf8).write(to: url)
    return url
  }
}
