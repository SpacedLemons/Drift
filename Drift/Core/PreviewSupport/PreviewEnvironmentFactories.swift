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
    AppDependencyContainer(
      journalRepository: PreviewJournalRepository(entries: entries),
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
      backupService: PreviewBackupService()
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
