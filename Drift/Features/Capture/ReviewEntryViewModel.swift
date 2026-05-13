//
//  ReviewEntryViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReviewEntryViewModel {
  @ObservationIgnored
  private let draft: ReviewEntryDraft
  @ObservationIgnored
  private let journalRepository: any JournalRepository
  @ObservationIgnored
  private let audioPlaybackService: any AudioPlaybackService
  @ObservationIgnored
  let imageAttachmentService: any ImageAttachmentService
  @ObservationIgnored
  private let customThemeService: any CustomThemeService
  @ObservationIgnored
  private let fileManager: FileManager
  @ObservationIgnored
  private var playbackTimerTask: Task<Void, Never>?

  var transcript: String
  var selectedMood: Mood
  var selectedThemes: [JournalTheme]
  var selectedCustomThemes: [CustomJournalTheme]
  var availableCustomThemes: [CustomJournalTheme] = []
  var tags: [String]
  var pendingTag = ""
  var pendingCustomThemeName = ""
  var imageAttachments: [JournalImageAttachment] = []

  private(set) var isSaving = false
  private(set) var isLoadingCustomThemes = false
  private(set) var isProcessingImages = false
  private(set) var isPlaybackAvailable = false
  private(set) var isPlayingAudio = false
  private(set) var playbackDuration: TimeInterval = 0
  private(set) var playbackCurrentTime: TimeInterval = 0
  private(set) var playbackErrorMessage: String?
  private(set) var errorMessage: String?

  init(
    draft: ReviewEntryDraft,
    journalRepository: any JournalRepository,
    audioPlaybackService: any AudioPlaybackService = PreviewAudioPlaybackService(),
    imageAttachmentService: any ImageAttachmentService = PreviewImageAttachmentService(),
    customThemeService: any CustomThemeService = PreviewCustomThemeService(),
    fileManager: FileManager = .default
  ) {
    self.draft = draft
    self.journalRepository = journalRepository
    self.audioPlaybackService = audioPlaybackService
    self.imageAttachmentService = imageAttachmentService
    self.customThemeService = customThemeService
    self.fileManager = fileManager
    transcript = draft.transcript
    selectedMood = draft.suggestedMood
    selectedThemes = draft.suggestedThemes
    selectedCustomThemes = []
    tags = draft.tags
  }

  deinit {
    playbackTimerTask?.cancel()
  }

  var shouldShowPlaybackControls: Bool {
    isPlaybackAvailable
  }

  var playbackProgress: Double {
    guard playbackDuration > 0 else { return 0 }
    return min(max(playbackCurrentTime / playbackDuration, 0), 1)
  }

  var playbackTimeText: String {
    "\(formatPlaybackTime(playbackCurrentTime)) / \(formatPlaybackTime(playbackDuration))"
  }

  var playbackButtonIcon: String {
    isPlayingAudio ? AppIcons.pause : AppIcons.play
  }

  var playbackButtonTitle: String {
    isPlayingAudio ? "Pause" : "Play"
  }

  func selectMood(_ mood: Mood) {
    selectedMood = mood
  }

  func toggleTheme(_ theme: JournalTheme) {
    if selectedThemes.contains(theme) {
      selectedThemes.removeAll { $0 == theme }
    } else {
      selectedThemes.append(theme)
    }
  }

  func loadCustomThemes() async {
    guard !isLoadingCustomThemes else { return }

    isLoadingCustomThemes = true
    defer { isLoadingCustomThemes = false }

    do {
      availableCustomThemes = try await customThemeService.loadCustomThemes()
    } catch {
      errorMessage = "We could not load your custom themes."
    }
  }

  func loadPlayback() async {
    guard fileManager.fileExists(atPath: draft.audioURL.path) else {
      isPlaybackAvailable = false
      return
    }

    do {
      let metadata = try await audioPlaybackService.prepare(url: draft.audioURL)
      playbackDuration = metadata.duration
      playbackCurrentTime = 0
      isPlaybackAvailable = metadata.duration > 0
      playbackErrorMessage = nil
    } catch let error as AudioPlaybackError {
      isPlaybackAvailable = false
      playbackErrorMessage = error.localizedDescription
    } catch {
      isPlaybackAvailable = false
      playbackErrorMessage = "We could not prepare this recording for playback."
    }
  }

  func togglePlayback() async {
    guard isPlaybackAvailable else { return }

    do {
      if isPlayingAudio {
        await audioPlaybackService.pause()
        isPlayingAudio = false
        stopPlaybackTimer()
      } else {
        try await audioPlaybackService.play()
        isPlayingAudio = true
        playbackErrorMessage = nil
        startPlaybackTimer()
      }
    } catch let error as AudioPlaybackError {
      playbackErrorMessage = error.localizedDescription
    } catch {
      playbackErrorMessage = "We could not play this recording."
    }
  }

  func stopPlayback() async {
    await audioPlaybackService.stop()
    isPlayingAudio = false
    playbackCurrentTime = 0
    stopPlaybackTimer()
  }

  func toggleCustomTheme(_ theme: CustomJournalTheme) {
    if selectedCustomThemes.contains(theme) {
      selectedCustomThemes.removeAll { $0 == theme }
    } else {
      selectedCustomThemes.append(theme)
    }
  }

  func createCustomTheme() async {
    let name = pendingCustomThemeName

    do {
      let theme = try await customThemeService.createCustomTheme(named: name)
      availableCustomThemes.append(theme)
      selectedCustomThemes.append(theme)
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
      selectedCustomThemes.removeAll { $0.id == theme.id }
    } catch {
      errorMessage = "We could not delete that custom theme. Please try again."
    }
  }

  func addPendingTag() {
    let tag = pendingTag.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !tag.isEmpty else { return }
    guard !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else {
      pendingTag = ""
      return
    }

    tags.append(tag)
    pendingTag = ""
  }

  func removeTag(_ tag: String) {
    tags.removeAll { $0 == tag }
  }

  func addImageInputs(_ inputs: [ImageAttachmentInput]) async {
    guard !inputs.isEmpty else { return }

    isProcessingImages = true
    errorMessage = nil
    defer { isProcessingImages = false }

    do {
      for input in inputs {
        let attachment = try await imageAttachmentService.saveImageAttachment(input)
        imageAttachments.append(attachment)
      }
    } catch let error as ImageAttachmentServiceError {
      errorMessage = error.localizedDescription
    } catch {
      errorMessage = "We could not save that image on this device. Please try again."
    }
  }

  func removeImageAttachment(_ attachment: JournalImageAttachment) async {
    imageAttachments.removeAll { $0.id == attachment.id }
    await imageAttachmentService.deleteAttachment(attachment)
  }

  func discardDraftAttachments() async {
    await stopPlayback()
    await cleanupTemporaryAudio()
    await imageAttachmentService.deleteAttachments(imageAttachments)
    imageAttachments = []
  }

  func save() async -> JournalEntry? {
    let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedTranscript.isEmpty else {
      errorMessage = "Add a transcript before saving."
      return nil
    }

    isSaving = true
    errorMessage = nil

    let entry = JournalEntry(
      id: draft.id,
      createdAt: draft.createdAt,
      updatedAt: Date(),
      transcript: cleanedTranscript,
      title: makeTitle(from: cleanedTranscript),
      mood: selectedMood,
      moodConfidence: 0.68,
      themes: selectedThemes,
      customThemes: selectedCustomThemes,
      tags: tags,
      duration: draft.duration,
      source: .voice,
      imageAttachments: imageAttachments
    )

    do {
      try await journalRepository.saveEntry(entry)
      await cleanupTemporaryAudio()
      isSaving = false
      return entry
    } catch {
      isSaving = false
      errorMessage = "We could not save this entry. Please try again."
      return nil
    }
  }

  private func makeTitle(from transcript: String) -> String {
    let firstSentence =
      transcript
      .components(separatedBy: CharacterSet(charactersIn: ".!?"))
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard let firstSentence, !firstSentence.isEmpty else { return "Voice journal" }
    return String(firstSentence.prefix(48))
  }

  private func startPlaybackTimer() {
    playbackTimerTask?.cancel()
    playbackTimerTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(nanoseconds: 300_000_000)

        guard let self else { return }
        let time = await self.audioPlaybackService.currentTime()
        let isStillPlaying = await self.audioPlaybackService.isPlaying()

        await MainActor.run {
          self.playbackCurrentTime = time
          self.isPlayingAudio = isStillPlaying

          if !isStillPlaying {
            self.stopPlaybackTimer()
          }
        }
      }
    }
  }

  private func stopPlaybackTimer() {
    playbackTimerTask?.cancel()
    playbackTimerTask = nil
  }

  private func cleanupTemporaryAudio() async {
    await audioPlaybackService.stop()
    stopPlaybackTimer()
    isPlayingAudio = false

    let audioURL = draft.audioURL.standardizedFileURL
    let temporaryDirectoryPath = fileManager.temporaryDirectory.standardizedFileURL.path
    guard audioURL.path.hasPrefix(temporaryDirectoryPath) else { return }

    await Task.detached(priority: .utility) {
      guard FileManager.default.fileExists(atPath: audioURL.path) else { return }
      try? FileManager.default.removeItem(at: audioURL)
    }.value
  }

  private func formatPlaybackTime(_ time: TimeInterval) -> String {
    let totalSeconds = max(Int(time), 0)
    let minutes = totalSeconds / 60
    let seconds = totalSeconds % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
}
