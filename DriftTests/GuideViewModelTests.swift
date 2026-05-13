//
//  GuideViewModelTests.swift
//  DriftTests
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import Testing

@testable import Drift

@MainActor
struct GuideViewModelTests {
  @Test
  func guideCanBeDismissedAndReopened() async {
    let service = PreviewGuideService()
    let viewModel = GuideViewModel(guideService: service)

    await viewModel.load()
    #expect(!viewModel.isDismissed)

    await viewModel.dismissGuide()
    #expect(viewModel.isDismissed)
    #expect(await service.isGuideDismissed())

    await viewModel.reopenGuide()
    #expect(!viewModel.isDismissed)
    #expect(!(await service.isGuideDismissed()))
  }

  @Test
  func guideContainsExpectedAnnotations() {
    let viewModel = GuideViewModel()
    let titles = viewModel.annotations.map(\.title)

    #expect(titles.contains("Record"))
    #expect(titles.contains("Review"))
    #expect(titles.contains("Themes"))
    #expect(titles.contains("Calendar"))
    #expect(titles.contains("Reminders"))
    #expect(titles.contains("Privacy"))
    #expect(titles.contains("Images"))
  }
}
