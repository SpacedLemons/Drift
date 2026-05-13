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
  let customisationService: any CustomisationService & Sendable
  let customThemeService: any CustomThemeService & Sendable
  let imageAttachmentService: any ImageAttachmentService & Sendable
  let guideService: any GuideService & Sendable
  let exportService: any ExportService & Sendable

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
      customisationService: LocalCustomisationService(),
      customThemeService: LocalCustomThemeService(),
      imageAttachmentService: LocalImageAttachmentService(),
      guideService: LocalGuideService(),
      exportService: LocalMarkdownExportService()
    )
  }

  static func live(modelContainer: ModelContainer) -> AppDependencyContainer {
    AppDependencyContainer(
      journalRepository: SwiftDataJournalRepository(modelContainer: modelContainer),
      audioRecordingService: AVAudioRecordingService(),
      audioPlaybackService: AVAudioPlaybackService(),
      transcriptionService: AppleSpeechTranscriptionService(),
      moodAnalysisService: LocalMoodAnalysisService(),
      reminderService: LocalNotificationReminderService(),
      aiJournalAnalysisService: DisabledAIJournalAnalysisService(),
      subscriptionService: DisabledSubscriptionService(),
      customisationService: LocalCustomisationService(),
      customThemeService: LocalCustomThemeService(),
      imageAttachmentService: LocalImageAttachmentService(),
      guideService: LocalGuideService(),
      exportService: LocalMarkdownExportService()
    )
  }
}
