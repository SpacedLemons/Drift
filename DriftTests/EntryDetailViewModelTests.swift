//
//  EntryDetailViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct EntryDetailViewModelTests {
  @Test
  func loadPopulatesEntry() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()

    #expect(viewModel.entry?.id == entry.id)
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func loadHandlesMissingEntry() async throws {
    let missingID = UUID()
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntry(id: .value(missingID))
      .willReturn(Optional<JournalEntry>.none)
    let viewModel = EntryDetailViewModel(
      entryID: missingID,
      journalRepository: repository
    )

    await viewModel.load()

    #expect(viewModel.entry == nil)
    #expect(viewModel.errorMessage == "We could not find this Drift.")
  }

  @Test
  func saveChangesUpdatesRepository() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()
    viewModel.beginEditing()
    viewModel.editedTitle = "Updated title"
    viewModel.editedTranscript = "Updated transcript with enough detail."
    viewModel.editedMood = .reflective
    viewModel.editedThemes = [.growth]
    viewModel.editedCustomThemes = [
      CustomJournalTheme(name: "Side project", createdAt: entry.createdAt)
    ]
    viewModel.editedTags = ["updated"]
    viewModel.editedImageAttachments = [
      JournalImageAttachment(localFileName: "updated.jpg", createdAt: entry.createdAt)
    ]

    let didSave = await viewModel.saveChanges()
    let updatedEntry = try await repository.fetchEntry(id: entry.id)

    #expect(didSave)
    #expect(updatedEntry?.title == "Updated title")
    #expect(updatedEntry?.transcript == "Updated transcript with enough detail.")
    #expect(updatedEntry?.mood == .reflective)
    #expect(updatedEntry?.themes == [.growth])
    #expect(updatedEntry?.customThemes.map(\.displayName) == ["Side project"])
    #expect(updatedEntry?.tags == ["updated"])
    #expect(updatedEntry?.imageAttachments.map(\.localFileName) == ["updated.jpg"])
  }

  @Test
  func hasUnsavedChangesReflectsEditedDraftState() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()
    viewModel.beginEditing()
    #expect(!viewModel.hasUnsavedChanges)

    viewModel.editedTranscript = "\(entry.transcript) More detail."
    #expect(viewModel.hasUnsavedChanges)

    viewModel.cancelEditing()
    #expect(!viewModel.hasUnsavedChanges)
  }

  @Test
  func saveChangesValidatesNonEmptyTranscript() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()
    viewModel.beginEditing()
    viewModel.editedTranscript = "   "

    let didSave = await viewModel.saveChanges()

    #expect(!didSave)
    #expect(viewModel.errorMessage == "A Drift needs some text before it can be saved.")
  }

  @Test
  func saveFailureShowsUserFriendlyError() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntry(id: .value(entry.id))
      .willReturn(entry)
    given(repository)
      .updateEntry(.any)
      .willThrow(JournalRepositoryError.updateFailed)
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()
    viewModel.beginEditing()
    viewModel.editedTranscript = "Updated transcript"
    let didSave = await viewModel.saveChanges()

    #expect(!didSave)
    #expect(viewModel.errorMessage == "We could not save your Drift changes. Please try again.")
    #expect(!viewModel.isSaving)
  }

  @Test
  func deleteRemovesEntryFromRepository() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()

    let didDelete = await viewModel.deleteEntry()
    let deletedEntry = try await repository.fetchEntry(id: entry.id)

    #expect(didDelete)
    #expect(deletedEntry == nil)
  }

  @Test
  func deleteFailureShowsUserFriendlyError() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = MockJournalRepository()
    given(repository)
      .fetchEntry(id: .value(entry.id))
      .willReturn(entry)
    given(repository)
      .deleteEntry(id: .value(entry.id))
      .willThrow(JournalRepositoryError.deleteFailed)
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()

    let didDelete = await viewModel.deleteEntry()

    #expect(!didDelete)
    #expect(viewModel.errorMessage == "We could not delete this Drift. Please try again.")
    #expect(!viewModel.isDeleting)
  }

  @Test
  func togglesFavorite() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository
    )

    await viewModel.load()

    let didToggle = await viewModel.toggleFavorite()
    let updatedEntry = try await repository.fetchEntry(id: entry.id)

    #expect(didToggle)
    #expect(viewModel.entry?.isFavorite == !entry.isFavorite)
    #expect(updatedEntry?.isFavorite == !entry.isFavorite)
  }

  @Test
  func createsAndSelectsCustomThemeWhileEditing() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository,
      customThemeService: PreviewCustomThemeService(themes: [])
    )

    await viewModel.load()
    viewModel.beginEditing()
    viewModel.pendingCustomThemeName = "Home"
    await viewModel.createCustomTheme()

    #expect(viewModel.availableCustomThemes.map(\.displayName) == ["Home"])
    #expect(viewModel.editedCustomThemes.map(\.displayName).contains("Home"))
  }

  @Test
  func imageInputsCanBeAddedWhileEditing() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    let viewModel = EntryDetailViewModel(
      entryID: entry.id,
      journalRepository: repository,
      imageAttachmentService: PreviewImageAttachmentService()
    )

    await viewModel.load()
    viewModel.beginEditing()
    await viewModel.addImageInputs([
      ImageAttachmentInput(data: Data("image".utf8), originalFileName: "edit.jpg")
    ])

    #expect(viewModel.editedImageAttachments.last?.originalFileName == "edit.jpg")
    #expect(viewModel.hasUnsavedChanges)
  }

  @Test
  func searchReflectsUpdateAndDelete() async throws {
    let entry = PreviewData.journalEntries[0]
    let repository = PreviewJournalRepository(entries: [entry])
    var updatedEntry = entry
    updatedEntry.transcript = "A unique searchable phrase"

    try await repository.updateEntry(updatedEntry)
    let updatedResults = try await repository.searchEntries(query: "unique searchable")

    try await repository.deleteEntry(id: entry.id)
    let deletedResults = try await repository.searchEntries(query: "unique searchable")

    #expect(updatedResults.map(\.id) == [entry.id])
    #expect(deletedResults.isEmpty)
  }
}
