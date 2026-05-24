//
//  DefaultSeedStateEntity.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import SwiftData

@Model
final class DefaultSeedStateEntity {
  @Attribute(.unique) var key: String
  var createdAt: Date

  init(
    key: String,
    createdAt: Date
  ) {
    self.key = key
    self.createdAt = createdAt
  }
}
