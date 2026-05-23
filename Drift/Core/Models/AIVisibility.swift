//
//  AIVisibility.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum AIVisibility: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case privateLocalOnly
  case availableForInAppAI
  case availableForChatGPT

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .privateLocalOnly: "Private local only"
    case .availableForInAppAI: "Available for in-app AI"
    case .availableForChatGPT: "Available for ChatGPT export"
    }
  }

  var privacyCopy: String {
    switch self {
    case .privateLocalOnly:
      "Private on this device. Not included in AI context unless you choose it."
    case .availableForInAppAI:
      "Prepared for future in-app AI features, but no AI access is active yet."
    case .availableForChatGPT:
      "Can be included in a local context export that you copy when you choose."
    }
  }
}
