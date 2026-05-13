//
//  ProcessingViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProcessingViewModel {
  @ObservationIgnored
  private let recordingResult: RecordingResult
  @ObservationIgnored
  private let transcriptionService: any TranscriptionService
  @ObservationIgnored
  private let moodAnalysisService: any MoodAnalysisService
  @ObservationIgnored
  private let fileManager: FileManager
  private var hasStarted = false

  private(set) var steps = ProcessingStep.allCases.map { ProcessingChecklistItem(step: $0) }
  private(set) var errorMessage: String?
  private(set) var cleanupWarningMessage: String?
  private(set) var shouldShowSettingsLink = false

  init(
    recordingResult: RecordingResult,
    transcriptionService: any TranscriptionService,
    moodAnalysisService: any MoodAnalysisService,
    fileManager: FileManager = .default
  ) {
    self.recordingResult = recordingResult
    self.transcriptionService = transcriptionService
    self.moodAnalysisService = moodAnalysisService
    self.fileManager = fileManager
  }

  func prepareEntry() async -> ReviewEntryDraft? {
    guard !hasStarted else { return nil }
    hasStarted = true
    errorMessage = nil
    cleanupWarningMessage = nil
    shouldShowSettingsLink = false

    do {
      mark(.transcribing, as: .active)
      try await pauseBriefly()
      try await transcriptionService.requestPermission()
      let transcript = try await transcriptionService.transcribe(audioURL: recordingResult.audioURL)
      let cleanedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !cleanedTranscript.isEmpty else { throw TranscriptionError.emptyResult }
      mark(.transcribing, as: .complete)

      mark(.cleaningTranscript, as: .active)
      try await pauseBriefly()
      mark(.cleaningTranscript, as: .complete)

      mark(.suggestingMood, as: .active)
      try await pauseBriefly()
      let mood = try await moodAnalysisService.suggestMood(from: cleanedTranscript)
      mark(.suggestingMood, as: .complete)

      mark(.findingThemes, as: .active)
      try await pauseBriefly()
      let themes = try await moodAnalysisService.suggestThemes(from: cleanedTranscript)
      mark(.findingThemes, as: .complete)

      return ReviewEntryDraft(
        id: UUID(),
        audioURL: recordingResult.audioURL,
        duration: recordingResult.duration,
        createdAt: recordingResult.finishedAt,
        transcript: cleanedTranscript,
        suggestedMood: mood,
        suggestedThemes: themes,
        tags: themes.map(\.displayName).map { $0.lowercased() }
      )
    } catch {
      errorMessage = userFacingErrorMessage(for: error)
      shouldShowSettingsLink = shouldShowSettingsLink(for: error)
      markActiveStepAsFailed()
      return nil
    }
  }

  func makeManualEntryDraft() async -> ReviewEntryDraft {
    shouldShowSettingsLink = false

    return ReviewEntryDraft(
      id: UUID(),
      audioURL: recordingResult.audioURL,
      duration: recordingResult.duration,
      createdAt: recordingResult.finishedAt,
      transcript: "",
      suggestedMood: .neutral,
      suggestedThemes: [],
      tags: []
    )
  }

  func discardEntry() async {
    await deleteTemporaryAudioIfNeeded()
    shouldShowSettingsLink = false
  }

  func reset() {
    hasStarted = false
    errorMessage = nil
    cleanupWarningMessage = nil
    shouldShowSettingsLink = false
    steps = ProcessingStep.allCases.map { ProcessingChecklistItem(step: $0) }
  }

  private func mark(_ step: ProcessingStep, as status: ProcessingStepStatus) {
    guard let index = steps.firstIndex(where: { $0.step == step }) else { return }
    steps[index].status = status
  }

  private func markActiveStepAsFailed() {
    guard let index = steps.firstIndex(where: { $0.status == .active }) else { return }
    steps[index].status = .failed
  }

  private func pauseBriefly() async throws {
    try await Task.sleep(nanoseconds: 450_000_000)
  }

  private func deleteTemporaryAudioIfNeeded() async {
    // Future preference: skip this cleanup if Drift adds "Keep audio recording".
    let audioURL = recordingResult.audioURL.standardizedFileURL
    let temporaryDirectoryPath = fileManager.temporaryDirectory.standardizedFileURL.path
    guard audioURL.path.hasPrefix(temporaryDirectoryPath) else { return }

    let didFailCleanup = await Task.detached(priority: .utility) {
      let fileManager = FileManager.default
      guard fileManager.fileExists(atPath: audioURL.path) else { return false }

      do {
        try fileManager.removeItem(at: audioURL)
        return false
      } catch {
        return true
      }
    }.value

    if didFailCleanup {
      cleanupWarningMessage = TranscriptionError.cleanupFailed.localizedDescription
    }
  }

  private func userFacingErrorMessage(for error: any Error) -> String {
    if let transcriptionError = error as? TranscriptionError {
      return transcriptionError.localizedDescription
    }

    return "We could not transcribe this recording. You can try again or type it manually."
  }

  private func shouldShowSettingsLink(for error: any Error) -> Bool {
    guard let transcriptionError = error as? TranscriptionError else { return false }
    return transcriptionError == .permissionDenied
  }
}

struct ProcessingChecklistItem: Identifiable, Hashable {
  let step: ProcessingStep
  var status: ProcessingStepStatus = .pending

  var id: ProcessingStep { step }
}

enum ProcessingStep: CaseIterable, Hashable {
  case transcribing
  case cleaningTranscript
  case suggestingMood
  case findingThemes

  var title: String {
    switch self {
    case .transcribing: "Transcribing voice"
    case .cleaningTranscript: "Cleaning transcript"
    case .suggestingMood: "Suggesting mood"
    case .findingThemes: "Finding themes"
    }
  }
}

enum ProcessingStepStatus: Hashable {
  case pending
  case active
  case complete
  case failed
}
