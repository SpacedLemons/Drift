//
//  ProcessingViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Mockable
import Testing

@testable import Drift

@MainActor
struct ProcessingViewModelTests {
  @Test
  func prepareEntryTranscribesAndRunsLocalMoodAnalysis() async throws {
    let audioURL = try makeTemporaryAudioFile()
    let transcriptionService = MockTranscriptionService()
    let moodAnalysisService = MockMoodAnalysisService()
    given(transcriptionService)
      .requestPermission().willReturn()
      .transcribe(audioURL: .value(audioURL)).willReturn("  I felt focused today.  ")
    given(moodAnalysisService)
      .suggestMood(from: .value("I felt focused today.")).willReturn(.positive)
      .suggestThemes(from: .value("I felt focused today.")).willReturn([.work, .productivity])

    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: transcriptionService,
      moodAnalysisService: moodAnalysisService
    )

    let draft = await viewModel.prepareEntry()

    #expect(draft?.transcript == "I felt focused today.")
    #expect(draft?.suggestedMood == .positive)
    #expect(draft?.suggestedThemes == [.work, .productivity])
    #expect(FileManager.default.fileExists(atPath: audioURL.path))
    try? FileManager.default.removeItem(at: audioURL)
    verify(transcriptionService)
      .requestPermission().called(.once)
      .transcribe(audioURL: .value(audioURL)).called(.once)
    verify(moodAnalysisService)
      .suggestMood(from: .value("I felt focused today.")).called(.once)
      .suggestThemes(from: .value("I felt focused today.")).called(.once)
  }

  @Test
  func prepareEntrySurfacesTranscriptionFailure() async throws {
    let audioURL = try makeTemporaryAudioFile()
    defer { try? FileManager.default.removeItem(at: audioURL) }
    let transcriptionService = MockTranscriptionService()
    let moodAnalysisService = MockMoodAnalysisService()
    given(transcriptionService)
      .requestPermission().willReturn()
      .transcribe(audioURL: .value(audioURL)).willThrow(TranscriptionError.transcriptionFailed)

    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: transcriptionService,
      moodAnalysisService: moodAnalysisService
    )

    let draft = await viewModel.prepareEntry()

    #expect(draft == nil)
    #expect(viewModel.errorMessage == TranscriptionError.transcriptionFailed.localizedDescription)
    #expect(!viewModel.shouldShowSettingsLink)
    verify(moodAnalysisService)
      .suggestMood(from: .any).called(.never)
      .suggestThemes(from: .any).called(.never)
  }

  @Test
  func prepareEntrySurfacesEmptyResult() async throws {
    let audioURL = try makeTemporaryAudioFile()
    defer { try? FileManager.default.removeItem(at: audioURL) }
    let transcriptionService = MockTranscriptionService()
    let moodAnalysisService = MockMoodAnalysisService()
    given(transcriptionService)
      .requestPermission().willReturn()
      .transcribe(audioURL: .value(audioURL)).willReturn("   ")

    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: transcriptionService,
      moodAnalysisService: moodAnalysisService
    )

    let draft = await viewModel.prepareEntry()

    #expect(draft == nil)
    #expect(viewModel.errorMessage == TranscriptionError.emptyResult.localizedDescription)
    verify(moodAnalysisService)
      .suggestMood(from: .any).called(.never)
      .suggestThemes(from: .any).called(.never)
  }

  @Test
  func prepareEntrySurfacesPermissionDenied() async throws {
    let audioURL = try makeTemporaryAudioFile()
    defer { try? FileManager.default.removeItem(at: audioURL) }
    let transcriptionService = MockTranscriptionService()
    let moodAnalysisService = MockMoodAnalysisService()
    given(transcriptionService)
      .requestPermission().willThrow(TranscriptionError.permissionDenied)

    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: transcriptionService,
      moodAnalysisService: moodAnalysisService
    )

    let draft = await viewModel.prepareEntry()

    #expect(draft == nil)
    #expect(viewModel.errorMessage == TranscriptionError.permissionDenied.localizedDescription)
    #expect(viewModel.shouldShowSettingsLink)
    verify(transcriptionService)
      .transcribe(audioURL: .any).called(.never)
  }

  @Test
  func manualEntryFallbackCreatesEmptyDraftAndKeepsTemporaryAudioForReview() async throws {
    let audioURL = try makeTemporaryAudioFile()
    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: MockTranscriptionService(),
      moodAnalysisService: MockMoodAnalysisService()
    )

    let draft = await viewModel.makeManualEntryDraft()

    #expect(draft.transcript.isEmpty)
    #expect(draft.suggestedMood == .neutral)
    #expect(draft.suggestedThemes.isEmpty)
    #expect(FileManager.default.fileExists(atPath: audioURL.path))
    try? FileManager.default.removeItem(at: audioURL)
  }

  @Test
  func discardEntryDeletesTemporaryAudio() async throws {
    let audioURL = try makeTemporaryAudioFile()
    let viewModel = makeViewModel(
      audioURL: audioURL,
      transcriptionService: MockTranscriptionService(),
      moodAnalysisService: MockMoodAnalysisService()
    )

    await viewModel.discardEntry()

    #expect(!FileManager.default.fileExists(atPath: audioURL.path))
  }

  private func makeViewModel(
    audioURL: URL,
    transcriptionService: any TranscriptionService,
    moodAnalysisService: any MoodAnalysisService
  ) -> ProcessingViewModel {
    ProcessingViewModel(
      recordingResult: RecordingResult(
        audioURL: audioURL,
        duration: 12,
        finishedAt: PreviewData.baseDate
      ),
      transcriptionService: transcriptionService,
      moodAnalysisService: moodAnalysisService
    )
  }

  private func makeTemporaryAudioFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("drift-processing-test-\(UUID().uuidString)")
      .appendingPathExtension("m4a")
    try Data("audio".utf8).write(to: url)
    return url
  }
}
