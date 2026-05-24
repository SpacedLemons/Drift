//
//  SpaceRepository.swift
//  Drift
//
//  Created by Lucas Stuart West Rogers on 23/05/2026.
//

import Foundation
import Mockable

@Mockable
protocol SpaceRepository {
  func fetchSpaces() async throws -> [DriftSpace]
  func fetchSpace(id: UUID) async throws -> DriftSpace?
  func saveSpace(_ space: DriftSpace) async throws
  func updateSpace(_ space: DriftSpace) async throws
  func deleteSpace(id: UUID) async throws
}

enum SpaceRepositoryError: LocalizedError {
  case fetchFailed
  case saveFailed
  case deleteFailed
  case spaceNotFound

  var errorDescription: String? {
    switch self {
    case .fetchFailed: "We could not load your Spaces."
    case .saveFailed: "We could not save that Space."
    case .deleteFailed: "We could not delete that Space."
    case .spaceNotFound: "That Space no longer exists."
    }
  }
}

actor LocalSpaceRepository: SpaceRepository {
  private var spaces: [DriftSpace]

  init(spaces: [DriftSpace] = DriftSpace.defaultSpaces) {
    self.spaces = spaces
  }

  func fetchSpaces() async throws -> [DriftSpace] {
    sorted(spaces)
  }

  func fetchSpace(id: UUID) async throws -> DriftSpace? {
    spaces.first { $0.id == id }
  }

  func saveSpace(_ space: DriftSpace) async throws {
    spaces.removeAll { $0.id == space.id }
    spaces.append(space)
  }

  func updateSpace(_ space: DriftSpace) async throws {
    guard let index = spaces.firstIndex(where: { $0.id == space.id }) else {
      throw SpaceRepositoryError.spaceNotFound
    }

    spaces[index] = space
  }

  func deleteSpace(id: UUID) async throws {
    guard spaces.contains(where: { $0.id == id }) else {
      throw SpaceRepositoryError.spaceNotFound
    }

    spaces.removeAll { $0.id == id }
  }

  private func sorted(_ spaces: [DriftSpace]) -> [DriftSpace] {
    spaces.sorted {
      if $0.isPinned != $1.isPinned {
        return $0.isPinned && !$1.isPinned
      }

      return $0.updatedAt > $1.updatedAt
    }
  }
}
