//
//  FloatingRecordButton.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct FloatingRecordButton: View {
  let action: () -> Void

  var body: some View {
    Button(
      action: {
        action()
      },
      label: {
        Image(systemName: AppIcons.mic)
          .font(.system(size: 24, weight: .semibold))
          .foregroundStyle(.white)
          .frame(width: 68, height: 68)
          .background(
            Circle()
              .fill(AppColors.accent)
              .shadow(color: AppColors.accent.opacity(0.35), radius: 18, y: 8)
          )
      }
    )
    .buttonStyle(.plain)
    .accessibilityLabel("Record Drift")
  }
}
