//
//  SpacesViewModel.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Observation

@MainActor
@Observable
final class SpacesViewModel {
  let spaces: [DriftSpace]

  init(spaces: [DriftSpace] = DriftSpace.placeholderSpaces) {
    self.spaces = spaces
  }
}
