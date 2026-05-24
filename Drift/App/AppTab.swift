//
//  AppTab.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppTab: Hashable {
  case capture
  case spaces
  case gpt
  case settings

  @ViewBuilder
  var label: some View {
    switch self {
    case .capture: Label("Capture", systemImage: "mic")
    case .spaces: Label("Spaces", systemImage: "square.grid.2x2")
    case .gpt: Label("GPT", systemImage: "sparkles")
    case .settings: Label("Settings", systemImage: "gearshape")
    }
  }
}
