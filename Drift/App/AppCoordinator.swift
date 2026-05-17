//
//  AppCoordinator.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
  var path: [AppRoute] = []
  var fullScreenRoute: AppFullScreenRoute?
  var paywallReasonMessage: String?

  func showJournalEntry(_ entry: JournalEntry) {
    showJournalEntry(entry.id)
  }

  func showJournalEntry(_ id: UUID) {
    path.append(.journalEntry(id))
  }

  func editJournalEntry(_ id: UUID) {
    path.append(.editJournalEntry(id))
  }

  func startCapture() {
    path.append(.capture(.recording))
  }

  @discardableResult
  func startCaptureFromReminder() -> Bool {
    path = [.capture(.recording)]
    return path == [.capture(.recording)]
  }

  func showProcessing(_ result: RecordingResult) {
    path.append(.capture(.processing(result)))
  }

  func showReview(_ draft: ReviewEntryDraft) {
    path.append(.capture(.review(draft)))
  }

  func showSaved(_ entry: JournalEntry) {
    path = [.capture(.saved(entry))]
  }

  func viewSavedEntry(_ entry: JournalEntry) {
    path = [.journalEntry(entry.id)]
  }

  func backToEntryDetail(_ id: UUID) {
    if let detailIndex = path.lastIndex(of: .journalEntry(id)) {
      path = Array(path.prefix(through: detailIndex))
    } else {
      path = [.journalEntry(id)]
    }
  }

  func addAnotherEntry() {
    path = [.capture(.recording)]
  }

  func backToJournal() {
    path.removeAll()
  }

  func showDriftPlusPaywall(reasonMessage: String? = nil) {
    paywallReasonMessage = reasonMessage
    fullScreenRoute = .driftPlus
  }

  func dismissFullScreenRoute() {
    fullScreenRoute = nil
    paywallReasonMessage = nil
  }
}
