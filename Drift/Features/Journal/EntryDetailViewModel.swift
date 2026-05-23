//
//  EntryDetailViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class EntryDetailViewModel {
  @ObservationIgnored
  private let journalRepository: any JournalRepository
  @ObservationIgnored
  let imageAttachmentService: any ImageAttachmentService
  @ObservationIgnored
  private let customThemeService: any CustomThemeService

  let entryID: UUID

  private(set) var entry: JournalEntry?
  private(set) var isLoading = false
  private(set) var isSaving = false
  private(set) var isDeleting = false
  private(set) var errorMessage: String?

  var isEditing = false
  var editedTitle = ""
  var editedTranscript = ""
  var editedMood: Mood = .neutral
  var editedDriftType: DriftType = .reflection
  var editedThemes: [JournalTheme] = []
  var editedCustomThemes: [CustomJournalTheme] = []
  var availableCustomThemes: [CustomJournalTheme] = []
  var editedTags: [String] = []
  var editedImageAttachments: [JournalImageAttachment] = []
  var pendingTag = ""
  var pendingCustomThemeName = ""

  private var addedImageAttachments: [JournalImageAttachment] = []
  private var removedImageAttachments: [JournalImageAttachment] = []
  private(set) var isProcessingImages = false

  init(
    entryID: UUID,
    journalRepository: any JournalRepository,
    imageAttachmentService: any ImageAttachmentService = PreviewImageAttachmentService(),
    customThemeService: any CustomThemeService = PreviewCustomThemeService()
  ) {
    self.entryID = entryID
    self.journalRepository = journalRepository
    self.imageAttachmentService = imageAttachmentService
    self.customThemeService = customThemeService
  }

  var durationText: String? {
    guard let duration = entry?.duration else { return nil }
    let totalSeconds = max(Int(duration), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return "\(minutes)m \(seconds)s"
  }

  var hasUnsavedChanges: Bool {
    guard let entry else { return false }

    return editedTitle.trimmingCharacters(in: .whitespacesAndNewlines) != (entry.title ?? "")
      || editedTranscript.trimmingCharacters(in: .whitespacesAndNewlines) != entry.transcript
      || editedMood != (entry.mood ?? .neutral)
      || editedDriftType != entry.driftType
      || editedThemes != entry.themes
      || editedCustomThemes != entry.customThemes
      || editedTags != entry.tags
      || editedImageAttachments != entry.imageAttachments
      || !pendingTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      || !pendingCustomThemeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func load() async {
    isLoading = true
    errorMessage = nil

    do {
      guard let loadedEntry = try await journalRepository.fetchEntry(id: entryID) else {
        entry = nil
        errorMessage = "We could not find this Drift."
        isLoading = false
        return
      }

      entry = loadedEntry
      if !isEditing {
        seedEditState(from: loadedEntry)
      }
    } catch {
      errorMessage = "We could not find this Drift."
    }

    isLoading = false
  }

  func loadCustomThemes() async {
    do {
      availableCustomThemes = try await customThemeService.loadCustomThemes()
    } catch {
      errorMessage = "We could not load your custom themes."
    }
  }

  func beginEditing() {
    guard let entry else { return }
    seedEditState(from: entry)
    isEditing = true
    errorMessage = nil
  }

  func cancelEditing() {
    let unsavedAttachments = addedImageAttachments
    if let entry {
      seedEditState(from: entry)
    }
    addedImageAttachments = []
    removedImageAttachments = []
    isEditing = false
    errorMessage = nil

    Task {
      await imageAttachmentService.deleteAttachments(unsavedAttachments)
    }
  }

  func saveChanges() async -> Bool {
    guard let entry else {
      errorMessage = "We could not find this Drift."
      return false
    }

    let transcript = editedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !transcript.isEmpty else {
      errorMessage = "A Drift needs some text before it can be saved."
      return false
    }

    isSaving = true
    errorMessage = nil

    let title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    let updatedEntry = JournalEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: Date(),
      transcript: transcript,
      title: title.isEmpty ? nil : title,
      mood: editedMood,
      moodConfidence: entry.moodConfidence,
      themes: editedThemes,
      customThemes: editedCustomThemes,
      tags: editedTags,
      duration: entry.duration,
      source: entry.source,
      isFavorite: entry.isFavorite,
      imageAttachments: editedImageAttachments,
      driftType: editedDriftType,
      aiVisibility: entry.aiVisibility,
      driftStatus: entry.driftStatus
    )

    do {
      try await journalRepository.updateEntry(updatedEntry)
      await imageAttachmentService.deleteAttachments(removedImageAttachments)
      self.entry = updatedEntry
      isEditing = false
      isSaving = false
      addedImageAttachments = []
      removedImageAttachments = []
      return true
    } catch {
      isSaving = false
      errorMessage = "We could not save your Drift changes. Please try again."
      return false
    }
  }

  func deleteEntry() async -> Bool {
    guard !isDeleting else { return false }

    isDeleting = true
    errorMessage = nil
    defer { isDeleting = false }

    do {
      let attachments = entry?.imageAttachments ?? []
      try await journalRepository.deleteEntry(id: entryID)
      await imageAttachmentService.deleteAttachments(attachments)
      return true
    } catch {
      errorMessage = "We could not delete this Drift. Please try again."
      return false
    }
  }

  func toggleFavorite() async -> Bool {
    guard let entry else { return false }

    let updatedEntry = JournalEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: Date(),
      transcript: entry.transcript,
      title: entry.title,
      mood: entry.mood,
      moodConfidence: entry.moodConfidence,
      themes: entry.themes,
      customThemes: entry.customThemes,
      tags: entry.tags,
      duration: entry.duration,
      source: entry.source,
      isFavorite: !entry.isFavorite,
      imageAttachments: entry.imageAttachments,
      driftType: entry.driftType,
      aiVisibility: entry.aiVisibility,
      driftStatus: entry.driftStatus
    )

    do {
      try await journalRepository.updateEntry(updatedEntry)
      self.entry = updatedEntry
      return true
    } catch {
      errorMessage = "We could not save your Drift changes. Please try again."
      return false
    }
  }

  func toggleTheme(_ theme: JournalTheme) {
    if editedThemes.contains(theme) {
      editedThemes.removeAll { $0 == theme }
    } else {
      editedThemes.append(theme)
    }
  }

  func toggleCustomTheme(_ theme: CustomJournalTheme) {
    if editedCustomThemes.contains(theme) {
      editedCustomThemes.removeAll { $0 == theme }
    } else {
      editedCustomThemes.append(theme)
    }
  }

  func createCustomTheme() async {
    let name = pendingCustomThemeName

    do {
      let theme = try await customThemeService.createCustomTheme(named: name)
      availableCustomThemes.append(theme)
      editedCustomThemes.append(theme)
      pendingCustomThemeName = ""
      errorMessage = nil
    } catch let error as CustomThemeServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "We could not save your custom theme. Please try again."
    }
  }

  func deleteCustomTheme(_ theme: CustomJournalTheme) async {
    do {
      try await customThemeService.deleteCustomTheme(id: theme.id)
      availableCustomThemes.removeAll { $0.id == theme.id }
      editedCustomThemes.removeAll { $0.id == theme.id }
    } catch {
      errorMessage = "We could not delete that custom theme. Please try again."
    }
  }

  func addImageInputs(_ inputs: [ImageAttachmentInput]) async {
    guard !inputs.isEmpty else { return }

    isProcessingImages = true
    errorMessage = nil
    defer { isProcessingImages = false }

    do {
      for input in inputs {
        let attachment = try await imageAttachmentService.saveImageAttachment(input)
        editedImageAttachments.append(attachment)
        addedImageAttachments.append(attachment)
      }
    } catch let error as ImageAttachmentServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "We could not save that image on this device. Please try again."
    }
  }

  func removeImageAttachment(_ attachment: JournalImageAttachment) async {
    editedImageAttachments.removeAll { $0.id == attachment.id }

    if addedImageAttachments.contains(where: { $0.id == attachment.id }) {
      addedImageAttachments.removeAll { $0.id == attachment.id }
      await imageAttachmentService.deleteAttachment(attachment)
    } else if !removedImageAttachments.contains(where: { $0.id == attachment.id }) {
      removedImageAttachments.append(attachment)
    }
  }

  func addPendingTag() {
    let tag = pendingTag.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tag.isEmpty else { return }
    guard !editedTags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else {
      pendingTag = ""
      return
    }

    editedTags.append(tag)
    pendingTag = ""
  }

  func removeTag(_ tag: String) {
    editedTags.removeAll { $0 == tag }
  }

  private func seedEditState(from entry: JournalEntry) {
    editedTitle = entry.title ?? ""
    editedTranscript = entry.transcript
    editedMood = entry.mood ?? .neutral
    editedDriftType = entry.driftType
    editedThemes = entry.themes
    editedCustomThemes = entry.customThemes
    editedTags = entry.tags
    editedImageAttachments = entry.imageAttachments
    pendingTag = ""
    pendingCustomThemeName = ""
  }
}
