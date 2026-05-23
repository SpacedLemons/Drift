//
//  AppDependencyContainer.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftData

struct AppDependencyContainer: Sendable {
  let journalRepository: any JournalRepository & Sendable
  let audioRecordingService: any AudioRecordingService & Sendable
  let audioPlaybackService: any AudioPlaybackService & Sendable
  let transcriptionService: any TranscriptionService & Sendable
  let moodAnalysisService: any MoodAnalysisService & Sendable
  let reminderService: any ReminderService & Sendable
  let aiJournalAnalysisService: any AIJournalAnalysisService & Sendable
  let subscriptionService: any SubscriptionService & Sendable
  let dailyEntryLimitService: any DailyEntryLimitService & Sendable
  let customisationService: any CustomisationService & Sendable
  let customThemeService: any CustomThemeService & Sendable
  let imageAttachmentService: any ImageAttachmentService & Sendable
  let guideService: any GuideService & Sendable
  let exportService: any ExportService & Sendable
  let backupService: any BackupService & Sendable

  static func unavailable() -> AppDependencyContainer {
    AppDependencyContainer(
      journalRepository: UnavailableJournalRepository(),
      audioRecordingService: UnavailableAudioRecordingService(),
      audioPlaybackService: PreviewAudioPlaybackService(),
      transcriptionService: UnavailableTranscriptionService(),
      moodAnalysisService: LocalMoodAnalysisService(),
      reminderService: UnavailableReminderService(),
      aiJournalAnalysisService: DisabledAIJournalAnalysisService(),
      subscriptionService: DisabledSubscriptionService(),
      dailyEntryLimitService: PreviewDailyEntryLimitService(),
      customisationService: LocalCustomisationService(),
      customThemeService: LocalCustomThemeService(),
      imageAttachmentService: LocalImageAttachmentService(),
      guideService: LocalGuideService(),
      exportService: LocalMarkdownExportService(),
      backupService: PlaceholderBackupService()
    )
  }

  static func live(modelContainer: ModelContainer) -> AppDependencyContainer {
    let journalRepository = SwiftDataJournalRepository(modelContainer: modelContainer)
    let storeKitSubscriptionService = StoreKitSubscriptionService()

    #if DEBUG
      let debugOverrideStore = DebugEntitlementOverrideStore()
      let subscriptionService = DebugSubscriptionService(
        baseService: storeKitSubscriptionService,
        overrideStore: debugOverrideStore
      )
    #else
      let subscriptionService = storeKitSubscriptionService
    #endif

    let localDailyEntryLimitService = LocalDailyEntryLimitService(
      journalRepository: journalRepository,
      subscriptionService: subscriptionService
    )

    #if DEBUG
      let dailyEntryLimitService = DebugDailyEntryLimitService(
        baseService: localDailyEntryLimitService,
        subscriptionService: subscriptionService,
        overrideStore: debugOverrideStore
      )
    #else
      let dailyEntryLimitService = localDailyEntryLimitService
    #endif

    return AppDependencyContainer(
      journalRepository: journalRepository,
      audioRecordingService: AVAudioRecordingService(),
      audioPlaybackService: AVAudioPlaybackService(),
      transcriptionService: AppleSpeechTranscriptionService(),
      moodAnalysisService: LocalMoodAnalysisService(),
      reminderService: LocalNotificationReminderService(),
      aiJournalAnalysisService: DisabledAIJournalAnalysisService(),
      subscriptionService: subscriptionService,
      dailyEntryLimitService: dailyEntryLimitService,
      customisationService: LocalCustomisationService(),
      customThemeService: LocalCustomThemeService(),
      imageAttachmentService: LocalImageAttachmentService(),
      guideService: LocalGuideService(),
      exportService: LocalMarkdownExportService(),
      backupService: PlaceholderBackupService()
    )
  }
}
