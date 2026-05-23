//
//  DriftType.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

enum DriftType: String, CaseIterable, Identifiable, Codable, Hashable, Sendable {
  case thought
  case reflection
  case goal
  case idea
  case memory
  case mood
  case decision
  case task
  case visual
  case context

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .thought: "Thought"
    case .reflection: "Reflection"
    case .goal: "Goal"
    case .idea: "Idea"
    case .memory: "Memory"
    case .mood: "Mood"
    case .decision: "Decision"
    case .task: "Task"
    case .visual: "Visual"
    case .context: "Context"
    }
  }

  var symbolName: String {
    switch self {
    case .thought: "bubble.left.and.text.bubble.right"
    case .reflection: AppIcons.waveform
    case .goal: "target"
    case .idea: "lightbulb"
    case .memory: "clock.arrow.circlepath"
    case .mood: AppIcons.mood
    case .decision: "checkmark.seal"
    case .task: "checklist"
    case .visual: AppIcons.photo
    case .context: "rectangle.stack"
    }
  }
}
