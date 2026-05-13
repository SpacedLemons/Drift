//
//  CaptureRoute.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

enum CaptureRoute: Hashable {
  case recording
  case processing(RecordingResult)
  case review(ReviewEntryDraft)
  case saved(JournalEntry)
}
