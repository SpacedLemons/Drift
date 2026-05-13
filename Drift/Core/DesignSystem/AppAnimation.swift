//
//  AppAnimation.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 12/05/2026.
//

import SwiftUI

enum AppAnimation {
  static let gentle = Animation.easeInOut(duration: 0.22)
  static let spring = Animation.spring(response: 0.32, dampingFraction: 0.82)
}
