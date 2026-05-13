//
//  SystemSettingsLink.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 13/05/2026.
//

import SwiftUI
import UIKit

struct SystemSettingsLink: View {
  let title: String
  let systemImage: String

  init(
    title: String = "Open Settings",
    systemImage: String = AppIcons.settings
  ) {
    self.title = title
    self.systemImage = systemImage
  }

  var body: some View {
    if let settingsURL {
      Link(destination: settingsURL) {
        Label(title, systemImage: systemImage)
      }
      .buttonStyle(.bordered)
      .accessibilityHint("Opens Drift settings in the Settings app.")
    }
  }

  private var settingsURL: URL? {
    URL(string: UIApplication.openSettingsURLString)
  }
}
