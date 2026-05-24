//
//  AppDependencyContainer.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftData

struct AppDependencyContainer: Sendable {
  let journalRepository: any JournalRepository & Sendable
  let driftRepository: any DriftRepository & Sendable
  let driftSearchService: any DriftSearchService & Sendable
  let spaceRepository: any SpaceRepository & Sendable
  let contextPackService: any ContextPackService & Sendable
  let contextExportService: any ContextExportService & Sendable
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
  let userIdentityService: any UserIdentityService & Sendable
  let chatGPTConnectionService: any ChatGPTConnectionService & Sendable

  static func unavailable() -> AppDependencyContainer {
    let journalRepository = UnavailableJournalRepository()
    let driftRepository = JournalBackedDriftRepository(journalRepository: journalRepository)

    return AppDependencyContainer(
      journalRepository: journalRepository,
      driftRepository: driftRepository,
      driftSearchService: LocalDriftSearchService(driftRepository: driftRepository),
      spaceRepository: LocalSpaceRepository(),
      contextPackService: LocalContextPackService(),
      contextExportService: LocalContextExportService(),
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
      backupService: PlaceholderBackupService(),
      userIdentityService: PreviewUserIdentityService(),
      chatGPTConnectionService: LocalChatGPTConnectionService()
    )
  }

  static func live(modelContainer: ModelContainer) -> AppDependencyContainer {
    let journalRepository = SwiftDataJournalRepository(modelContainer: modelContainer)
    let driftRepository = JournalBackedDriftRepository(journalRepository: journalRepository)
    let spaceRepository = SwiftDataSpaceRepository(modelContainer: modelContainer)
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
      driftRepository: driftRepository,
      driftSearchService: LocalDriftSearchService(driftRepository: driftRepository),
      spaceRepository: spaceRepository,
      contextPackService: SwiftDataContextPackService(modelContainer: modelContainer),
      contextExportService: LocalContextExportService(),
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
      backupService: PlaceholderBackupService(),
      userIdentityService: KeychainUserIdentityService(),
      chatGPTConnectionService: LocalChatGPTConnectionService()
    )
  }
}
