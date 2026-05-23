//
//  GuideViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Observation

@MainActor
@Observable
final class GuideViewModel {
  @ObservationIgnored
  private let guideService: any GuideService

  private(set) var isDismissed = false

  let annotations: [GuideAnnotation] = [
    GuideAnnotation(
      icon: AppIcons.mic,
      title: "Record",
      message: "Tap the microphone to capture a voice-first Drift."
    ),
    GuideAnnotation(
      icon: AppIcons.checkmark,
      title: "Review",
      message: "Review the transcript, mood, themes, tags, and images before saving."
    ),
    GuideAnnotation(
      icon: AppIcons.tag,
      title: "Themes",
      message: "Use built-in themes, custom themes, and tags to keep Drifts easy to find."
    ),
    GuideAnnotation(
      icon: AppIcons.calendar,
      title: "Calendar",
      message: "Expand the calendar on the Timeline to browse older local Drifts."
    ),
    GuideAnnotation(
      icon: AppIcons.bell,
      title: "Reminders",
      message: "Reminders are local notifications on this device."
    ),
    GuideAnnotation(
      icon: AppIcons.lockShield,
      title: "Privacy",
      message: "Drifts stay on this device. No account is required."
    ),
    GuideAnnotation(
      icon: AppIcons.photo,
      title: "Images",
      message: "Images are stored on this device with your Drift."
    ),
  ]

  init(guideService: any GuideService = PreviewGuideService()) {
    self.guideService = guideService
  }

  func load() async {
    isDismissed = await guideService.isGuideDismissed()
  }

  func dismissGuide() async {
    await guideService.setGuideDismissed(true)
    isDismissed = true
  }

  func reopenGuide() async {
    await guideService.setGuideDismissed(false)
    isDismissed = false
  }
}

struct GuideAnnotation: Identifiable, Hashable {
  var icon: String
  var title: String
  var message: String

  var id: String { title }
}
