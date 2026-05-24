//
//  LocalIdentityStatus.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 24/05/2026.
//

import Foundation

enum LocalIdentityStatus: Equatable, Sendable {
  case unknown
  case ready(createdAt: Date)
  case unavailable
}
