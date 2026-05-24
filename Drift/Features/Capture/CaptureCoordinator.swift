//
//  CaptureCoordinator.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Observation

@MainActor
@Observable
final class CaptureCoordinator {
  @ObservationIgnored
  private let dependencies: AppDependencyContainer

  init(dependencies: AppDependencyContainer) {
    self.dependencies = dependencies
  }

  func makeRecordingViewModel() -> RecordingViewModel {
    RecordingViewModel(
      audioRecordingService: dependencies.audioRecordingService
    )
  }

  func makeProcessingViewModel(recordingResult: RecordingResult) -> ProcessingViewModel {
    ProcessingViewModel(
      recordingResult: recordingResult,
      transcriptionService: dependencies.transcriptionService,
      moodAnalysisService: dependencies.moodAnalysisService
    )
  }

  func makeReviewEntryViewModel(draft: ReviewEntryDraft) -> ReviewEntryViewModel {
    ReviewEntryViewModel(
      draft: draft,
      journalRepository: dependencies.journalRepository,
      spaceRepository: dependencies.spaceRepository,
      audioPlaybackService: dependencies.audioPlaybackService,
      imageAttachmentService: dependencies.imageAttachmentService,
      customThemeService: dependencies.customThemeService,
      dailyEntryLimitService: dependencies.dailyEntryLimitService
    )
  }

  func makeSavedEntryViewModel(entry: JournalEntry) -> SavedEntryViewModel {
    SavedEntryViewModel(entry: entry)
  }
}
