//
//  RecordingOrb.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

struct RecordingOrb: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  let isRecording: Bool
  let isPaused: Bool
  let audioLevel: Double

  private var activeLevel: Double {
    guard isRecording, !isPaused else { return 0 }
    return min(max(audioLevel, 0), 1)
  }

  private var visualLevel: Double {
    reduceMotion ? 0 : activeLevel
  }

  var body: some View {
    ZStack {
      Circle()
        .fill(AppColors.accent.opacity(isPaused ? 0.10 : 0.14 + visualLevel * 0.14))
        .frame(width: 210, height: 210)
        .scaleEffect(1.0 + visualLevel * 0.09)

      Circle()
        .stroke(AppColors.accent.opacity(0.18 + visualLevel * 0.22), lineWidth: 1)
        .frame(width: 170 + visualLevel * 34, height: 170 + visualLevel * 34)

      Circle()
        .stroke(AppColors.accentSecondary.opacity(0.10 + visualLevel * 0.18), lineWidth: 1)
        .frame(width: 132 + visualLevel * 28, height: 132 + visualLevel * 28)

      Circle()
        .fill(AppColors.surfaceRaised)
        .frame(width: 126, height: 126)
        .overlay {
          Circle().stroke(AppColors.border, lineWidth: 1)
        }
        .shadow(color: AppColors.accent.opacity(0.24), radius: 28, y: 12)

      Image(systemName: AppIcons.mic)
        .font(.system(size: 44, weight: .semibold))
        .foregroundStyle(isPaused ? AppColors.textTertiary : AppColors.textPrimary)
        .scaleEffect(1.0 + visualLevel * 0.04)
    }
    .animation(reduceMotion ? nil : AppAnimation.spring, value: isRecording)
    .animation(reduceMotion ? nil : AppAnimation.gentle, value: isPaused)
    .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: visualLevel)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(isPaused ? "Recording paused" : "Recording")
    .accessibilityValue(isRecording ? "Audio level \(Int(activeLevel * 100)) percent" : "Idle")
  }
}
