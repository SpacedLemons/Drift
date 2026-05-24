//
//  PreviewEnvironmentFactories.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

extension AppDependencyContainer {
  static func preview(
    entries: [JournalEntry] = PreviewData.journalEntries
  ) -> AppDependencyContainer {
    let journalRepository = PreviewJournalRepository(entries: entries)
    let driftRepository = JournalBackedDriftRepository(journalRepository: journalRepository)

    return AppDependencyContainer(
      journalRepository: journalRepository,
      driftRepository: driftRepository,
      driftSearchService: LocalDriftSearchService(driftRepository: driftRepository),
      spaceRepository: LocalSpaceRepository(),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService(),
      audioRecordingService: PreviewAudioRecordingService(),
      audioPlaybackService: PreviewAudioPlaybackService(),
      transcriptionService: PreviewTranscriptionService(),
      moodAnalysisService: PreviewMoodAnalysisService(),
      reminderService: PreviewReminderService(),
      aiJournalAnalysisService: DisabledAIJournalAnalysisService(),
      subscriptionService: DisabledSubscriptionService(),
      dailyEntryLimitService: PreviewDailyEntryLimitService(),
      customisationService: LocalCustomisationService(),
      customThemeService: PreviewCustomThemeService(),
      imageAttachmentService: PreviewImageAttachmentService(),
      guideService: PreviewGuideService(),
      exportService: LocalMarkdownExportService(),
      backupService: PreviewBackupService(),
      userIdentityService: PreviewUserIdentityService(),
      chatGPTConnectionService: LocalChatGPTConnectionService()
    )
  }
}

extension AppEnvironment {
  static func preview(entries: [JournalEntry] = PreviewData.journalEntries) -> AppEnvironment {
    AppEnvironment(
      dependencies: .preview(entries: entries)
    )
  }
}
