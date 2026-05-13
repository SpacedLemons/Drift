//
//  AppTab.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppTab: Hashable {
  case journal
  case insights
  case settings

  @ViewBuilder
  var label: some View {
    switch self {
    case .journal: Label("Journal", systemImage: AppIcons.book)
    case .insights: Label("Insights", systemImage: AppIcons.chart)
    case .settings: Label("Settings", systemImage: AppIcons.settings)
    }
  }
}
