//
//  IconButton.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct IconButton: View {
  let icon: String
  let accessibilityLabel: String
  let action: () -> Void

  var body: some View {
    Button(
      action: {
        action()
      },
      label: {
        Image(systemName: icon)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary)
          .frame(width: 44, height: 44)
          .background(AppColors.surfaceRaised, in: Circle())
          .overlay {
            Circle().stroke(AppColors.border, lineWidth: 1)
          }
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel)
  }
}
